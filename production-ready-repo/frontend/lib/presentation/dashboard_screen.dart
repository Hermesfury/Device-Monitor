import 'package:dev_monitor/domain/entities.dart';
import 'package:dev_monitor/platform/channels/monitor_channel.dart';
import 'package:dev_monitor/presentation/providers.dart';
import 'package:dev_monitor/presentation/widgets/gauge_card.dart';
import 'package:dev_monitor/presentation/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut));
    _headerAnim.forward();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveMetric = ref.watch(liveMetricProvider);
    final batteryInfo = ref.watch(batteryInfoProvider);
    final networkStats = ref.watch(networkStatsProvider);
    final appUsage = ref.watch(appUsageProvider);
    final usageInsights = ref.watch(usageInsightsProvider);
    final anomalies = ref.watch(anomaliesProvider);
    final riskyApps = ref.watch(riskyAppsProvider);
    final batteryUsage = ref.watch(batteryUsageProvider);
    final deviceInfo = ref.watch(deviceInfoProvider);
    final storageInfo = ref.watch(storageInfoProvider);
    // Trigger usage session collection
    ref.watch(usageSessionCollectorProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(liveMetric),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // CPU + RAM Gauges row
                _buildGaugesRow(liveMetric),
                const SizedBox(height: 20),
                // Battery
                _buildSectionTitle('Battery'),
                const SizedBox(height: 12),
                _buildBatterySection(batteryInfo),
                const SizedBox(height: 20),
                // RAM Boost
                _buildSectionTitle('RAM Optimization'),
                const SizedBox(height: 12),
                _buildRamBoostSection(),
                const SizedBox(height: 20),
                // Storage
                _buildSectionTitle('Internal Storage'),
                const SizedBox(height: 12),
                _buildStorageSection(storageInfo),
                const SizedBox(height: 20),
                // Network
                _buildSectionTitle('Network'),
                const SizedBox(height: 12),
                _buildNetworkSection(networkStats),
                const SizedBox(height: 20),
                // App usage
                _buildSectionTitle('Top Apps (24h)'),
                const SizedBox(height: 12),
                _buildAppUsageSection(appUsage),
                const SizedBox(height: 20),
                // Behavioral Insights
                _buildSectionTitle('Daily Insights'),
                const SizedBox(height: 12),
                _buildInsightsSection(usageInsights),
                const SizedBox(height: 20),
                // Anomalies
                _buildSectionTitle('Recent Anomalies'),
                const SizedBox(height: 12),
                _buildAnomaliesSection(anomalies),
                const SizedBox(height: 20),
                // Risky Apps
                _buildSectionTitle('Risky Apps'),
                const SizedBox(height: 12),
                _buildRiskyAppsSection(riskyApps),
                const SizedBox(height: 20),
                // Battery Attribution
                _buildSectionTitle('Battery Usage by App'),
                const SizedBox(height: 12),
                _buildBatteryUsageSection(batteryUsage),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(AsyncValue<MonitorMetric> liveMetric) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _headerFade,
        child: SlideTransition(
          position: _headerSlide,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1040), Color(0xFF0D1730)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Monitor',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        ref.watch(deviceInfoProvider).when(
                          data: (d) => Text(d.displayName, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildLiveIndicator(liveMetric),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'System Overview',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white38,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                liveMetric.when(
                  data: (m) => Text(
                    'CPU ${m.cpuUsage.toStringAsFixed(1)}%  •  '
                    'RAM ${(m.memUsagePercent * 100).toStringAsFixed(0)}%  •  '
                    '${(m.usedMem / 1024 / 1024 / 1024).toStringAsFixed(1)} GB used',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  loading: () => Text('Connecting...', style: GoogleFonts.inter(color: Colors.white30, fontSize: 14)),
                  error: (_, __) => Text('Error', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveIndicator(AsyncValue<MonitorMetric> liveMetric) {
    return liveMetric.when(
      data: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00D4AA).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(
              color: Color(0xFF00D4AA), shape: BoxShape.circle,
            )),
            const SizedBox(width: 6),
            Text('LIVE', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: Color(0xFF00D4AA), letterSpacing: 0.6,
            )),
          ],
        ),
      ),
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('...', style: GoogleFonts.inter(fontSize: 11, color: Colors.white30)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        color: Colors.white38,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildGaugesRow(AsyncValue<MonitorMetric> liveMetric) {
    return liveMetric.when(
      data: (m) => Row(
        children: [
          Expanded(
            child: GaugeCard(
              label: 'CPU Usage',
              value: (m.cpuUsage / 100).clamp(0.0, 1.0),
              valueText: '${m.cpuUsage.toStringAsFixed(1)}%',
              primaryColor: const Color(0xFF6C63FF),
              secondaryColor: const Color(0xFF9B61E5),
              icon: Icons.memory_rounded,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GaugeCard(
              label: 'RAM Usage',
              value: m.memUsagePercent.clamp(0.0, 1.0),
              valueText: '${(m.memUsagePercent * 100).toStringAsFixed(0)}%',
              primaryColor: const Color(0xFF00D4AA),
              secondaryColor: const Color(0xFF00A884),
              icon: Icons.developer_board_rounded,
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: [
          Expanded(child: _buildGaugeSkeleton()),
          const SizedBox(width: 16),
          Expanded(child: _buildGaugeSkeleton()),
        ],
      ),
      error: (_, __) => _buildErrorCard('Could not load metrics'),
    );
  }

  Widget _buildGaugeSkeleton() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: const Center(child: CircularProgressIndicator(
        color: Color(0xFF6C63FF), strokeWidth: 2,
      )),
    );
  }

  Widget _buildBatterySection(AsyncValue<BatteryInfo> batteryInfo) {
    return batteryInfo.when(
      data: (info) {
        final isLow = info.level < 20;
        final batteryColor = isLow
            ? Colors.redAccent
            : info.isCharging
                ? const Color(0xFF00D4AA)
                : const Color(0xFFFFC107);

        return Column(
          children: [
            StatCard(
              label: 'BATTERY LEVEL',
              value: '${info.level.toStringAsFixed(0)}%',
              icon: info.isCharging
                  ? Icons.battery_charging_full_rounded
                  : isLow
                      ? Icons.battery_alert_rounded
                      : Icons.battery_std_rounded,
              color: batteryColor,
              subtitle: info.chargingStatus,
              trailing: Text(
                '${info.temperature.toStringAsFixed(1)}°C',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: info.temperature > 40 ? Colors.redAccent : Colors.white38,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildBatteryProgressBar(info.level / 100, batteryColor),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStatTile(
                    icon: Icons.electrical_services_rounded,
                    label: 'Voltage',
                    value: '${info.voltage} mV',
                    color: const Color(0xFFFFC107),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniStatTile(
                    icon: Icons.battery_full_rounded,
                    label: 'Capacity',
                    value: '${info.capacity}%',
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(color: Color(0xFFFFC107)),
      error: (_, __) => _buildErrorCard('Could not load battery info'),
    );
  }

  Widget _buildBatteryProgressBar(double value, Color color) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageSection(AsyncValue<StorageInfo> storageInfo) {
    return storageInfo.when(
      data: (info) {
        final usedColor = const Color(0xFF9B61E5);
        return Column(
          children: [
            StatCard(
              label: 'STORAGE CAPACITY',
              value: '${(info.usedBytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB Used',
              icon: Icons.storage_rounded,
              color: usedColor,
              subtitle: 'of ${(info.totalBytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB total',
              trailing: Text(
                '${(info.usedPercentage * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildBatteryProgressBar(info.usedPercentage, usedColor),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(color: Color(0xFF9B61E5)),
      error: (_, __) => _buildErrorCard('Could not load storage info'),
    );
  }

  Widget _buildNetworkSection(AsyncValue<NetworkStats> networkStats) {
    return networkStats.when(
      data: (stats) => Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'DOWNLOAD',
              value: NetworkStats.formatSpeed(stats.rxSpeedBps),
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF00D4AA),
              subtitle: _formatBytes(stats.totalRxBytes) + ' total',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'UPLOAD',
              value: NetworkStats.formatSpeed(stats.txSpeedBps),
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFF6C63FF),
              subtitle: _formatBytes(stats.totalTxBytes) + ' total',
            ),
          ),
        ],
      ),
      loading: () => const LinearProgressIndicator(color: Color(0xFF00D4AA)),
      error: (_, __) => _buildErrorCard('Could not load network stats'),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  Widget _buildAppUsageSection(AsyncValue<List<AppUsageInfo>> appUsage) {
    return appUsage.when(
      data: (list) {
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF131929),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                const Icon(Icons.apps_rounded, size: 40, color: Colors.white12),
                const SizedBox(height: 12),
                Text(
                  'No usage data',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grant Usage Access in Settings to see app data',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final topApps = list.take(7).toList();
        final maxTime = topApps.first.totalTimeInForeground.toDouble();

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            children: topApps.asMap().entries.map((entry) {
              final idx = entry.key;
              final app = entry.value;
              final ratio = maxTime > 0 ? app.totalTimeInForeground / maxTime : 0.0;
              return _buildAppUsageItem(app, ratio, idx == topApps.length - 1);
            }).toList(),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(color: Color(0xFF6C63FF)),
      error: (_, __) => _buildErrorCard('Could not load app usage'),
    );
  }

  Widget _buildAppUsageItem(AppUsageInfo app, double ratio, bool isLast) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00D4AA),
      const Color(0xFFFFC107),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFFFFBE0B),
    ];
    final color = colors[app.packageName.hashCode.abs() % colors.length];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: ratio.clamp(0.0, 1.0),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                app.usageTime,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: Colors.white.withOpacity(0.05), indent: 20, endIndent: 20),
      ],
    );
  }

  Widget _buildMiniStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white30)),
                Text(value, style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(AsyncValue<UsageInsights> insights) {
    return insights.when(
      data: (data) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_rounded, color: Color(0xFF6C63FF), size: 20),
                const SizedBox(width: 8),
                Text('Screen Time: ${data.formattedTotalScreenTime}',
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('Top App', data.topApps.isNotEmpty ? data.topApps[0].appName : 'N/A'),
                _buildStatItem('Sessions', data.totalSessions.toString()),
                _buildStatItem('Categories', data.categoryUsage.length.toString()),
              ],
            ),
          ],
        ),
      ),
      loading: () => _buildLoadingCard(),
      error: (err, stack) => _buildErrorCard('Failed to load insights'),
    );
  }

  Widget _buildAnomaliesSection(AsyncValue<List<AnomalyEvent>> anomalies) {
    return anomalies.when(
      data: (data) => data.isEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131929),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 12),
                  Text('No anomalies detected', style: GoogleFonts.inter(color: Colors.white70)),
                ],
              ),
            )
          : Column(
              children: data.take(3).map((anomaly) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getAnomalyColor(anomaly.severity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getAnomalyColor(anomaly.severity).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_getAnomalyIcon(anomaly.type), color: _getAnomalyColor(anomaly.severity), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        anomaly.description,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
      loading: () => _buildLoadingCard(),
      error: (err, stack) => _buildErrorCard('Failed to load anomalies'),
    );
  }

  Color _getAnomalyColor(double severity) {
    if (severity >= 0.7) return Colors.redAccent;
    if (severity >= 0.4) return Colors.orangeAccent;
    return Colors.yellowAccent;
  }

  IconData _getAnomalyIcon(AnomalyType type) {
    switch (type) {
      case AnomalyType.cpuSpike: return Icons.memory_rounded;
      case AnomalyType.highMemoryUsage: return Icons.storage_rounded;
      case AnomalyType.unusualNetworkActivity: return Icons.wifi_rounded;
      case AnomalyType.backgroundActivitySpike: return Icons.apps_rounded;
      case AnomalyType.unusualHourActivity: return Icons.schedule_rounded;
    }
  }

  Widget _buildRiskyAppsSection(AsyncValue<List<AppRiskScore>> riskyApps) {
    return riskyApps.when(
      data: (data) => data.isEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131929),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 12),
                  Text('No risky apps detected', style: GoogleFonts.inter(color: Colors.white70)),
                ],
              ),
            )
          : Column(
              children: data.take(3).map((app) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRiskColor(app.level).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getRiskColor(app.level).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_getRiskIcon(app.level), color: _getRiskColor(app.level), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.packageName.split('.').last,
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Risk: ${app.score}/10',
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
      loading: () => _buildLoadingCard(),
      error: (err, stack) => _buildErrorCard('Failed to load risky apps'),
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low: return Colors.greenAccent;
      case RiskLevel.medium: return Colors.orangeAccent;
      case RiskLevel.high: return Colors.redAccent;
    }
  }

  IconData _getRiskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.low: return Icons.shield_rounded;
      case RiskLevel.medium: return Icons.warning_rounded;
      case RiskLevel.high: return Icons.dangerous_rounded;
    }
  }

  Widget _buildBatteryUsageSection(AsyncValue<List<AppBatteryUsage>> batteryUsage) {
    return batteryUsage.when(
      data: (data) => data.isEmpty
          ? _buildEmptyCard('No battery usage data')
          : Column(
              children: data.take(5).map((usage) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131929),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.battery_alert_rounded, color: Color(0xFF00D4AA), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        usage.packageName.split('.').last,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                      ),
                    ),
                    Text(
                      '${usage.estimatedDrainPercent.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF00D4AA), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )).toList(),
            ),
      loading: () => _buildLoadingCard(),
      error: (err, stack) => _buildErrorCard('Failed to load battery usage'),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white30)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white30, size: 20),
          const SizedBox(width: 12),
          Text(message, style: GoogleFonts.inter(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildRamBoostSection() {
    final deviceInfo = ref.watch(deviceInfoProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.memory_rounded, color: Color(0xFF00D4AA), size: 20),
              const SizedBox(width: 8),
              Text('RAM Boost', style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          deviceInfo.when(
            data: (d) => Text(
              d.displayName,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
            loading: () => Text(
              'Loading...',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
            error: (_, __) => Text(
              'Unknown Device',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _performRamBoost(context),
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: Text('Boost RAM', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performRamBoost(BuildContext context) async {
    try {
      final channel = ref.read(monitorChannelProvider);
      final processesKilled = await channel.performRamBoost();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'RAM Boost Complete! $processesKilled background processes closed.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF00D4AA),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'RAM Boost failed. Please try again.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Text(message, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
        ],
      ),
    );
  }
}
