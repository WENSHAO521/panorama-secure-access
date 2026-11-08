package com.follow.clash

import android.content.ComponentName
import android.content.Context
import android.content.ServiceConnection
import android.os.IBinder
import com.follow.clash.common.GlobalState
import com.follow.clash.common.intent
import com.follow.clash.service.CoreService
import com.follow.clash.service.ipc.ICoreCallback
import com.follow.clash.service.ipc.ICoreService
import com.follow.clash.service.ipc.IServiceListener
import com.follow.clash.service.ipc.Payload
import com.follow.clash.service.models.NotificationParams
import com.follow.clash.service.models.VpnOptions
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import java.util.Collections
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.resume

/**
 * The app's side of the Core process. The Core, the VPN and the proxy service run in `:core`,
 * so a crash of the UI process leaves the tunnel up; this binds that process and forwards to it.
 */
object ServiceController {
    private val gson = Gson()
    private val lock = Mutex()
    private val notificationLock = Mutex()

    @Volatile
    internal var runtime: ServiceRuntime? = null
        private set

    @Volatile
    private var eventListener: ((ByteArray) -> Unit)? = null

    @Volatile
    private var notificationParams: NotificationParams? = null

    fun invokeMethod(
        data: String,
        onError: (String) -> Unit,
        callback: (ByteArray) -> Unit,
    ): Result<Unit> = runCatching {
        val service = runBlocking { CoreConnection.service() }
        val call = CoreCall(callback, onError)
        runCatching { service.invokeMethod(Payload(data), call) }
            .onFailure { error -> call.fail(error.message.orEmpty()) }
    }

    suspend fun quickSetup(
        initParams: String,
        setupParams: String,
    ): Result<String> = runCatching {
        val service = CoreConnection.service()
        suspendCancellableCoroutine<Result<String>> { continuation ->
            val call = CoreCall(
                onResult = { result -> continuation.resume(Result.success(String(result))) },
                onError = { message ->
                    continuation.resume(Result.failure(IllegalStateException(message)))
                },
            )
            runCatching { service.quickSetup(initParams, Payload(setupParams), call) }
                .onFailure { error -> call.fail(error.message.orEmpty()) }
        }.getOrThrow()
    }

    fun setEventListener(callback: ((ByteArray) -> Unit)?): Result<Unit> = runCatching {
        eventListener = callback
        GlobalState.launch {
            runCatching { applyEventListener(CoreConnection.service()) }
                .onFailure { error -> GlobalState.log("Unable to set the event listener: $error") }
        }
    }

    fun updateNotificationParams(params: NotificationParams) {
        notificationParams = params
        GlobalState.launch {
            runCatching { applyNotificationParams(CoreConnection.service()) }
                .onFailure { error ->
                    GlobalState.log("Unable to update notification params: $error")
                }
        }
    }

    suspend fun start(options: VpnOptions): Boolean = lock.withLock {
        val startedAt = runCatching {
            val service = CoreConnection.service()
            withContext(Dispatchers.IO) { service.start(gson.toJson(options)) }
        }.getOrElse { error ->
            GlobalState.log("Unable to start background service: $error")
            0L
        }
        if (startedAt <= 0L) {
            runtime = null
            return@withLock false
        }
        runtime = ServiceRuntime(vpn = options.enable, startedAtMillis = startedAt)
        true
    }

    suspend fun stop() = lock.withLock {
        runCatching {
            val service = CoreConnection.service()
            withContext(Dispatchers.IO) { service.stop() }
        }.onFailure { error -> GlobalState.log("Unable to stop background service: $error") }
        runtime = null
    }

    /** Waits for the Core process so a run it kept while the UI was gone is known here. */
    suspend fun awaitConnected(): Boolean = runCatching { CoreConnection.service() }.isSuccess

    private fun applyEventListener(service: ICoreService) {
        val listener = eventListener
        service.setEventListener(
            listener?.let {
                object : ICoreCallback.Stub() {
                    override fun onResult(result: Payload) = it(result.read())
                }
            },
        )
    }

    private suspend fun applyNotificationParams(service: ICoreService) {
        notificationLock.withLock {
            val params = notificationParams ?: return
            withContext(Dispatchers.IO) {
                service.updateNotificationParams(gson.toJson(params))
            }
        }
    }

