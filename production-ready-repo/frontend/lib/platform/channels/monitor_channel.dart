import 'package:flutter/services.dart';

class MonitorChannel {
  static const MethodChannel _channel = MethodChannel('com.devmonitor.activity_monitor/methods');

  Future<double> getCpuUsage() async {
    try {
      final double usage = await _channel.invokeMethod('getCpuUsage');
      return usage;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> getMemoryStats() async {
    try {
      final Map<dynamic, dynamic> stats = await _channel.invokeMethod('getMemoryStats');
      return Map<String, dynamic>.from(stats);
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getBatteryStats() async {
    try {
      final Map<dynamic, dynamic> stats = await _channel.invokeMethod('getBatteryStats');
      return Map<String, dynamic>.from(stats);
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getNetworkStats() async {
    try {
      final Map<dynamic, dynamic> stats = await _channel.invokeMethod('getNetworkStats');
      return Map<String, dynamic>.from(stats);
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getAppUsageStats() async {
    try {
      final List<dynamic> stats = await _channel.invokeMethod('getAppUsageStats');
      return stats.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAppUsageSessions() async {
    try {
      final List<dynamic> sessions = await _channel.invokeMethod('getAppUsageSessions');
      return sessions.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> startMonitorService() async {
    try {
      await _channel.invokeMethod('startMonitorService');
    } catch (e) {
      // Handle error
    }
  }

  Future<void> stopMonitorService() async {
    try {
      await _channel.invokeMethod('stopMonitorService');
    } catch (e) {
      // Handle error
    }
  }

  Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (e) {
      // Handle error
    }
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final Map<dynamic, dynamic> stats = await _channel.invokeMethod('getStorageInfo');
      return Map<String, dynamic>.from(stats);
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final Map<dynamic, dynamic> stats = await _channel.invokeMethod('getDeviceInfo');
      return Map<String, dynamic>.from(stats);
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, bool>> getAppPermissions(String packageName) async {
    try {
      final Map<dynamic, dynamic> permissions = await _channel.invokeMethod('getAppPermissions', {'packageName': packageName});
      return Map<String, bool>.from(permissions);
    } catch (e) {
      return {};
    }
  }

  Future<int> performRamBoost() async {
    try {
      final int processesKilled = await _channel.invokeMethod('performRamBoost');
      return processesKilled;
    } catch (e) {
      return 0;
    }
  }
}
