package com.follow.clash.service

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.os.RemoteException
import com.follow.clash.common.GlobalState
import com.follow.clash.core.Core
import com.follow.clash.service.ipc.ICoreCallback
import com.follow.clash.service.ipc.ICoreService
import com.follow.clash.service.ipc.IServiceListener
import com.follow.clash.service.ipc.Payload
import com.follow.clash.service.models.NotificationParams
import com.follow.clash.service.models.VpnOptions
import com.google.gson.Gson
import kotlinx.coroutines.runBlocking

/**
 * Hosts the Core in its own process, beside the VPN and proxy services, so a crash of the
 * Flutter UI no longer takes the tunnel down. The app binds this for as long as it runs.
 */
class CoreService : Service() {
    private val gson = Gson()

    override fun onCreate() {
        super.onCreate()
        runCatching { Core.load() }
            .onFailure { error -> GlobalState.log("Unable to load the Core: $error") }
        // Outlives every run: the Core also tests delays and updates providers while stopped.
        NetworkObserver.start()
    }

    override fun onBind(intent: Intent): IBinder = binder

    override fun onLowMemory() {
        lowCoreMemory()
        super.onLowMemory()
    }

    override fun onTrimMemory(level: Int) {
        trimCoreMemory(level)
        super.onTrimMemory(level)
    }

    private fun ICoreCallback.deliver(result: ByteArray?) {
        try {
            onResult(Payload(result ?: ByteArray(0)))
        } catch (error: RemoteException) {
            GlobalState.log("Unable to deliver a Core result: $error")
        }
    }

    private val binder = object : ICoreService.Stub() {
        override fun invokeMethod(data: Payload, callback: ICoreCallback) {
            Core.invokeMethod(data.readText()) { result -> callback.deliver(result) }
        }

        override fun quickSetup(
            initParams: String,
            setupParams: Payload,
            callback: ICoreCallback,
        ) {
            Core.quickSetup(initParams, setupParams.readText()) { result ->
                callback.deliver(result?.toByteArray(Charsets.UTF_8))
            }
        }

        override fun setEventListener(listener: ICoreCallback?) {
            if (listener == null) {
                Core.updateEventListener(null)
                return
            }
            Core.updateEventListener { event ->
                try {
                    listener.onResult(Payload(event))
                } catch (error: RemoteException) {
                    GlobalState.log("Event listener is gone: $error")
                    Core.updateEventListener(null)
                }
            }
        }

        override fun setServiceListener(listener: IServiceListener?) {
            if (listener == null) {
                CoreRuntime.onServiceLost = null
                return
            }
            CoreRuntime.onServiceLost = { message ->
                try {
                    listener.onServiceLost(message)
                } catch (error: RemoteException) {
                    GlobalState.log("Service listener is gone: $error")
                }
            }
        }

        override fun updateNotificationParams(params: String) {
            runCatching { gson.fromJson(params, NotificationParams::class.java) }
                .onSuccess(ServiceConfig::updateNotificationParams)
                .onFailure { error -> GlobalState.log("Invalid notification params: $error") }
        }

        override fun start(vpnOptions: String): Long {
            val options = gson.fromJson(vpnOptions, VpnOptions::class.java)
            return runBlocking { CoreRuntime.start(options) }?.startedAtMillis ?: 0L
        }

        override fun stop() = runBlocking { CoreRuntime.stop() }

        override fun runtimeStartedAt(): Long = CoreRuntime.runInfo?.startedAtMillis ?: 0L

        override fun runtimeVpn(): Boolean = CoreRuntime.runInfo?.vpn == true
    }
}
