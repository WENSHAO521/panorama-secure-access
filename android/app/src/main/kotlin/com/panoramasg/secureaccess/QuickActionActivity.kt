package com.panoramasg.secureaccess

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import androidx.core.content.pm.ShortcutManagerCompat
import com.panoramasg.secureaccess.common.GlobalState
import com.panoramasg.secureaccess.common.QuickAction
import com.panoramasg.secureaccess.common.action
import com.panoramasg.secureaccess.common.shortcutId
import kotlinx.coroutines.launch

class QuickActionActivity : Activity() {
    private var awaitingConsent: QuickAction? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handle(intent)
    }

    // A caller that repeats an action before this instance is gone reaches it here, not onCreate.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handle(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != VPN_CONSENT_REQUEST) return
        val action = awaitingConsent
        awaitingConsent = null
        if (action != null && resultCode == RESULT_OK) {
            dispatch(action)
        } else {
            application.showToast(VPN_PERMISSION_MESSAGE)
        }
        finish()
    }

    private fun handle(intent: Intent) {
        if (awaitingConsent != null) return
        val action = QuickAction.entries.firstOrNull { it.action == intent.action }
        if (action == null) {
            finish()
            return
        }
        ShortcutManagerCompat.reportShortcutUsed(this, action.shortcutId)
        // Without the app in front nobody else can show the system consent, so a first start
        // from the shade or a shortcut asks for it here before it runs.
        val consent = if (startsVpn(action)) VpnService.prepare(this) else null
        if (consent != null) {
            awaitingConsent = action
            startActivityForResult(consent, VPN_CONSENT_REQUEST)
            return
        }
        dispatch(action)
        finish()
    }

    private fun startsVpn(action: QuickAction): Boolean {
        val starts = when (action) {
            QuickAction.START -> true
            QuickAction.STOP -> false
            QuickAction.TOGGLE -> !ServiceState.isRunRequested
        }
        return starts && application.sharedState.vpnOptions?.enable != false
    }

    private fun dispatch(action: QuickAction) {
        GlobalState.launch {
            when (action) {
                QuickAction.START -> ServiceState.handleStartAction()
                QuickAction.STOP -> ServiceState.handleStopAction()
                QuickAction.TOGGLE -> ServiceState.handleToggleAction()
            }
        }
    }

    private companion object {
        const val VPN_CONSENT_REQUEST = 1
    }
}
