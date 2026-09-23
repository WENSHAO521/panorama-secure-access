package com.follow.clash.plugins

import android.Manifest
import android.app.Activity
import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.webkit.MimeTypeMap
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.getSystemService
import androidx.core.content.FileProvider
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import androidx.core.net.toUri
import com.follow.clash.R
import com.follow.clash.common.Components
import com.follow.clash.common.GlobalState
import com.follow.clash.common.QuickAction
import com.follow.clash.common.quickIntent
import com.follow.clash.common.registerReceiverCompat
import com.follow.clash.getPackageIconPath
import com.follow.clash.packages.PackageResolver
import com.follow.clash.showToast
import com.google.gson.Gson
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.lang.ref.WeakReference

class AppPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    companion object {
        const val VPN_PERMISSION_REQUEST_CODE = 1001
        const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1002
    }

    private var activityRef: WeakReference<Activity>? = null

    private lateinit var channel: MethodChannel

    private lateinit var scope: CoroutineScope

    private var vpnPrepareCallback: (suspend () -> Unit)? = null

    private var requestNotificationCallback: (() -> Unit)? = null

    private val packageResolver by lazy {
        PackageResolver(
            GlobalState.application.packageManager,
            GlobalState.application.packageName,
        )
    }

    private var packageChangeContext: Context? = null

    // Apps installed, updated or removed while Panorama runs: drop the cached
    // list and tell the app, so per-app routing never shows a stale list.
    private val packageChangeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent == null ||
                intent.data?.schemeSpecificPart == GlobalState.application.packageName
            ) {
                return
            }
            // An update sends ADDED (replacing) and then REPLACED; act once.
            val addedByUpdate = intent.action == Intent.ACTION_PACKAGE_ADDED &&
                intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)
            if (addedByUpdate) {
                return
            }
            packageResolver.invalidate()
            channel.invokeMethod("packagesChanged", null)
        }
    }

    private var isBlockNotification: Boolean = false

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "moveTaskToBack" -> {
                activityRef?.get()?.moveTaskToBack(true)
                result.success(true)
            }

            "updateExcludeFromRecents" -> {
                val value = call.argument<Boolean>("value")
                updateExcludeFromRecents(value)
                result.success(true)
            }

            "initShortcuts" -> {
                initShortcuts(call.arguments as String)
                result.success(true)
            }

            "getPackages" -> {
                scope.launch {
                    result.success(getPackagesToJson())
                }
            }

            "getChinaPackageNames" -> {
                scope.launch {
                    result.success(getChinaPackageNames())
                }
            }

            "getPackageIcon" -> {
                handleGetPackageIcon(call, result)
            }

            "tip" -> {
                val message = call.argument<String>("message")
                tip(message)
                result.success(true)
            }

            "isBatteryOptimizationDisabled" -> {
                result.success(isBatteryOptimizationDisabled())
            }

            "openBatteryOptimizationSettings" -> {
                result.success(openBatteryOptimizationSettings())
            }

            "openAppSettings" -> {
                result.success(openAppSettings())
            }

            "openFile" -> {
                val path = call.argument<String>("path")
                result.success(openFile(path))
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleGetPackageIcon(call: MethodCall, result: Result) {
        scope.launch {
            val packageName = call.argument<String>("packageName")
            if (packageName == null) {
                result.success("")
                return@launch
            }
            val path = GlobalState.application.packageManager.getPackageIconPath(packageName)
            result.success(path)
        }
    }

    private fun initShortcuts(label: String) {
        val shortcut = with(ShortcutInfoCompat.Builder(GlobalState.application, "toggle")) {
            setShortLabel(label)
            setIcon(
                IconCompat.createWithResource(
                    GlobalState.application,
                    R.mipmap.ic_launcher_round,
                )
            )
            setIntent(QuickAction.TOGGLE.quickIntent)
            build()
        }
        ShortcutManagerCompat.setDynamicShortcuts(
            GlobalState.application, listOf(shortcut)
        )
    }

    private fun tip(message: String?) {
        GlobalState.application.showToast(message)
    }

    private fun isBatteryOptimizationDisabled(): Boolean {
        val powerManager = getSystemService(GlobalState.application, PowerManager::class.java)
        return powerManager?.isIgnoringBatteryOptimizations(GlobalState.application.packageName)
            ?: false
    }

    private fun openBatteryOptimizationSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = "package:${GlobalState.application.packageName}".toUri()
            }
            activityRef?.get()?.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openAppSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = "package:${GlobalState.application.packageName}".toUri()
            }
            activityRef?.get()?.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openFile(path: String?): Boolean {
        if (path == null) return false
        return try {
            val file = File(path)
            val mimeType = if (file.extension.equals("apk", ignoreCase = true)) {
                "application/vnd.android.package-archive"
            } else {
                val extension = MimeTypeMap.getFileExtensionFromUrl(file.name)
                MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: "*/*"
            }
            val uri = FileProvider.getUriForFile(
                GlobalState.application,
                "${GlobalState.application.packageName}.fileprovider",
                file,
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activityRef?.get()?.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun updateExcludeFromRecents(value: Boolean?) {
        val am = getSystemService(GlobalState.application, ActivityManager::class.java)
        val task = am?.appTasks?.firstOrNull {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                it.taskInfo.taskId == activityRef?.get()?.taskId
            } else {
                it.taskInfo.id == activityRef?.get()?.taskId
            }
        }

        when (value) {
            true -> task?.setExcludeFromRecents(value)
            false -> task?.setExcludeFromRecents(value)
            null -> task?.setExcludeFromRecents(false)
        }
    }


    private suspend fun getPackagesToJson(): String {
        return withContext(Dispatchers.Default) {
            Gson().toJson(packageResolver.installedPackages)
        }
    }

    private suspend fun getChinaPackageNames(): String {
        return withContext(Dispatchers.Default) {
            Gson().toJson(packageResolver.getChinaPackageNames())
        }
    }

    fun requestNotificationsPermission(callBack: () -> Unit) {
        requestNotificationCallback = callBack
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val permission = ContextCompat.checkSelfPermission(
                GlobalState.application, Manifest.permission.POST_NOTIFICATIONS
            )
            if (permission == PackageManager.PERMISSION_GRANTED || isBlockNotification) {
                invokeRequestNotificationCallback()
                return
            }
            activityRef?.get()?.let {
                ActivityCompat.requestPermissions(
                    it,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_REQUEST_CODE
                )
            }
            return
        } else {
            invokeRequestNotificationCallback()
        }

    }

    fun invokeRequestNotificationCallback() {
        requestNotificationCallback?.invoke()
        requestNotificationCallback = null
    }

    fun prepare(needPrepare: Boolean, callBack: (suspend () -> Unit)) {
        vpnPrepareCallback = callBack
        if (!needPrepare) {
            invokeVpnPrepareCallback()
            return
        }
        val intent = VpnService.prepare(GlobalState.application)
        if (intent != null) {
            activityRef?.get()?.startActivityForResult(intent, VPN_PERMISSION_REQUEST_CODE)
            return
        }
        invokeVpnPrepareCallback()
    }

    fun invokeVpnPrepareCallback() {
        GlobalState.launch {
            vpnPrepareCallback?.invoke()
            vpnPrepareCallback = null
        }
    }


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        scope = CoroutineScope(Dispatchers.Default)
        channel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "${Components.PACKAGE_NAME}/app")
        channel.setMethodCallHandler(this)
        watchPackageChanges(flutterPluginBinding.applicationContext)
    }

    private fun watchPackageChanges(context: Context) {
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addAction(Intent.ACTION_PACKAGE_FULLY_REMOVED)
            addDataScheme("package")
        }
        context.registerReceiverCompat(packageChangeReceiver, filter)
        packageChangeContext = context
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        packageChangeContext?.unregisterReceiver(packageChangeReceiver)
        packageChangeContext = null
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityRef = WeakReference(binding.activity)
        binding.addActivityResultListener(::onActivityResult)
        binding.addRequestPermissionsResultListener(::onRequestPermissionsResultListener)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityRef = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityRef = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivity() {
        channel.invokeMethod("exit", null)
        activityRef = null
    }

    private fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == VPN_PERMISSION_REQUEST_CODE) {
            if (resultCode == FlutterActivity.RESULT_OK) {
                invokeVpnPrepareCallback()
            }
        }
        return true
    }

    private fun onRequestPermissionsResultListener(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray
    ): Boolean {
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST_CODE) {
            isBlockNotification = true
        }
        invokeRequestNotificationCallback()
        return true
    }
}
