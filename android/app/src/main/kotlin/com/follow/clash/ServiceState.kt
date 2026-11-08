package com.follow.clash

import com.follow.clash.models.SharedState
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.Deferred

object ServiceState {
    private val machine = ServiceStateMachine(AndroidServiceStateHost)

    val runState = machine.runState

    val isRunRequested: Boolean
        get() = machine.isRunRequested

    fun attachFlutterEngine(engine: FlutterEngine) =
        AndroidServiceStateHost.attachFlutterEngine(engine)

    fun detachFlutterEngine(engine: FlutterEngine) =
        AndroidServiceStateHost.detachFlutterEngine(engine)

    // The Core process outlives this one, so a fresh process first learns whether a run is up.
    suspend fun syncWithCore() {
        if (ServiceController.awaitConnected()) {
            machine.adoptRuntime()
        }
    }

    suspend fun handleToggleAction() {
        syncWithCore()
        machine.handleToggleAction()
    }

    suspend fun handleStartAction() {
        syncWithCore()
        machine.handleStartAction()
    }

    suspend fun handleStopAction() {
        syncWithCore()
        machine.handleStopAction()
    }

    suspend fun handleVpnRevokeAction() {
        syncWithCore()
        machine.handleVpnRevokeAction()
    }

    suspend fun awaitRunTime(): Long {
        syncWithCore()
        return machine.awaitRunTime()
    }

    fun requestStart(): Deferred<Boolean> = machine.requestStart()

    fun requestStop(): Deferred<Boolean> = machine.requestStop()

    fun syncSharedState(state: SharedState) = machine.syncSharedState(state)

    internal fun captureRequestToken(): RunRequest = machine.captureRequestToken()

    internal suspend fun handleServiceLost(token: RunRequest) = machine.handleServiceLost(token)
}
