import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlebox/core/providers/settings_provider.dart';
import 'package:puzzlebox/core/services/engagement_service.dart';
import 'package:puzzlebox/core/widgets/streak_earned_dialog.dart';
import 'package:puzzlebox/screens/streak_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'EngagementService detects when a streak is newly earned on a given day',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = EngagementService(prefs);

      final day1 = DateTime(2026, 11, 1);
      final res1 = await service.recordCompletion(
        game: 'sudoku',
        difficulty: 'Medium',
        now: day1,
      );
      expect(res1.currentStreak, 1);
      expect(res1.streakEarnedToday, isTrue);

      // Second completion on the same day must NOT re-earn or re-celebrate the streak
      final res1Repeat = await service.recordCompletion(
        game: 'binary',
        difficulty: 'Easy',
        now: day1,
      );
      expect(res1Repeat.currentStreak, 1);
      expect(res1Repeat.streakEarnedToday, isFalse);

      // Next consecutive day advances the streak to 2 and earns today
      final day2 = DateTime(2026, 11, 2);
      final res2 = await service.recordCompletion(
        game: 'pips',
        difficulty: 'Hard',
        now: day2,
      );
      expect(res2.currentStreak, 2);
      expect(res2.streakEarnedToday, isTrue);
    },
  );

  testWidgets(
    'StreakEarnedScreen renders with correct streak text and Neo-Brutalist elements',
    (tester) async {
      SharedPreferences.setMockInitialValues({'settings_palette': 2});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: StreakEarnedScreen(streak: 5)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text(' DAY STREAK!'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Streak Kept Burning!'), findsOneWidget);
      expect(find.text('KEEP IT UP!'), findsOneWidget);
    },
  );

  testWidgets('StreakScreen renders hero card and 7 days week row', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'settings_palette': 0,
      'engagement_v1':
          '{"days":["2026-11-01"],"best":3,"total":10,"history":[]}',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: StreakScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1400));

    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text('day streak'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('BEST STREAK'), findsOneWidget);
    expect(find.text('TOTAL SOLVED'), findsOneWidget);
  });
}
