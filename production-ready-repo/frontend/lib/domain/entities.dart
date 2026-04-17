class MonitorMetric {
  final double cpuUsage;
  final int totalMem;
  final int usedMem;
  final int availMem;
  final DateTime timestamp;

  MonitorMetric({
    required this.cpuUsage,
    required this.totalMem,
    required this.usedMem,
    required this.availMem,
    required this.timestamp,
  });

  double get memUsagePercent => totalMem > 0 ? usedMem / totalMem : 0;

  Map<String, dynamic> toMap() {
    return {
      'cpuUsage': cpuUsage,
      'totalMem': totalMem,
      'usedMem': usedMem,
      'availMem': availMem,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory MonitorMetric.fromMap(Map<String, dynamic> map) {
    return MonitorMetric(
      cpuUsage: (map['cpuUsage'] as num?)?.toDouble() ?? 0.0,
      totalMem: (map['totalMem'] as num?)?.toInt() ?? 0,
      usedMem: (map['usedMem'] as num?)?.toInt() ?? 0,
      availMem: (map['availMem'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
}

class BatteryInfo {
  final double level;
  final bool isCharging;
  final double temperature;
  final int voltage;
  final int capacity;
  final int currentNow;

  BatteryInfo({
    required this.level,
    required this.isCharging,
    required this.temperature,
    required this.voltage,
    required this.capacity,
    this.currentNow = 0,
  });

  String get chargingStatus => isCharging ? 'Charging' : 'Discharging';
}

class NetworkStats {
  final int totalRxBytes;
  final int totalTxBytes;
  final double rxSpeedBps; // bytes per second since last reading
  final double txSpeedBps;

  NetworkStats({
    required this.totalRxBytes,
    required this.totalTxBytes,
    required this.rxSpeedBps,
    required this.txSpeedBps,
  });

  static String formatSpeed(double bps) {
    if (bps < 1024) return '${bps.toStringAsFixed(0)} B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / 1024 / 1024).toStringAsFixed(1)} MB/s';
  }
}

class AppUsageInfo {
  final String packageName;
  final int totalTimeInForeground;
  final DateTime lastTimeUsed;

  AppUsageInfo({
    required this.packageName,
    required this.totalTimeInForeground,
    required this.lastTimeUsed,
  });

  String get appName => packageName.split('.').last
      .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (m) => ' ')
      .split(RegExp(r'[ _]'))
      .where((s) => s.isNotEmpty)
      .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
      .join(' ');

  String get usageTime {
    final minutes = totalTimeInForeground ~/ 1000 ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}

class StorageInfo {
  final int totalBytes;
  final int freeBytes;
  final int usedBytes;

  StorageInfo({
    required this.totalBytes,
    required this.freeBytes,
    required this.usedBytes,
  });
  
  double get usedPercentage => totalBytes > 0 ? (usedBytes / totalBytes) : 0.0;
}

class DeviceInfo {
  final String brand;
  final String model;
  final String device;
  final String board;
  final String hardware;
  final String osVersion;
  final int sdkInt;

  DeviceInfo({
    required this.brand,
    required this.model,
    required this.device,
    required this.board,
    required this.hardware,
    required this.osVersion,
    required this.sdkInt,
  });

  String get displayName => brand.toUpperCase() + ' ' + model;
}

// Behavioral Intelligence Entities
enum AppCategory {
  social,
  productivity,
  entertainment,
  communication,
  utilities,
  games,
  shopping,
  health,
  education,
  finance,
  other,
}

class AppUsageSession {
  final String packageName;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMs;

  AppUsageSession({
    required this.packageName,
    required this.startTime,
    required this.endTime,
    required this.durationMs,
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'durationMs': durationMs,
    };
  }

  factory AppUsageSession.fromMap(Map<String, dynamic> map) {
    return AppUsageSession(
      packageName: map['packageName'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] ?? 0),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime'] ?? 0),
      durationMs: map['durationMs'] ?? 0,
    );
  }
}

class AppUsageStats {
  final String packageName;
  final String appName;
  final AppCategory category;
  final int totalUsageMs;
  final int sessionsCount;
  final DateTime lastUsed;
  final DateTime firstSeen;

  AppUsageStats({
    required this.packageName,
    required this.appName,
    required this.category,
    required this.totalUsageMs,
    required this.sessionsCount,
    required this.lastUsed,
    required this.firstSeen,
  });

  String get formattedTotalUsage {
    final minutes = totalUsageMs ~/ (1000 * 60);
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'category': category.name,
      'totalUsageMs': totalUsageMs,
      'sessionsCount': sessionsCount,
      'lastUsed': lastUsed.millisecondsSinceEpoch,
      'firstSeen': firstSeen.millisecondsSinceEpoch,
    };
  }

  factory AppUsageStats.fromMap(Map<String, dynamic> map) {
    return AppUsageStats(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      category: AppCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => AppCategory.other,
      ),
      totalUsageMs: map['totalUsageMs'] ?? 0,
      sessionsCount: map['sessionsCount'] ?? 0,
      lastUsed: DateTime.fromMillisecondsSinceEpoch(map['lastUsed'] ?? 0),
      firstSeen: DateTime.fromMillisecondsSinceEpoch(map['firstSeen'] ?? 0),
    );
  }
}

class UsageInsights {
  final int totalScreenTimeMs;
  final List<AppUsageStats> topApps;
  final Map<AppCategory, int> categoryUsage;
  final int averageSessionMs;
  final DateTime peakUsageHour;
  final int totalSessions;

  UsageInsights({
    required this.totalScreenTimeMs,
    required this.topApps,
    required this.categoryUsage,
    required this.averageSessionMs,
    required this.peakUsageHour,
    required this.totalSessions,
  });

  String get formattedTotalScreenTime {
    final minutes = totalScreenTimeMs ~/ (1000 * 60);
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}

// Anomaly Detection Entities
enum AnomalyType {
  cpuSpike,
  highMemoryUsage,
  unusualNetworkActivity,
  backgroundActivitySpike,
  unusualHourActivity,
}

class AnomalyEvent {
  final AnomalyType type;
  final DateTime timestamp;
  final String description;
  final Map<String, dynamic> details;
  final double severity; // 0.0 to 1.0

  AnomalyEvent({
    required this.type,
    required this.timestamp,
    required this.description,
    required this.details,
    required this.severity,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'description': description,
      'details': details,
      'severity': severity,
    };
  }

  factory AnomalyEvent.fromMap(Map<String, dynamic> map) {
    return AnomalyEvent(
      type: AnomalyType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AnomalyType.cpuSpike,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      description: map['description'] ?? '',
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      severity: (map['severity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AnomalyThresholds {
  final double cpuSpikeThreshold; // percentage
  final int cpuSpikeDurationMs; // sustained period
  final double memoryThreshold; // percentage
  final double networkSpikeThreshold; // bytes/sec increase
  final List<int> normalHours; // 0-23 hours

  AnomalyThresholds({
    this.cpuSpikeThreshold = 50.0, // Lower threshold for more detection
    this.cpuSpikeDurationMs = 10000, // 10 seconds
    this.memoryThreshold = 75.0, // Lower threshold
    this.networkSpikeThreshold = 500000, // 500KB/s
    this.normalHours = const [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
  });
}

// App Risk Scoring Entities
enum RiskLevel { low, medium, high }

class PermissionInfo {
  final String name;
  final String description;
  final bool isGranted;
  final RiskLevel riskLevel;

  PermissionInfo({
    required this.name,
    required this.description,
    required this.isGranted,
    required this.riskLevel,
  });
}

class AppRiskScore {
  final String packageName;
  final int score; // 0-10
  final RiskLevel level;
  final List<String> riskFactors;
  final List<PermissionInfo> permissions;
  final int backgroundActivityLevel; // 0-10
  final int dataUsageLevel; // 0-10

  AppRiskScore({
    required this.packageName,
    required this.score,
    required this.level,
    required this.riskFactors,
    required this.permissions,
    required this.backgroundActivityLevel,
    required this.dataUsageLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'score': score,
      'level': level.name,
      'riskFactors': riskFactors,
      'permissions': permissions.map((p) => {
        'name': p.name,
        'description': p.description,
        'isGranted': p.isGranted,
        'riskLevel': p.riskLevel.name,
      }).toList(),
      'backgroundActivityLevel': backgroundActivityLevel,
      'dataUsageLevel': dataUsageLevel,
    };
  }

  factory AppRiskScore.fromMap(Map<String, dynamic> map) {
    return AppRiskScore(
      packageName: map['packageName'] ?? '',
      score: map['score'] ?? 0,
      level: RiskLevel.values.firstWhere(
        (e) => e.name == map['level'],
        orElse: () => RiskLevel.low,
      ),
      riskFactors: List<String>.from(map['riskFactors'] ?? []),
      permissions: (map['permissions'] as List<dynamic>?)?.map((p) => PermissionInfo(
        name: p['name'] ?? '',
        description: p['description'] ?? '',
        isGranted: p['isGranted'] ?? false,
        riskLevel: RiskLevel.values.firstWhere(
          (e) => e.name == p['riskLevel'],
          orElse: () => RiskLevel.low,
        ),
      )).toList() ?? [],
      backgroundActivityLevel: map['backgroundActivityLevel'] ?? 0,
      dataUsageLevel: map['dataUsageLevel'] ?? 0,
    );
  }
}

// Battery Attribution
class AppBatteryUsage {
  final String packageName;
  final double estimatedDrainPercent; // percentage of total battery drain
  final int usageTimeMs;
  final double averageCpuUsage;

  AppBatteryUsage({
    required this.packageName,
    required this.estimatedDrainPercent,
    required this.usageTimeMs,
    required this.averageCpuUsage,
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'estimatedDrainPercent': estimatedDrainPercent,
      'usageTimeMs': usageTimeMs,
      'averageCpuUsage': averageCpuUsage,
    };
  }

  factory AppBatteryUsage.fromMap(Map<String, dynamic> map) {
    return AppBatteryUsage(
      packageName: map['packageName'] ?? '',
      estimatedDrainPercent: (map['estimatedDrainPercent'] as num?)?.toDouble() ?? 0.0,
      usageTimeMs: map['usageTimeMs'] ?? 0,
      averageCpuUsage: (map['averageCpuUsage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// Weekly Reports
class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalScreenTimeMs;
  final Map<AppCategory, int> categoryBreakdown;
  final List<AppUsageStats> topApps;
  final int totalDataUsageBytes;
  final List<AnomalyEvent> anomalies;
  final List<AppRiskScore> riskyApps;
  final double averageDailyUsageMs;

  WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.totalScreenTimeMs,
    required this.categoryBreakdown,
    required this.topApps,
    required this.totalDataUsageBytes,
    required this.anomalies,
    required this.riskyApps,
    required this.averageDailyUsageMs,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekStart': weekStart.millisecondsSinceEpoch,
      'weekEnd': weekEnd.millisecondsSinceEpoch,
      'totalScreenTimeMs': totalScreenTimeMs,
      'categoryBreakdown': categoryBreakdown.map((k, v) => MapEntry(k.name, v)),
      'topApps': topApps.map((a) => a.toMap()).toList(),
      'totalDataUsageBytes': totalDataUsageBytes,
      'anomalies': anomalies.map((a) => a.toMap()).toList(),
      'riskyApps': riskyApps.map((r) => r.toMap()).toList(),
      'averageDailyUsageMs': averageDailyUsageMs,
    };
  }

  factory WeeklyReport.fromMap(Map<String, dynamic> map) {
    return WeeklyReport(
      weekStart: DateTime.fromMillisecondsSinceEpoch(map['weekStart'] ?? 0),
      weekEnd: DateTime.fromMillisecondsSinceEpoch(map['weekEnd'] ?? 0),
      totalScreenTimeMs: map['totalScreenTimeMs'] ?? 0,
      categoryBreakdown: (map['categoryBreakdown'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(
          AppCategory.values.firstWhere((e) => e.name == k, orElse: () => AppCategory.other),
          v as int,
        ),
      ) ?? {},
      topApps: (map['topApps'] as List<dynamic>?)?.map((a) => AppUsageStats.fromMap(a)).toList() ?? [],
      totalDataUsageBytes: map['totalDataUsageBytes'] ?? 0,
      anomalies: (map['anomalies'] as List<dynamic>?)?.map((a) => AnomalyEvent.fromMap(a)).toList() ?? [],
      riskyApps: (map['riskyApps'] as List<dynamic>?)?.map((r) => AppRiskScore.fromMap(r)).toList() ?? [],
      averageDailyUsageMs: (map['averageDailyUsageMs'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
