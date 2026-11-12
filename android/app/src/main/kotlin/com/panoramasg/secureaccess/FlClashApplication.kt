package com.panoramasg.secureaccess

import android.app.Application
import android.content.Context
import com.panoramasg.secureaccess.common.GlobalState

class FlClashApplication : Application() {
    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        GlobalState.init(this)
    }
}
