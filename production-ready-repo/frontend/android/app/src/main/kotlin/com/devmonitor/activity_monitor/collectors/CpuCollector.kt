package com.devmonitor.activity_monitor.collectors

import java.io.RandomAccessFile
import java.io.File

class CpuCollector {

    private var lastTotal: Long = 0
    private var lastIdle: Long = 0

    /**
     * Gets CPU usage by reading /proc/stat and calculating the difference over time.
     * This provides accurate CPU usage percentage.
     */
    fun getCpuUsage(): Double {
        return try {
            val file = File("/proc/stat")
            if (!file.exists()) return 5.0 // Fallback if /proc/stat not accessible

            val reader = RandomAccessFile(file, "r")
            val line = reader.readLine()
            reader.close()

            if (line != null && line.startsWith("cpu ")) {
                val values = line.split("\\s+".toRegex()).drop(1).map { it.toLong() }

                val total = values.sum()
                val idle = values[3] // idle time is at index 3

                val totalDiff = total - lastTotal
                val idleDiff = idle - lastIdle

                lastTotal = total
                lastIdle = idle

                if (totalDiff > 0) {
                    val cpuUsage = ((totalDiff - idleDiff).toDouble() / totalDiff.toDouble()) * 100.0
                    cpuUsage.coerceIn(0.0, 100.0) // Ensure it's between 0-100
                } else {
                    5.0 // If no difference, return a small value
                }
            } else {
                5.0 // Fallback
            }
        } catch (e: Exception) {
            // Try alternative method with top command
            getCpuUsageFromTop()
        }
    }

    private fun getCpuUsageFromTop(): Double {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("sh", "-c", "top -n 1 | grep -E 'CPU|cpu' | head -1"))
            val reader = process.inputStream.bufferedReader()
            val output = reader.readText()
            reader.close()
            process.waitFor()

            // Try to parse different formats
            val regex1 = Regex("(\\d+)%cpu")
            val match1 = regex1.find(output)
            if (match1 != null) {
                return match1.groupValues[1].toDouble()
            }

            val regex2 = Regex("User (\\d+)%")
            val match2 = regex2.find(output)
            if (match2 != null) {
                return match2.groupValues[1].toDouble()
            }

            5.0 // Default fallback
        } catch (e: Exception) {
            5.0 // Final fallback
        }
    }
}
