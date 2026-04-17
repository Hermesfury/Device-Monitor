package com.devmonitor.activity_monitor.collectors

import android.os.Environment
import android.os.StatFs

class StorageCollector {
    fun getStorageInfo(): Map<String, Any> {
        val path = Environment.getDataDirectory()
        val stat = StatFs(path.path)
        val blockSize = stat.blockSizeLong
        val totalBlocks = stat.blockCountLong
        val availableBlocks = stat.availableBlocksLong

        val totalBytes = totalBlocks * blockSize
        val freeBytes = availableBlocks * blockSize
        val usedBytes = totalBytes - freeBytes

        return mapOf(
            "totalBytes" to totalBytes,
            "freeBytes" to freeBytes,
            "usedBytes" to usedBytes
        )
    }
}
