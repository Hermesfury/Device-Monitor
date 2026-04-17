package com.devmonitor.activity_monitor

import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import com.devmonitor.activity_monitor.collectors.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.devmonitor.activity_monitor/methods"

    private lateinit var cpuCollector: CpuCollector
    private lateinit var memoryCollector: MemoryCollector
    private lateinit var batteryCollector: BatteryCollector
    private lateinit var networkCollector: NetworkCollector
    private lateinit var usageCollector: UsageCollector
    private lateinit var storageCollector: StorageCollector
    private lateinit var deviceCollector: DeviceCollector
    private lateinit var permissionCollector: PermissionCollector
    private lateinit var ramBooster: RamBooster

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        cpuCollector = CpuCollector()
        memoryCollector = MemoryCollector(applicationContext)
        batteryCollector = BatteryCollector(applicationContext)
        networkCollector = NetworkCollector()
        usageCollector = UsageCollector(applicationContext)
        storageCollector = StorageCollector()
        deviceCollector = DeviceCollector()
        permissionCollector = PermissionCollector(applicationContext)
        ramBooster = RamBooster(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCpuUsage" -> {
                    result.success(cpuCollector.getCpuUsage())
                }
                "getMemoryStats" -> {
                    result.success(memoryCollector.getMemoryStats())
                }
                "getBatteryStats" -> {
                    result.success(batteryCollector.getBatteryStats())
                }
                "getNetworkStats" -> {
                    result.success(networkCollector.getNetworkStats())
                }
                "getAppUsageStats" -> {
                    result.success(usageCollector.getAppUsageStats())
                }
                "getAppUsageSessions" -> {
                    result.success(usageCollector.getAppUsageSessions())
                }
                "getStorageInfo" -> {
                    result.success(storageCollector.getStorageInfo())
                }
                "getDeviceInfo" -> {
                    result.success(deviceCollector.getDeviceInfo())
                }
                "getAppPermissions" -> {
                    val packageName = call.arguments as String
                    result.success(permissionCollector.getAppPermissions(packageName))
                }
                "performRamBoost" -> {
                    val processesKilled = ramBooster.performRamBoost()
                    result.success(processesKilled)
                }
                "openUsageSettings" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    context.startActivity(intent)
                    result.success(null)
                }
                "startMonitorService" -> {
                    val intent = Intent(this, MonitorService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stopMonitorService" -> {
                    stopService(Intent(this, MonitorService::class.java))
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