    internal suspend fun onConnected(service: ICoreService) {
        withContext(Dispatchers.IO) {
            service.setServiceListener(serviceListener)
            applyEventListener(service)
            applyNotificationParams(service)
        }
        val startedAt = withContext(Dispatchers.IO) { service.runtimeStartedAt() }
        if (startedAt > 0L) {
            val vpn = withContext(Dispatchers.IO) { service.runtimeVpn() }
            runtime = ServiceRuntime(vpn = vpn, startedAtMillis = startedAt)
        } else if (runtime != null) {
            handleServiceLost("The Core process restarted")
        }
    }

    internal fun onDisconnected() {
        CoreCall.failAll("The Core process died")
        if (runtime != null) {
            handleServiceLost("The Core process died")
        }
    }

    private val serviceListener = object : IServiceListener.Stub() {
        override fun onServiceLost(message: String) = handleServiceLost(message)
    }

    private fun handleServiceLost(message: String) {
        val token = ServiceState.captureRequestToken()
        GlobalState.launch {
            val wasRunning = lock.withLock {
                if (runtime == null) {
                    return@withLock false
                }
                GlobalState.log("Background service disconnected: $message")
                runtime = null
                true
            }
            if (wasRunning) {
                ServiceState.handleServiceLost(token)
            }
        }
    }
}

/** One answer from the Core; settled with an error instead if the Core process dies first. */
private class CoreCall(
    private val onResult: (ByteArray) -> Unit,
    private val onError: (String) -> Unit,
) : ICoreCallback.Stub() {
    private val settled = AtomicBoolean(false)

    init {
        pending += this
    }

    override fun onResult(result: Payload) {
        val bytes = runCatching { result.read() }
        if (!settled.compareAndSet(false, true)) return
        pending -= this
        bytes.fold(onResult) { error -> onError(error.message.orEmpty()) }
    }

    fun fail(message: String) {
        if (!settled.compareAndSet(false, true)) return
        pending -= this
        onError(message)
    }

    companion object {
        private val pending: MutableSet<CoreCall> = Collections.synchronizedSet(mutableSetOf())

        fun failAll(message: String) {
            val calls = synchronized(pending) { pending.toList() }
            calls.forEach { it.fail(message) }
        }
    }
}

private object CoreConnection : ServiceConnection, IBinder.DeathRecipient {
    private val service = MutableStateFlow<ICoreService?>(null)
    private val bindLock = Any()
    private var bound = false

    @Volatile
    private var linked: IBinder? = null

    private fun ensureBound() {
        synchronized(bindLock) {
            if (bound) return
            bound = GlobalState.application.bindService(
                CoreService::class.intent,
                this,
                Context.BIND_AUTO_CREATE or Context.BIND_IMPORTANT,
            )
            check(bound) { "bindService() failed for the Core process" }
        }
    }

    // Never called on the main thread, where the connection itself is delivered.
    suspend fun service(timeoutMillis: Long = 10_000): ICoreService {
        ensureBound()
        return withTimeout(timeoutMillis) { service.filterNotNull().first() }
    }

    override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
        if (binder == null) return
        val next = ICoreService.Stub.asInterface(binder)
        linked = binder
        runCatching { binder.linkToDeath(this, 0) }
            .onFailure {
                onDisconnected()
                return
            }
        GlobalState.launch {
            runCatching { ServiceController.onConnected(next) }
                .onFailure { error -> GlobalState.log("Unable to sync the Core process: $error") }
            if (linked === binder) {
                service.value = next
            }
        }
    }

    override fun onServiceDisconnected(name: ComponentName?) = onDisconnected()

    override fun binderDied() = onDisconnected()

    override fun onBindingDied(name: ComponentName?) {
        synchronized(bindLock) {
            runCatching { GlobalState.application.unbindService(this) }
            bound = false
        }
        onDisconnected()
    }

    private fun onDisconnected() {
        val binder = synchronized(bindLock) { linked.also { linked = null } } ?: return
        runCatching { binder.unlinkToDeath(this, 0) }
        service.value = null
        ServiceController.onDisconnected()
    }
}
