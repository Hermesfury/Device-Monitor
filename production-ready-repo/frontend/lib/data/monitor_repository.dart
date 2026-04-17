import 'dart:math';
import 'package:dev_monitor/domain/entities.dart';
import 'package:dev_monitor/platform/channels/monitor_channel.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class MonitorRepository {
  final MonitorChannel _channel;
  final Database _db;
  final _store = intMapStoreFactory.store('metrics_history');
  final _appUsageStore = intMapStoreFactory.store('app_usage_sessions');
  final _anomaliesStore = intMapStoreFactory.store('anomalies');
  final _riskScoresStore = intMapStoreFactory.store('risk_scores');
  final _weeklyReportsStore = intMapStoreFactory.store('weekly_reports');

  // Network speed delta tracking
  int _lastRxBytes = 0;
  int _lastTxBytes = 0;
  DateTime _lastNetworkTime = DateTime.now();

  MonitorRepository(this._channel, this._db);

  Future<MonitorMetric> getLiveMetrics() async {
    final cpu = await _channel.getCpuUsage();
    final mem = await _channel.getMemoryStats();

    final metric = MonitorMetric(
      cpuUsage: cpu,
      totalMem: (mem['totalMem'] as num?)?.toInt() ?? 0,
      usedMem: (mem['usedMem'] as num?)?.toInt() ?? 0,
      availMem: (mem['availMem'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.now(),
    );

    // Persist to history (keep last 100 records)
    await _store.add(_db, metric.toMap());
    await _pruneHistory(100);

    return metric;
  }

  Future<void> _pruneHistory(int maxRecords) async {
    final count = await _store.count(_db);
    if (count > maxRecords) {
      final finder = Finder(
        sortOrders: [SortOrder('timestamp', true)],
        limit: count - maxRecords,
      );
      await _store.delete(_db, finder: finder);
    }
  }

  Future<BatteryInfo> getBatteryInfo() async {
    final stats = await _channel.getBatteryStats();
    return BatteryInfo(
      level: (stats['level'] as num?)?.toDouble() ?? 0.0,
      isCharging: stats['isCharging'] as bool? ?? false,
      temperature: (stats['temperature'] as num?)?.toDouble() ?? 0.0,
      voltage: (stats['voltage'] as num?)?.toInt() ?? 0,
      capacity: (stats['capacity'] as num?)?.toInt() ?? 0,
      currentNow: (stats['currentNow'] as num?)?.toInt() ?? 0,
    );
  }

  Future<NetworkStats> getNetworkStats() async {
    final stats = await _channel.getNetworkStats();
    final now = DateTime.now();
    final rx = (stats['totalRxBytes'] as num?)?.toInt() ?? 0;
    final tx = (stats['totalTxBytes'] as num?)?.toInt() ?? 0;

    final elapsed = now.difference(_lastNetworkTime).inMilliseconds;
    double rxSpeed = 0;
    double txSpeed = 0;

    if (elapsed > 0 && _lastRxBytes > 0) {
      rxSpeed = (rx - _lastRxBytes) / (elapsed / 1000.0);
      txSpeed = (tx - _lastTxBytes) / (elapsed / 1000.0);
      if (rxSpeed < 0) rxSpeed = 0;
      if (txSpeed < 0) txSpeed = 0;
    }

    _lastRxBytes = rx;
    _lastTxBytes = tx;
    _lastNetworkTime = now;

    return NetworkStats(
      totalRxBytes: rx,
      totalTxBytes: tx,
      rxSpeedBps: rxSpeed,
      txSpeedBps: txSpeed,
    );
  }

  Future<List<AppUsageInfo>> getAppUsage() async {
    final stats = await _channel.getAppUsageStats();
    final list = stats
        .where((e) {
          final packageName = e['packageName'] as String? ?? '';
          final usageTime = (e['totalTimeInForeground'] as num? ?? 0);

          // Filter out system apps and apps with very little usage
          if (usageTime < 60000) return false; // Less than 1 minute

          // Skip system apps and common system processes
          if (packageName.startsWith('android.') ||
              packageName.startsWith('com.android.') ||
              packageName.contains('system') ||
              packageName.contains('launcher') ||
              packageName.contains('provider') ||
              packageName.contains('inputmethod') ||
              packageName.contains('wallpaper') ||
              packageName == 'com.google.android.gms' || // Google Play Services
              packageName == 'com.google.android.gsf') { // Google Services Framework
            return false;
          }

          return usageTime > 0;
        })
        .map((e) => AppUsageInfo(
              packageName: e['packageName'] as String? ?? '',
              totalTimeInForeground: (e['totalTimeInForeground'] as num?)?.toInt() ?? 0,
              lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(
                  (e['lastTimeUsed'] as num?)?.toInt() ?? 0),
            ))
        .toList();

    // Sort by usage time descending and take top 20
    list.sort((a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground));
    return list.take(20).toList();
  }

  Future<void> collectAndSaveUsageSessions() async {
    final sessions = await _channel.getAppUsageSessions();
    for (final sessionData in sessions) {
      final session = AppUsageSession(
        packageName: sessionData['packageName'] ?? '',
        startTime: DateTime.fromMillisecondsSinceEpoch(sessionData['startTime'] ?? 0),
        endTime: DateTime.fromMillisecondsSinceEpoch(sessionData['endTime'] ?? 0),
        durationMs: sessionData['durationMs'] ?? 0,
      );
      await saveAppUsageSession(session);
    }
  }

  Future<List<MonitorMetric>> getHistory(int limit) async {
    final finder = Finder(
      sortOrders: [SortOrder('timestamp', false)],
      limit: limit,
    );
    final records = await _store.find(_db, finder: finder);
    return records.map((e) => MonitorMetric.fromMap(e.value)).toList();
  }

  // Behavioral Intelligence Methods
  AppCategory _categorizeApp(String packageName, String appName) {
    final name = appName.toLowerCase();
    final pkg = packageName.toLowerCase();

    // Social & Communication
    if (pkg.contains('facebook') || pkg.contains('instagram') || pkg.contains('twitter') ||
        pkg.contains('snapchat') || pkg.contains('tiktok') || pkg.contains('linkedin') ||
        pkg.contains('discord') || pkg.contains('telegram') || pkg.contains('signal') ||
        pkg.contains('whatsapp') || pkg.contains('messenger') || pkg.contains('skype') ||
        name.contains('social') || name.contains('chat') || name.contains('message')) {
      return AppCategory.social;
    }

    // Productivity & Business
    if (pkg.contains('office') || pkg.contains('docs') || pkg.contains('sheets') ||
        pkg.contains('slides') || pkg.contains('drive') || pkg.contains('gmail') ||
        pkg.contains('outlook') || pkg.contains('calendar') || pkg.contains('todo') ||
        pkg.contains('notes') || pkg.contains('evernote') || pkg.contains('keep') ||
        pkg.contains('productivity') || pkg.contains('business') || name.contains('productivity')) {
      return AppCategory.productivity;
    }

    // Entertainment & Media
    if (pkg.contains('netflix') || pkg.contains('youtube') || pkg.contains('spotify') ||
        pkg.contains('music') || pkg.contains('video') || pkg.contains('hbo') ||
        pkg.contains('disney') || pkg.contains('prime') || pkg.contains('twitch') ||
        pkg.contains('pandora') || pkg.contains('soundcloud') || name.contains('music') ||
        name.contains('video') || name.contains('stream')) {
      return AppCategory.entertainment;
    }

    // Games
    if (pkg.contains('game') || pkg.contains('gaming') || pkg.contains('play') ||
        pkg.contains('minecraft') || pkg.contains('fortnite') || pkg.contains('pubg') ||
        pkg.contains('cod') || pkg.contains('among') || pkg.contains('candy') ||
        name.contains('game') || name.contains('gaming')) {
      return AppCategory.games;
    }

    // Finance & Banking
    if (pkg.contains('bank') || pkg.contains('finance') || pkg.contains('wallet') ||
        pkg.contains('pay') || pkg.contains('cash') || pkg.contains('money') ||
        pkg.contains('chase') || pkg.contains('boa') || pkg.contains('wells') ||
        pkg.contains('paypal') || pkg.contains('venmo') || pkg.contains('cashapp') ||
        name.contains('bank') || name.contains('finance')) {
      return AppCategory.finance;
    }

    // Health & Fitness
    if (pkg.contains('health') || pkg.contains('fitness') || pkg.contains('medical') ||
        pkg.contains('workout') || pkg.contains('gym') || pkg.contains('strava') ||
        pkg.contains('fitbit') || pkg.contains('myfitnesspal') || pkg.contains('nike') ||
        name.contains('health') || name.contains('fitness') || name.contains('medical')) {
      return AppCategory.health;
    }

    // Shopping & Commerce
    if (pkg.contains('shop') || pkg.contains('amazon') || pkg.contains('ebay') ||
        pkg.contains('aliexpress') || pkg.contains('walmart') || pkg.contains('target') ||
        pkg.contains('etsy') || pkg.contains('poshmark') || pkg.contains('mercari') ||
        name.contains('shop') || name.contains('store')) {
      return AppCategory.shopping;
    }

    // Education & Learning
    if (pkg.contains('edu') || pkg.contains('learn') || pkg.contains('school') ||
        pkg.contains('classroom') || pkg.contains('duolingo') || pkg.contains('khan') ||
        pkg.contains('coursera') || pkg.contains('udemy') || pkg.contains('edx') ||
        name.contains('edu') || name.contains('learn') || name.contains('school')) {
      return AppCategory.education;
    }

    // Utilities & System
    if (pkg.contains('com.android.') || pkg.contains('system') || pkg.contains('settings') ||
        pkg.contains('file') || pkg.contains('manager') || pkg.contains('browser') ||
        pkg.contains('calculator') || pkg.contains('clock') || pkg.contains('weather') ||
        name.contains('system') || name.contains('utility')) {
      return AppCategory.utilities;
    }

    // Communication (phone, SMS, etc.)
    if (pkg.contains('phone') || pkg.contains('dialer') || pkg.contains('contacts') ||
        pkg.contains('sms') || pkg.contains('mms') || pkg.contains('message') ||
        name.contains('phone') || name.contains('dialer')) {
      return AppCategory.communication;
    }

    return AppCategory.other;
  }

  Future<void> saveAppUsageSession(AppUsageSession session) async {
    await _appUsageStore.add(_db, session.toMap());
    await _pruneOldSessions(7); // Keep last 7 days
  }

  Future<void> _pruneOldSessions(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final finder = Finder(
      filter: Filter.lessThan('startTime', cutoff.millisecondsSinceEpoch),
    );
    await _appUsageStore.delete(_db, finder: finder);
  }

  Future<List<AppUsageStats>> getAppUsageStats({DateTime? startDate, DateTime? endDate}) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 1));
    final end = endDate ?? DateTime.now();

    final finder = Finder(
      filter: Filter.and([
        Filter.greaterThanOrEquals('startTime', start.millisecondsSinceEpoch),
        Filter.lessThanOrEquals('endTime', end.millisecondsSinceEpoch),
      ]),
    );

    final records = await _appUsageStore.find(_db, finder: finder);
    final sessions = records.map((r) => AppUsageSession.fromMap(r.value)).toList();

    final statsMap = <String, AppUsageStats>{};

    for (final session in sessions) {
      final appName = session.packageName.split('.').last
          .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (m) => ' ')
          .split(RegExp(r'[ _]'))
          .where((s) => s.isNotEmpty)
          .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
          .join(' ');

      final category = _categorizeApp(session.packageName, appName);

      if (statsMap.containsKey(session.packageName)) {
        final existing = statsMap[session.packageName]!;
        statsMap[session.packageName] = AppUsageStats(
          packageName: session.packageName,
          appName: appName,
          category: category,
          totalUsageMs: existing.totalUsageMs + session.durationMs,
          sessionsCount: existing.sessionsCount + 1,
          lastUsed: session.endTime.isAfter(existing.lastUsed) ? session.endTime : existing.lastUsed,
          firstSeen: session.startTime.isBefore(existing.firstSeen) ? session.startTime : existing.firstSeen,
        );
      } else {
        statsMap[session.packageName] = AppUsageStats(
          packageName: session.packageName,
          appName: appName,
          category: category,
          totalUsageMs: session.durationMs,
          sessionsCount: 1,
          lastUsed: session.endTime,
          firstSeen: session.startTime,
        );
      }
    }

    final stats = statsMap.values.toList()
      ..sort((a, b) => b.totalUsageMs.compareTo(a.totalUsageMs));

    return stats;
  }

  Future<UsageInsights> getUsageInsights(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final stats = await getAppUsageStats(startDate: startOfDay, endDate: endOfDay);

    // If no session data available, fall back to basic usage stats
    if (stats.isEmpty) {
      final basicUsage = await getAppUsage();
      final fallbackStats = basicUsage.map((usage) {
        final appName = usage.appName;
        final category = _categorizeApp(usage.packageName, appName);
        return AppUsageStats(
          packageName: usage.packageName,
          appName: appName,
          category: category,
          totalUsageMs: usage.totalTimeInForeground,
          sessionsCount: 1, // Estimate as 1 session
          lastUsed: usage.lastTimeUsed,
          firstSeen: usage.lastTimeUsed,
        );
      }).toList();

      final totalScreenTime = fallbackStats.fold<int>(0, (sum, app) => sum + app.totalUsageMs);
      final topApps = fallbackStats.take(5).toList();

      final categoryUsage = <AppCategory, int>{};
      for (final app in fallbackStats) {
        categoryUsage[app.category] = (categoryUsage[app.category] ?? 0) + app.totalUsageMs;
      }

      final totalSessions = fallbackStats.length;
      final averageSession = totalSessions > 0 ? totalScreenTime ~/ totalSessions : 0;

      return UsageInsights(
        totalScreenTimeMs: totalScreenTime,
        topApps: topApps,
        categoryUsage: categoryUsage,
        averageSessionMs: averageSession,
        peakUsageHour: DateTime.now(),
        totalSessions: totalSessions,
      );
    }

    final totalScreenTime = stats.fold<int>(0, (sum, app) => sum + app.totalUsageMs);
    final topApps = stats.take(5).toList();

    final categoryUsage = <AppCategory, int>{};
    for (final app in stats) {
      categoryUsage[app.category] = (categoryUsage[app.category] ?? 0) + app.totalUsageMs;
    }

    final totalSessions = stats.fold<int>(0, (sum, app) => sum + app.sessionsCount);
    final averageSession = totalSessions > 0 ? totalScreenTime ~/ totalSessions : 0;

    // Simple peak hour detection (mock for now)
    final peakUsageHour = DateTime.now(); // TODO: Implement proper peak hour detection

    return UsageInsights(
      totalScreenTimeMs: totalScreenTime,
      topApps: topApps,
      categoryUsage: categoryUsage,
      averageSessionMs: averageSession,
      peakUsageHour: peakUsageHour,
      totalSessions: totalSessions,
    );
  }

  Future<StorageInfo> getStorageInfo() async {
    final stats = await _channel.getStorageInfo();
    return StorageInfo(
      totalBytes: (stats['totalBytes'] as num?)?.toInt() ?? 0,
      freeBytes: (stats['freeBytes'] as num?)?.toInt() ?? 0,
      usedBytes: (stats['usedBytes'] as num?)?.toInt() ?? 0,
    );
  }

  Future<DeviceInfo> getDeviceInfo() async {
    final stats = await _channel.getDeviceInfo();
    return DeviceInfo(
      brand: stats['brand'] as String? ?? 'Unknown',
      model: stats['model'] as String? ?? 'Device',
      device: stats['device'] as String? ?? 'Unknown',
      board: stats['board'] as String? ?? 'Unknown',
      hardware: stats['hardware'] as String? ?? 'Unknown',
      osVersion: stats['osVersion'] as String? ?? 'Unknown',
      sdkInt: (stats['sdkInt'] as num?)?.toInt() ?? 0,
    );
  }

  // Anomaly Detection Methods
  Future<void> logAnomaly(AnomalyEvent anomaly) async {
    await _anomaliesStore.add(_db, anomaly.toMap());
    await _pruneOldAnomalies(30); // Keep last 30 days
  }

  Future<void> _pruneOldAnomalies(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final finder = Finder(
      filter: Filter.lessThan('timestamp', cutoff.millisecondsSinceEpoch),
    );
    await _anomaliesStore.delete(_db, finder: finder);
  }

  Future<List<AnomalyEvent>> getRecentAnomalies(int limit) async {
    final finder = Finder(
      sortOrders: [SortOrder('timestamp', false)],
      limit: limit,
    );
    final records = await _anomaliesStore.find(_db, finder: finder);
    return records.map((r) => AnomalyEvent.fromMap(r.value)).toList();
  }

  Future<void> checkForAnomalies(MonitorMetric current, NetworkStats network, AnomalyThresholds thresholds) async {
    final now = DateTime.now();
    final hour = now.hour;

    // CPU Spike Detection
    if (current.cpuUsage >= thresholds.cpuSpikeThreshold) {
      // Check if sustained (look at recent history)
      final recentMetrics = await getHistory(10); // Last 20 seconds (2s intervals)
      final sustainedSpike = recentMetrics.where((m) => m.cpuUsage >= thresholds.cpuSpikeThreshold).length >= 5;

      if (sustainedSpike) {
        await logAnomaly(AnomalyEvent(
          type: AnomalyType.cpuSpike,
          timestamp: now,
          description: 'CPU usage spiked to ${current.cpuUsage.toStringAsFixed(1)}% for ${thresholds.cpuSpikeDurationMs ~/ 1000}s',
          details: {'cpuUsage': current.cpuUsage, 'durationMs': thresholds.cpuSpikeDurationMs},
          severity: (current.cpuUsage - thresholds.cpuSpikeThreshold) / (100 - thresholds.cpuSpikeThreshold),
        ));
      }
    }

    // High Memory Usage
    if (current.memUsagePercent >= thresholds.memoryThreshold) {
      await logAnomaly(AnomalyEvent(
        type: AnomalyType.highMemoryUsage,
        timestamp: now,
        description: 'Memory usage reached ${current.memUsagePercent.toStringAsFixed(1)}%',
        details: {'memoryPercent': current.memUsagePercent},
        severity: (current.memUsagePercent - thresholds.memoryThreshold) / (100 - thresholds.memoryThreshold),
      ));
    }

    // Network Spike
    if (network.rxSpeedBps + network.txSpeedBps >= thresholds.networkSpikeThreshold) {
      await logAnomaly(AnomalyEvent(
        type: AnomalyType.unusualNetworkActivity,
        timestamp: now,
        description: 'Network activity spiked to ${(network.rxSpeedBps + network.txSpeedBps) / 1000000} MB/s',
        details: {'rxSpeed': network.rxSpeedBps, 'txSpeed': network.txSpeedBps},
        severity: min(1.0, (network.rxSpeedBps + network.txSpeedBps) / (thresholds.networkSpikeThreshold * 2)),
      ));
    }

    // Unusual Hour Activity (if high CPU usage at unusual hour)
    if (!thresholds.normalHours.contains(hour) && current.cpuUsage > 20.0) {
      await logAnomaly(AnomalyEvent(
        type: AnomalyType.unusualHourActivity,
        timestamp: now,
        description: 'High CPU usage (${current.cpuUsage.toStringAsFixed(1)}%) detected at unusual hour (${hour}:00)',
        details: {'hour': hour, 'cpuUsage': current.cpuUsage},
        severity: 0.4,
      ));
    }

    // Background Activity Spike (if CPU usage high when no active apps)
    final recentUsage = await getAppUsage();
    final hasActiveApps = recentUsage.any((app) => app.totalTimeInForeground > 60000); // 1 minute recently
    if (!hasActiveApps && current.cpuUsage > 30.0) {
      await logAnomaly(AnomalyEvent(
        type: AnomalyType.backgroundActivitySpike,
        timestamp: now,
        description: 'High background CPU usage (${current.cpuUsage.toStringAsFixed(1)}%) with no active apps',
        details: {'cpuUsage': current.cpuUsage, 'activeApps': hasActiveApps},
        severity: 0.5,
      ));
    }
  }

  // App Risk Scoring Methods
  Future<AppRiskScore> calculateAppRiskScore(String packageName) async {
    // Get app permissions (mock for now - need platform channel)
    final permissions = await _channel.getAppPermissions(packageName);
    final permissionInfos = <PermissionInfo>[];

    int riskScore = 0;
    final riskFactors = <String>[];

    // Analyze permissions
    for (final perm in permissions.entries) {
      final name = perm.key;
      final granted = perm.value as bool;

      if (!granted) continue;

      RiskLevel permRisk = RiskLevel.low;
      String desc = 'Unknown permission';

      if (name.contains('CAMERA')) {
        permRisk = RiskLevel.medium;
        desc = 'Access to camera';
        riskScore += 3;
        riskFactors.add('Camera access');
      } else if (name.contains('MICROPHONE') || name.contains('RECORD_AUDIO')) {
        permRisk = RiskLevel.high;
        desc = 'Access to microphone';
        riskScore += 4;
        riskFactors.add('Microphone access');
      } else if (name.contains('LOCATION') || name.contains('GPS') || name.contains('FINE_LOCATION')) {
        permRisk = RiskLevel.medium;
        desc = 'Access to precise location';
        riskScore += 3;
        riskFactors.add('Location tracking');
      } else if (name.contains('STORAGE') || name.contains('READ_EXTERNAL') || name.contains('WRITE_EXTERNAL')) {
        permRisk = RiskLevel.low;
        desc = 'Access to storage';
        riskScore += 1;
        riskFactors.add('Storage access');
      } else if (name.contains('CONTACTS')) {
        permRisk = RiskLevel.medium;
        desc = 'Access to contacts';
        riskScore += 2;
        riskFactors.add('Contacts access');
      } else if (name.contains('PHONE') || name.contains('READ_PHONE_STATE')) {
        permRisk = RiskLevel.medium;
        desc = 'Access to phone state';
        riskScore += 2;
        riskFactors.add('Phone state access');
      } else if (name.contains('SMS') || name.contains('READ_SMS') || name.contains('SEND_SMS')) {
        permRisk = RiskLevel.high;
        desc = 'Access to SMS';
        riskScore += 4;
        riskFactors.add('SMS access');
      } else if (name.contains('CALL_LOG') || name.contains('READ_CALL_LOG')) {
        permRisk = RiskLevel.high;
        desc = 'Access to call logs';
        riskScore += 4;
        riskFactors.add('Call log access');
      } else if (name.contains('INTERNET')) {
        permRisk = RiskLevel.low;
        desc = 'Internet access';
        riskScore += 1;
        riskFactors.add('Internet access');
      } else if (name.contains('WAKE_LOCK') || name.contains('FOREGROUND_SERVICE')) {
        permRisk = RiskLevel.low;
        desc = 'Background execution';
        riskScore += 1;
        riskFactors.add('Background execution');
      }

      permissionInfos.add(PermissionInfo(
        name: name,
        description: desc,
        isGranted: granted,
        riskLevel: permRisk,
      ));
    }

    // Analyze background activity (based on usage patterns)
    final usageStats = await getAppUsageStats();
    final appStat = usageStats.where((s) => s.packageName == packageName).firstOrNull;
    int backgroundActivity = 0;

    if (appStat != null) {
      // High usage might indicate background services
      if (appStat.totalUsageMs > 3600000) { // 1 hour
        backgroundActivity = 3;
        riskScore += 1;
        riskFactors.add('High background activity');
      }
    }

    // Analyze data usage (mock - need to implement per-app data tracking)
    int dataUsage = 0;

    RiskLevel level;
    if (riskScore <= 3) level = RiskLevel.low;
    else if (riskScore <= 6) level = RiskLevel.medium;
    else level = RiskLevel.high;

    final score = AppRiskScore(
      packageName: packageName,
      score: min(10, riskScore),
      level: level,
      riskFactors: riskFactors,
      permissions: permissionInfos,
      backgroundActivityLevel: backgroundActivity,
      dataUsageLevel: dataUsage,
    );

    // Cache the score - check if exists and update, or add new
    final existing = await _riskScoresStore.findFirst(_db,
      finder: Finder(filter: Filter.equals('packageName', packageName)));

    if (existing != null) {
      await _riskScoresStore.record(existing.key).update(_db, score.toMap());
    } else {
      await _riskScoresStore.add(_db, score.toMap());
    }

    return score;
  }

  Future<List<AppRiskScore>> getRiskyApps({int minScore = 4}) async {
    final finder = Finder(
      filter: Filter.greaterThanOrEquals('score', minScore),
      sortOrders: [SortOrder('score', false)],
    );
    final records = await _riskScoresStore.find(_db, finder: finder);
    return records.map((r) => AppRiskScore.fromMap(r.value)).toList();
  }

  Future<AppRiskScore?> getAppRiskScore(String packageName) async {
    final record = await _riskScoresStore.findFirst(_db,
      finder: Finder(filter: Filter.equals('packageName', packageName)));
    if (record != null) {
      return AppRiskScore.fromMap(record.value);
    }
    return null;
  }

  // Battery Attribution Methods
  Future<List<AppBatteryUsage>> getBatteryUsageByApp() async {
    // Get recent usage stats (last 24 hours)
    final usageStats = await getAppUsageStats(startDate: DateTime.now().subtract(const Duration(hours: 24)));
    final cpuHistory = await getHistory(100); // Last ~3.3 hours

    // Calculate average system CPU usage during the period
    final avgSystemCpu = cpuHistory.isNotEmpty
        ? cpuHistory.map((m) => m.cpuUsage).reduce((a, b) => a + b) / cpuHistory.length
        : 10.0; // Default 10% if no data

    final batteryUsages = <AppBatteryUsage>[];

    for (final app in usageStats) {
      // Estimate CPU usage per app based on usage time vs total possible time
      final usageHours = app.totalUsageMs / (1000 * 60 * 60); // Convert to hours
      final totalHours = 24.0; // 24 hours period
      final usageRatio = usageHours / totalHours;

      // Estimate app's CPU contribution (rough approximation)
      final estimatedCpuUsage = max(5.0, avgSystemCpu * usageRatio * 2); // Minimum 5%, scale up usage ratio

      // Battery drain estimation: CPU usage * time factor * efficiency factor
      final timeFactor = usageHours / 24.0; // Fraction of day used
      final estimatedDrain = estimatedCpuUsage * timeFactor * 1.2; // 1.2x factor for battery drain vs CPU

      batteryUsages.add(AppBatteryUsage(
        packageName: app.packageName,
        estimatedDrainPercent: min(50.0, max(0.1, estimatedDrain)), // Cap at 50%, minimum 0.1%
        usageTimeMs: app.totalUsageMs,
        averageCpuUsage: estimatedCpuUsage,
      ));
    }

    batteryUsages.sort((a, b) => b.estimatedDrainPercent.compareTo(a.estimatedDrainPercent));
    return batteryUsages.take(10).toList(); // Return top 10
  }

  // Weekly Reports Methods
  Future<WeeklyReport> generateWeeklyReport() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final weekEnd = weekStart.add(const Duration(days: 7));

    final usageStats = await getAppUsageStats(startDate: weekStart, endDate: weekEnd);
    final anomalies = await getRecentAnomalies(100); // Last 100 anomalies
    final riskyApps = await getRiskyApps(minScore: 4);

    final totalScreenTime = usageStats.fold<int>(0, (sum, app) => sum + app.totalUsageMs);

    final categoryBreakdown = <AppCategory, int>{};
    for (final app in usageStats) {
      categoryBreakdown[app.category] = (categoryBreakdown[app.category] ?? 0) + app.totalUsageMs;
    }

    final topApps = usageStats.take(5).toList();

    // Mock data usage - need to implement proper tracking
    final totalDataUsage = 0; // TODO: Track per-app data usage

    final averageDaily = totalScreenTime ~/ 7;

    final report = WeeklyReport(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalScreenTimeMs: totalScreenTime,
      categoryBreakdown: categoryBreakdown,
      topApps: topApps,
      totalDataUsageBytes: totalDataUsage,
      anomalies: anomalies.where((a) =>
        a.timestamp.isAfter(weekStart) && a.timestamp.isBefore(weekEnd)).toList(),
      riskyApps: riskyApps,
      averageDailyUsageMs: averageDaily.toDouble(),
    );

    // Save report
    await _weeklyReportsStore.add(_db, report.toMap());
    await _pruneOldReports(12); // Keep last 12 weeks

    return report;
  }

  Future<void> _pruneOldReports(int weeks) async {
    final cutoff = DateTime.now().subtract(Duration(days: weeks * 7));
    final finder = Finder(
      filter: Filter.lessThan('weekStart', cutoff.millisecondsSinceEpoch),
    );
    await _weeklyReportsStore.delete(_db, finder: finder);
  }

  Future<List<WeeklyReport>> getWeeklyReports(int limit) async {
    final finder = Finder(
      sortOrders: [SortOrder('weekStart', false)],
      limit: limit,
    );
    final records = await _weeklyReportsStore.find(_db, finder: finder);
    return records.map((r) => WeeklyReport.fromMap(r.value)).toList();
  }
}

