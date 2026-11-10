import 'package:flutter/material.dart';
import 'package:puzzlebox/core/theme/neo.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'unified_stats_screen.dart';
import 'loading_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/notification_permission_sheet.dart';
import '../core/providers/settings_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _introKey = 'has_seen_intro_v1';

  /// Everything is loaded before the first frame, so the animated intro only
  /// plays on the very first launch; later launches open straight to Home.
  late bool _isLoading = !(ref.read(sharedPreferencesProvider).getBool(_introKey) ?? false);
  int index = 0;

  @override
  void initState() {
    super.initState();
    if (!_isLoading) _afterIntro();
  }

  void _afterIntro() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (WidgetsBinding.instance is! WidgetsFlutterBinding) return;
      NotificationPermissionSheet.showIfNeeded(context, ref);
    });
  }
  final pages = const [
    HomeScreen(),
    UnifiedStatsScreen(embedded: true),
    SettingsScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return LoadingScreen(
        onFinished: () {
          if (mounted) {
            ref.read(sharedPreferencesProvider).setBool(_introKey, true);
            setState(() => _isLoading = false);
            _afterIntro();
          }
        },
      );
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: KeyedSubtree(key: ValueKey<int>(index), child: pages[index]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            top: Neo.side(2.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.grid_view_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              selectedIcon: Icon(
                Icons.grid_view_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              label: 'Play',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.bar_chart_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              selectedIcon: Icon(
                Icons.bar_chart_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.tune_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              selectedIcon: Icon(
                Icons.tune_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              label: 'Settings',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.info_outline_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              selectedIcon: Icon(
                Icons.info_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              label: 'About',
            ),
          ],
        ),
      ),
    );
  }
}