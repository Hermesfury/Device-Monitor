package com.devmonitor.activity_monitor.collectors

import android.net.TrafficStats
import android.os.Process

class NetworkCollector {

    fun getNetworkStats(): Map<String, Any> {
        return mapOf(
            "totalRxBytes" to TrafficStats.getTotalRxBytes(),
            "totalTxBytes" to TrafficStats.getTotalTxBytes(),
            "mobileRxBytes" to TrafficStats.getMobileRxBytes(),
            "mobileTxBytes" to TrafficStats.getMobileTxBytes(),
            "uidRxBytes" to TrafficStats.getUidRxBytes(Process.myUid()),
            "uidTxBytes" to TrafficStats.getUidTxBytes(Process.myUid())
        )
    }
}
