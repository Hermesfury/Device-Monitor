package com.devmonitor.activity_monitor

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class MonitorService : Service() {

    private val CHANNEL_ID = "monitor_channel"
    private val NOTIFICATION_ID = 1
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var usageCollector: com.devmonitor.activity_monitor.collectors.UsageCollector

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        usageCollector = com.devmonitor.activity_monitor.collectors.UsageCollector(applicationContext)
        startPeriodicCollection()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Activity Monitor Active")
            .setContentText("Monitoring system metrics in real-time")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        // Here we could start a timer to sample data and broadcast it 
        // to MainActivity or store it in a database/cache.
        // For now, we just keep the service alive.

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startPeriodicCollection() {
        val runnable = object : Runnable {
            override fun run() {
                try {
                    // Collect usage sessions and save them (in a real implementation,
                    // this would send data to Flutter via platform channels or save to DB)
                    val sessions = usageCollector.getAppUsageSessions()
                    // TODO: Send sessions to Flutter for processing
                } catch (e: Exception) {
                    // Handle error
                }
                // Schedule next collection in 10 minutes
                handler.postDelayed(this, 10 * 60 * 1000L)
            }
        }
        handler.post(runnable)
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacksAndMessages(null)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Monitor Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}
