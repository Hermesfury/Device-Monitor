import 'dart:async';
import 'package:dev_monitor/core/database_service.dart';
import 'package:dev_monitor/data/monitor_repository.dart';
import 'package:dev_monitor/domain/entities.dart';
import 'package:dev_monitor/platform/channels/monitor_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core Services
final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

final monitorChannelProvider = Provider<MonitorChannel>((ref) => MonitorChannel());

final monitorRepositoryProvider = Provider<MonitorRepository>((ref) {
  final channel = ref.watch(monitorChannelProvider);
  final db = ref.watch(databaseProvider).db;
  return MonitorRepository(channel, db);
});

// Live Metrics (CPU + RAM) — every 2 seconds
final liveMetricProvider = StreamProvider<MonitorMetric>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return Stream.periodic(const Duration(seconds: 2), (_) async {
    final metric = await repo.getLiveMetrics();
    // Check for anomalies
    final network = await repo.getNetworkStats();
    await repo.checkForAnomalies(metric, network, AnomalyThresholds());
    return metric;
  }).asyncMap((event) => event);
});

// Battery Info — every 5 seconds
final batteryInfoProvider = StreamProvider<BatteryInfo>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return Stream.periodic(const Duration(seconds: 5), (_) => repo.getBatteryInfo())
      .asyncMap((event) => event);
});

// Network Stats — every 2 seconds
final networkStatsProvider = StreamProvider<NetworkStats>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return Stream.periodic(const Duration(seconds: 2), (_) => repo.getNetworkStats())
      .asyncMap((event) => event);
});

// App Usage — every 30 seconds (usage stats don't change rapidly)
final appUsageProvider = StreamProvider<List<AppUsageInfo>>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return Stream.periodic(const Duration(seconds: 30), (_) => repo.getAppUsage())
      .asyncMap((event) => event);
});

// History (last 50 records)
final historyProvider = FutureProvider<List<MonitorMetric>>((ref) {
  // Refresh when live metric updates
  ref.watch(liveMetricProvider);
  final repo = ref.watch(monitorRepositoryProvider);
  return repo.getHistory(50);
});

// Storage Info — every 10 seconds
final storageInfoProvider = StreamProvider<StorageInfo>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return Stream.periodic(const Duration(seconds: 10), (_) => repo.getStorageInfo())
      .asyncMap((event) => event);
});

// Device Info — fetched once
final deviceInfoProvider = FutureProvider<DeviceInfo>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return repo.getDeviceInfo();
});

// Usage Insights — every 2 minutes for faster updates
final usageInsightsProvider = StreamProvider<UsageInsights>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return Stream.periodic(const Duration(minutes: 2), (_) => repo.getUsageInsights(DateTime.now()))
      .asyncMap((event) => event);
});

// Recent Anomalies — every 10 seconds
final anomaliesProvider = StreamProvider<List<AnomalyEvent>>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return Stream.periodic(const Duration(seconds: 10), (_) => repo.getRecentAnomalies(10))
      .asyncMap((event) => event);
});

// Risky Apps — every 10 minutes
final riskyAppsProvider = StreamProvider<List<AppRiskScore>>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return Stream.periodic(const Duration(minutes: 10), (_) async {
    final installedApps = await repo.getAppUsage(); // Get installed apps
    final riskyApps = <AppRiskScore>[];
    for (final app in installedApps.take(20)) { // Limit to top 20 for performance
      final score = await repo.getAppRiskScore(app.packageName) ?? await repo.calculateAppRiskScore(app.packageName);
      if (score.score >= 2) riskyApps.add(score);
    }
    return riskyApps;
  }).asyncMap((event) => event);
});

// Battery Usage by App — every 5 minutes
final batteryUsageProvider = StreamProvider<List<AppBatteryUsage>>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return Stream.periodic(const Duration(minutes: 5), (_) => repo.getBatteryUsageByApp())
      .asyncMap((event) => event);
});

// Weekly Reports — on demand
final weeklyReportsProvider = FutureProvider<List<WeeklyReport>>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return repo.getWeeklyReports(4); // Last 4 weeks
});

// Usage Session Collection — every 10 minutes
final usageSessionCollectorProvider = StreamProvider<void>((ref) {
  final repo = ref.watch(monitorRepositoryProvider);
  return Stream.periodic(const Duration(minutes: 10), (_) => repo.collectAndSaveUsageSessions())
      .asyncMap((event) => event);
});

