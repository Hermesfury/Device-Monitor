package com.devmonitor.activity_monitor.collectors

import android.app.ActivityManager
import android.content.Context
import android.os.Process

class RamBooster(private val context: Context) {

    fun performRamBoost(): Int {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningProcesses = activityManager.runningAppProcesses ?: return 0

            var processesKilled = 0

            // Kill background processes (not system processes or our own app)
            for (processInfo in runningProcesses) {
                val packageName = processInfo.processName

                // Skip system processes and our own app
                if (packageName.startsWith("android.") ||
                    packageName.startsWith("com.android.") ||
                    packageName.startsWith("system") ||
                    packageName.contains("systemui") ||
                    packageName.contains("launcher") ||
                    packageName == context.packageName) {
                    continue
                }

                // Only kill processes that are not currently visible
                val importance = processInfo.importance
                if (importance >= ActivityManager.RunningAppProcessInfo.IMPORTANCE_BACKGROUND &&
                    importance < ActivityManager.RunningAppProcessInfo.IMPORTANCE_SERVICE) {
                    try {
                        Process.killProcess(processInfo.pid)
                        processesKilled++
                    } catch (e: Exception) {
                        // Process might have already died
                    }
                }
            }

            processesKilled
        } catch (e: Exception) {
            0
        }
    }
}
