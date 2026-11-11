import 'package:shared_preferences/shared_preferences.dart';
import 'achievements.dart';
import 'date_service.dart';

/// A request to open a game on a specific puzzle (archive day or weekly
/// challenge), picked up by the game when it starts.
class PuzzleLaunch {
  final String gameId;

  /// 'yyyy-mm-dd' for an archive day, or null for the weekly challenge.
  final String? day;
  const PuzzleLaunch.archive(this.gameId, String this.day);
  const PuzzleLaunch.weekly(this.gameId) : day = null;

  bool get isWeekly => day == null;

  static PuzzleLaunch? pending;

  /// Returns and clears the pending launch if it is for [gameId].
  static PuzzleLaunch? take(String gameId) {
    final p = pending;
    if (p == null || p.gameId != gameId) return null;
    pending = null;
    return p;
  }
}

abstract final class SpecialPuzzles {
  static final _weekEpoch = DateTime(2025, 1, 6); // a Monday
  static const archiveDays = 60;

  /// Games with a daily mode that the archive and weekly challenge support.
  static const games = [
    'sudoku', 'connections', 'spelling_bee', 'strands', 'mini_crossword',
    'crossword', 'letter_boxed', 'cages', 'binary', 'nonogram', 'vertex',
    'pips', 'tiles',
  ];

  /// Rotation for the weekly challenge (always played on Hard).
  static const weeklyRotation = [
    'sudoku', 'connections', 'cages', 'strands', 'nonogram',
    'spelling_bee', 'binary', 'crossword', 'letter_boxed', 'vertex',
  ];

  static int weekIndex([DateTime? now]) {
    final d = now ?? DateTime.now();
    final today = DateTime(d.year, d.month, d.day);
    return today.difference(_weekEpoch).inDays ~/ 7;
  }

  static String weekKey([DateTime? now]) => 'week-${weekIndex(now)}';

  static String weeklyGame([DateTime? now]) =>
      weeklyRotation[weekIndex(now) % weeklyRotation.length];

  /// Days until this week's challenge rotates (1-7).
  static int daysLeftInWeek([DateTime? now]) {
    final d = now ?? DateTime.now();
    return 7 - (DateTime(d.year, d.month, d.day).difference(_weekEpoch).inDays % 7);
  }

  static bool weeklyDone(SharedPreferences prefs, [DateTime? now]) =>
      (prefs.getStringList(Achievements.weeklyKey) ?? const []).contains(weekKey(now));

  static Future<void> markWeeklyDone(SharedPreferences prefs) async {
    final list = prefs.getStringList(Achievements.weeklyKey) ?? <String>[];
    if (!list.contains(weekKey())) {
      await prefs.setStringList(Achievements.weeklyKey, [...list, weekKey()]);
    }
  }

  static String _archiveKey(String gameId) => 'archive_done_v1_$gameId';

  static Set<String> archiveDone(SharedPreferences prefs, String gameId) =>
      (prefs.getStringList(_archiveKey(gameId)) ?? const <String>[]).toSet();

  static Future<void> markArchiveDone(SharedPreferences prefs, String gameId, String day) async {
    final set = archiveDone(prefs, gameId)..add(day);
    final kept = set.toList()..sort();
    await prefs.setStringList(
      _archiveKey(gameId),
      kept.length > 400 ? kept.sublist(kept.length - 400) : kept,
    );
  }

  /// Puzzle number for a daily key: archive days count from the puzzle
  /// epoch; weekly keys sit far away so they never collide with days.
  static int puzzleNumberFor(String dayKey) {
    if (dayKey.startsWith('week-')) return 100000 + int.parse(dayKey.substring(5));
    final d = DateTime.tryParse(dayKey);
    if (d == null) return DateService.puzzleNumber();
    return DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2025)).inDays;
  }
}
