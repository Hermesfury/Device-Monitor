import 'package:dev_monitor/presentation/dashboard_screen.dart';
import 'package:dev_monitor/presentation/history_screen.dart';
import 'package:dev_monitor/presentation/permission_screen.dart';
import 'package:dev_monitor/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dev_monitor/core/database_service.dart';
import 'package:dev_monitor/data/monitor_repository.dart';
import 'package:dev_monitor/platform/channels/monitor_channel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  try {
    await container.read(databaseProvider).init();
  } catch (e) {
    debugPrint('Failed to initialize database: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00D4AA),
          surface: Color(0xFF131929),
          error: Color(0xFFFF6B6B),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _permissionsHandled = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      // Check notification permission
      final notificationGranted = await Permission.notification.status;

      // For usage stats, we can't directly check it from Flutter
      // We'll try to get app usage data and see if it's empty
      final container = ProviderContainer();
      await container.read(databaseProvider).init();
      final repo = MonitorRepository(MonitorChannel(), container.read(databaseProvider).db);

      // Try to get app usage - if it returns empty, permissions aren't granted
      final appUsage = await repo.getAppUsage();
      final hasUsageData = appUsage.isNotEmpty;

      // If we have usage data and notification permission, skip permission screen
      if (hasUsageData && notificationGranted.isGranted) {
        setState(() => _permissionsHandled = true);
      }
    } catch (e) {
      // If there's an error, show permission screen
      print('Error checking permissions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsHandled) {
      return PermissionScreen(
        onPermissionsGranted: () {
          setState(() => _permissionsHandled = true);
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: IndexedStack(
        index: _selectedTab,
        children: const [
          DashboardScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1420),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.show_chart_rounded,
                label: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == index;
    final color = isSelected ? const Color(0xFF6C63FF) : Colors.white30;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
