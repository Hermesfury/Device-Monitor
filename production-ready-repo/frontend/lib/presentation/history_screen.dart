import 'package:dev_monitor/domain/entities.dart';
import 'package:dev_monitor/presentation/providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      data: (history) => history.isEmpty
          ? _buildEmpty()
          : _buildCharts(history),
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      ),
      error: (e, _) => Center(
        child: Text('Error loading history', style: GoogleFonts.inter(color: Colors.white54)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: GoogleFonts.inter(fontSize: 18, color: Colors.white38, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Data will appear as the monitor collects metrics',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white24),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(List<MonitorMetric> history) {
    // History is newest-first, reverse for chronological display
    final chronological = history.reversed.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('CPU Usage History', const Color(0xFF6C63FF)),
          const SizedBox(height: 16),
          _buildLineChart(
            data: chronological.map((m) => m.cpuUsage).toList(),
            color: const Color(0xFF6C63FF),
            maxY: 100,
            suffix: '%',
            timestamps: chronological.map((m) => m.timestamp).toList(),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('RAM Usage History', const Color(0xFF00D4AA)),
          const SizedBox(height: 16),
          _buildLineChart(
            data: chronological.map((m) => m.memUsagePercent * 100).toList(),
            color: const Color(0xFF00D4AA),
            maxY: 100,
            suffix: '%',
            timestamps: chronological.map((m) => m.timestamp).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart({
    required List<double> data,
    required Color color,
    required double maxY,
    required String suffix,
    required List<DateTime> timestamps,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withOpacity(0.06),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}$suffix',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white30),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (spots.length / 4).ceilToDouble().clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < timestamps.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('HH:mm').format(timestamps[idx]),
                        style: GoogleFonts.inter(fontSize: 9, color: Colors.white24),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
