package com.devmonitor.activity_monitor.collectors

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import java.util.*

class UsageCollector(private val context: Context) {

    fun getAppUsageStats(): List<Map<String, Any>> {
        val statsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 1000 * 60 * 60 * 24 // Last 24 hours

        val stats = statsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)

        return stats?.map { usageStats ->
            mapOf(
                "packageName" to usageStats.packageName,
                "totalTimeInForeground" to usageStats.totalTimeInForeground,
                "lastTimeUsed" to usageStats.lastTimeUsed
            )
        } ?: emptyList()
    }

    fun getAppUsageSessions(since: Long = System.currentTimeMillis() - 1000 * 60 * 60 * 24): List<Map<String, Any>> {
        val sessions = mutableListOf<Map<String, Any>>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val events = usageStatsManager.queryEvents(since, System.currentTimeMillis())

            val event = UsageEvents.Event()
            var lastEventTime = 0L
            var lastPackage = ""
            var sessionStart = 0L

            while (events.hasNextEvent()) {
                events.getNextEvent(event)

                when (event.eventType) {
                    UsageEvents.Event.ACTIVITY_RESUMED -> {
                        if (lastPackage != event.packageName) {
                            // New session started
                            sessionStart = event.timeStamp
                            lastPackage = event.packageName
                        }
                    }
                    UsageEvents.Event.ACTIVITY_PAUSED -> {
                        if (lastPackage == event.packageName && sessionStart > 0) {
                            // Session ended
                            val duration = event.timeStamp - sessionStart
                            if (duration > 1000) { // At least 1 second
                                sessions.add(mapOf(
                                    "packageName" to event.packageName,
                                    "startTime" to sessionStart,
                                    "endTime" to event.timeStamp,
                                    "durationMs" to duration
                                ))
                            }
                            sessionStart = 0L
                        }
                    }
                }
                lastEventTime = event.timeStamp
            }
        }

        return sessions
    }
}
