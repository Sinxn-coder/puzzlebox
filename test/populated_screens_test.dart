import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzlebox/core/providers/settings_provider.dart';
import 'package:puzzlebox/core/services/date_service.dart';
import 'package:puzzlebox/core/services/session_resume.dart';
import 'package:puzzlebox/core/theme/app_theme.dart';
import 'package:puzzlebox/core/theme/neo.dart';
import 'package:puzzlebox/games/daily_five/logic/word_list.dart';
import 'package:puzzlebox/screens/game_stats_screen.dart';
import 'package:puzzlebox/screens/home_screen.dart';
import 'package:puzzlebox/screens/streak_screen.dart';
import 'package:puzzlebox/screens/unified_stats_screen.dart';

/// A returning player's data: win history, streak, unfinished puzzles and
/// guess stats. Screens must lay out cleanly with real content, not only on
/// a fresh install.
Map<String, Object> _returningPlayer() {
  final now = DateTime.now();
  final days = [
    for (var i = 0; i < 9; i++)
      DateService.dateKey(now.subtract(Duration(days: i))),
  ];
  return {
    'engagement_v1': jsonEncode({
      'days': days,
      'best': 12,
      'total': 40,
      'playtime_seconds': 98765,
      'history': [
        for (var i = 0; i < 30; i++)
          {
            'game': ['sudoku', 'daily_five', 'chess', 'binary'][i % 4],
            'difficulty': ['Easy', 'Medium', 'Hard'][i % 3],
            'seconds': 40 + i * 37,
            'at': now.subtract(Duration(hours: i * 5)).toIso8601String(),
          },
      ],
    }),
    'daily_five_stats': jsonEncode({
      'gamesPlayed': 20,
      'gamesWon': 18,
      'currentStreak': 5,
      'maxStreak': 9,
      'distribution': {'1': 1, '2': 3, '3': 7, '4': 4, '5': 2, '6': 1},
    }),
    for (final id in ['sudoku', 'nonogram', 'daily_five', 'chess'])
      SessionResume.key(id): jsonEncode({
        'mode': 'practice',
        'difficulty': 'Hard',
        'day': DateService.todayKey(),
        'savedAt': now.toIso8601String(),
        'elapsed': 3725,
      }),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues(_returningPlayer());
    await WordList.init();
  });
  tearDown(() => Neo.style = NeoStyle.bold);

  final screens = <String, Widget>{
    'home': const Scaffold(body: HomeScreen()),
    'stats': const Scaffold(body: UnifiedStatsScreen()),
    'sudoku_stats': const GameStatsScreen(gameId: 'sudoku'),
    'daily_five_stats': const GameStatsScreen(gameId: 'daily_five'),
    'empty_game_stats': const GameStatsScreen(gameId: 'vertex'),
    'streak': const StreakScreen(),
  };
  final configs = [
    (const Size(320, 568), 1.3, Brightness.light, NeoStyle.bold),
    (const Size(360, 640), 1.0, Brightness.dark, NeoStyle.soft),
    (const Size(390, 844), 1.5, Brightness.dark, NeoStyle.bold),
  ];

  for (final (size, scale, brightness, style) in configs) {
    for (final entry in screens.entries) {
      testWidgets(
        '${entry.key} with data at ${size.width.toInt()}w x$scale ${brightness.name} ${style.name}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final prefs = await SharedPreferences.getInstance();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
              child: MaterialApp(
                theme: AppTheme.build(brightness, 0, style: style),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: child!,
                ),
                home: entry.value,
              ),
            ),
          );
          for (var i = 0; i < 12; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(tester.takeException(), isNull);
          // On short screens the row is below the fold and not built yet.
          if (entry.key == 'home') {
            await tester.scrollUntilVisible(
              find.text('CONTINUE PLAYING'),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.text('CONTINUE PLAYING'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
}
