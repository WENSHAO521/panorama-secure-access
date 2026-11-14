package com.panoramasg.secureaccess

import android.annotation.SuppressLint
import android.content.ComponentName
import android.net.VpnService
import android.os.Build
import android.service.quicksettings.Tile
import com.panoramasg.secureaccess.common.GlobalState
import com.panoramasg.secureaccess.common.QuickAction
import com.panoramasg.secureaccess.common.quickIntent
import com.panoramasg.secureaccess.common.toPendingIntent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class TileService : android.service.quicksettings.TileService() {
    private var scope: CoroutineScope? = null
    private var settle: Job? = null

    private val defaultLabel by lazy {
        packageManager.getServiceInfo(ComponentName(this, javaClass), 0).loadLabel(packageManager)
    }

    override fun onStartListening() {
        super.onStartListening()
        scope?.cancel()
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate).also { scope ->
            scope.launch {
                ServiceState.runState.collect { state ->
                    settle?.cancel()
                    updateTile(state)
                }
            }
        }
    }

    override fun onClick() {
        super.onClick()
        if (needsVpnConsent()) {
            openQuickAction()
            return
        }
        // Flutter may take a moment to claim the start, so the tile answers the tap itself and
        // falls back to the real state if no transition follows.
        val pending = if (ServiceState.isRunRequested) RunState.STOPPING else RunState.STARTING
        updateTile(pending)
        settle?.cancel()
        settle = scope?.launch {
            delay(SETTLE_MILLIS)
            updateTile(ServiceState.runState.value)
        }
        GlobalState.launch { ServiceState.handleToggleAction() }
    }

    override fun onStopListening() {
        scope?.cancel()
        scope = null
        settle = null
        super.onStopListening()
    }

    // The consent dialog is an activity, so only a start that still needs it leaves the shade.
    private fun needsVpnConsent(): Boolean =
        !ServiceState.isRunRequested &&
            application.sharedState.vpnOptions?.enable != false &&
            VpnService.prepare(this) != null

    // A transition keeps the tile tappable, so a start can be called off from the shade, and
    // lit the way it is heading, which is what a tap there should show at once.
    private fun updateTile(runState: RunState) {
        val tile = qsTile ?: return
        val shared = application.sharedState
        tile.state = when (runState) {
            RunState.STARTED, RunState.STARTING -> Tile.STATE_ACTIVE
            RunState.STOPPING, RunState.STOPPED -> Tile.STATE_INACTIVE
        }
        // OEM shades such as ColorOS render only the label, never the subtitle.
        tile.label = shared.currentProfileName.ifBlank { defaultLabel }
        val progress = when (runState) {
            RunState.STARTING -> shared.startTip
            RunState.STOPPING -> shared.stopTip
            else -> null
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = progress
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            tile.stateDescription = progress
        }
        tile.updateTile()
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun openQuickAction() {
        val intent = QuickAction.TOGGLE.quickIntent
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(intent.toPendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private companion object {
        const val SETTLE_MILLIS = 8_000L
    }
}
