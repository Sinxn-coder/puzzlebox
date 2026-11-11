import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzlebox/core/services/achievements.dart';
import 'package:puzzlebox/core/services/engagement_service.dart';
import 'package:puzzlebox/core/services/special_puzzles.dart';

Future<EngagementService> _service() async {
  SharedPreferences.setMockInitialValues({});
  return EngagementService(await SharedPreferences.getInstance());
}

Future<void> _playDays(EngagementService s, DateTime start, int days) async {
  for (var i = 0; i < days; i++) {
    await s.recordCompletion(
      game: 'sudoku',
      difficulty: 'Medium',
      seconds: 100,
      hints: 0,
      now: DateTime(start.year, start.month, start.day + i, 12),
    );
  }
}

void main() {
  test('a 7-day streak earns a freeze that bridges one missed day', () async {
    final s = await _service();
    await _playDays(s, DateTime(2026, 3, 1), 7); // Mar 1-7
    expect(s.load(now: DateTime(2026, 3, 7)).freezes, 1);

    // Miss Mar 8, open the app on Mar 9.
    final used = await s.applyFreezes(now: DateTime(2026, 3, 9, 9));
    expect(used, 1);
    final snap = s.load(now: DateTime(2026, 3, 9));
    expect(snap.freezes, 0);
    expect(snap.currentStreak, 8); // Mar 1-8 kept alive
    expect(snap.playDays.contains('2026-03-08'), isFalse);

    // Playing Mar 9 continues the same streak.
    await _playDays(s, DateTime(2026, 3, 9), 1);
    expect(s.load(now: DateTime(2026, 3, 9)).currentStreak, 9);
  });

  test('freezes cap at two and never cover a gap they cannot fill', () async {
    final s = await _service();
    await _playDays(s, DateTime(2026, 4, 1), 21);
    expect(s.load(now: DateTime(2026, 4, 21)).freezes, EngagementService.maxFreezes);
    // A three-day gap is too long for two freezes: streak resets.
    expect(await s.applyFreezes(now: DateTime(2026, 4, 25, 9)), 0);
    expect(s.load(now: DateTime(2026, 4, 25)).currentStreak, 0);
  });

  test('no freeze is used when the player already played today', () async {
    final s = await _service();
    await _playDays(s, DateTime(2026, 5, 1), 7);
    expect(await s.applyFreezes(now: DateTime(2026, 5, 7, 20)), 0);
    expect(s.load(now: DateTime(2026, 5, 7)).freezes, 1);
  });

  test('achievements: first check is silent, later unlocks are announced', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = EngagementService(prefs);
    await _playDays(s, DateTime(2026, 6, 1), 1);
    // Existing progress at upgrade time is recorded without toasts.
    expect(Achievements.newlyUnlocked(prefs, s.load(now: DateTime(2026, 6, 1))), isEmpty);
    await _playDays(s, DateTime(2026, 6, 2), 2);
    final fresh = Achievements.newlyUnlocked(prefs, s.load(now: DateTime(2026, 6, 3)));
    expect(fresh.map((a) => a.id), contains('streak3'));
    // Not announced twice.
    expect(Achievements.newlyUnlocked(prefs, s.load(now: DateTime(2026, 6, 3))), isEmpty);
    final data = Achievements.dataFrom(prefs, s.load(now: DateTime(2026, 6, 3)));
    expect(Achievements.all.firstWhere((a) => a.id == 'nohint1').unlocked(data), isTrue);
    expect(Achievements.all.map((a) => a.id).toSet().length, Achievements.all.length);
  });

  test('weekly challenge rotates weekly and archive keys never clash with days', () {
    final monday = DateTime(2026, 11, 9);
    expect(SpecialPuzzles.weekKey(monday), SpecialPuzzles.weekKey(DateTime(2026, 11, 15)));
    expect(SpecialPuzzles.weekKey(monday), isNot(SpecialPuzzles.weekKey(DateTime(2026, 11, 16))));
    expect(SpecialPuzzles.daysLeftInWeek(monday), 7);
    expect(SpecialPuzzles.puzzleNumberFor('2025-01-02'), 1);
    expect(SpecialPuzzles.puzzleNumberFor(SpecialPuzzles.weekKey(monday)), greaterThan(90000));
    for (final id in SpecialPuzzles.weeklyRotation) {
      expect(SpecialPuzzles.games, contains(id));
    }
  });
}
