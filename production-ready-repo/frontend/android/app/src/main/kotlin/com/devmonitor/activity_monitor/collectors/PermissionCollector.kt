package com.devmonitor.activity_monitor.collectors

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

class PermissionCollector(private val context: Context) {

    fun getAppPermissions(packageName: String): Map<String, Boolean> {
        val permissions = mutableMapOf<String, Boolean>()

        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
            }

            val requestedPermissions = packageInfo.requestedPermissions ?: emptyArray()
            val grantedPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS).requestedPermissionsFlags
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS).requestedPermissionsFlags
            }

            requestedPermissions.forEachIndexed { index, permission ->
                val granted = grantedPermissions?.get(index)?.and(PackageManager.PERMISSION_GRANTED) != 0
                permissions[permission] = granted
            }
        } catch (e: PackageManager.NameNotFoundException) {
            // App not found
        }

        return permissions
    }
}
