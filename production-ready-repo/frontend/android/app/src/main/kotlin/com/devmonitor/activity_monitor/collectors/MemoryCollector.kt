package com.devmonitor.activity_monitor.collectors

import android.app.ActivityManager
import android.content.Context

class MemoryCollector(private val context: Context) {

    private val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager

    fun getMemoryStats(): Map<String, Any> {
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)

        return mapOf(
            "totalMem" to memoryInfo.totalMem,
            "availMem" to memoryInfo.availMem,
            "threshold" to memoryInfo.threshold,
            "lowMemory" to memoryInfo.lowMemory,
            "usedMem" to (memoryInfo.totalMem - memoryInfo.availMem)
        )
    }
}
