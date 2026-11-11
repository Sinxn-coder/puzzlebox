import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game_catalog.dart';
import 'engagement_service.dart';

/// One achievement with a progress bar.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int target;
  final int Function(AchievementData data) progress;

  const Achievement(
    this.id,
    this.title,
    this.description,
    this.icon,
    this.color,
    this.target,
    this.progress,
  );

  int current(AchievementData d) => progress(d).clamp(0, target);
  bool unlocked(AchievementData d) => progress(d) >= target;
}

/// Everything achievements are computed from.
class AchievementData {
  final EngagementSnapshot engagement;
  final int weeklyDone;
  AchievementData(this.engagement, this.weeklyDone);

  List<Map<String, dynamic>> get history => engagement.history;

  int wins({String? game, String? difficulty, String? category}) => history.where((h) {
    if (game != null && h['game'] != game) return false;
    if (difficulty != null && h['difficulty'] != difficulty) return false;
    if (category != null && GameCatalog.byId(h['game'] as String?)?.category != category) return false;
    return true;
  }).length;

  int get distinctGames => history.map((h) => h['game']).toSet().length;
  int get noHintWins => history.where((h) => h['hints'] == 0).length;

  bool fastWin(int seconds, {String? game, String? difficulty}) => history.any(
    (h) =>
        (h['seconds'] as int? ?? 0) > 0 &&
        (h['seconds'] as int) <= seconds &&
        (game == null || h['game'] == game) &&
        (difficulty == null || h['difficulty'] == difficulty),
  );

  int winsAtHours(int from, int to) => history.where((h) {
    final at = DateTime.tryParse(h['at'] as String? ?? '');
    return at != null && at.hour >= from && at.hour < to;
  }).length;
}

abstract final class Achievements {
  static const _seenKey = 'achievements_seen_v1';
  static const weeklyKey = 'weekly_done_v1';

  static final all = <Achievement>[
    Achievement('first_win', 'First Win', 'Solve your first puzzle', Icons.flag_rounded, const Color(0xFF4ADE80), 1, (d) => d.engagement.totalCompleted),
    Achievement('ten', 'Getting Going', 'Solve 10 puzzles', Icons.workspace_premium_rounded, const Color(0xFFFACC15), 10, (d) => d.engagement.totalCompleted),
    Achievement('fifty', 'Puzzle Pro', 'Solve 50 puzzles', Icons.military_tech_rounded, const Color(0xFFFB923C), 50, (d) => d.engagement.totalCompleted),
    Achievement('hundred', 'Centurion', 'Solve 100 puzzles', Icons.emoji_events_rounded, const Color(0xFFF43F5E), 100, (d) => d.engagement.totalCompleted),
    Achievement('five_hundred', 'Puzzle Legend', 'Solve 500 puzzles', Icons.diamond_rounded, const Color(0xFFC084FC), 500, (d) => d.engagement.totalCompleted),
    Achievement('streak3', 'Warming Up', 'Reach a 3-day streak', Icons.local_fire_department_rounded, const Color(0xFFFB923C), 3, (d) => d.engagement.bestStreak),
    Achievement('streak7', 'On Fire', 'Reach a 7-day streak', Icons.local_fire_department_rounded, const Color(0xFFF43F5E), 7, (d) => d.engagement.bestStreak),
    Achievement('streak30', 'Unstoppable', 'Reach a 30-day streak', Icons.whatshot_rounded, const Color(0xFFC084FC), 30, (d) => d.engagement.bestStreak),
    Achievement('streak100', 'Eternal Flame', 'Reach a 100-day streak', Icons.auto_awesome_rounded, const Color(0xFFFACC15), 100, (d) => d.engagement.bestStreak),
    Achievement('freeze', 'Saved by Ice', 'Have a streak freeze save your streak', Icons.ac_unit_rounded, const Color(0xFF38BDF8), 1, (d) => d.engagement.frozenDays.length),
    Achievement('hard1', 'Hard Earned', 'Win a Hard puzzle', Icons.psychology_rounded, const Color(0xFFC084FC), 1, (d) => d.wins(difficulty: 'Hard')),
    Achievement('hard25', 'Tough Cookie', 'Win 25 Hard puzzles', Icons.fitness_center_rounded, const Color(0xFFF43F5E), 25, (d) => d.wins(difficulty: 'Hard')),
    Achievement('nohint1', 'Look, No Hints', 'Win without using a hint', Icons.star_rounded, const Color(0xFFFACC15), 1, (d) => d.noHintWins),
    Achievement('nohint25', 'Pure Skill', 'Win 25 puzzles without hints', Icons.stars_rounded, const Color(0xFFFB923C), 25, (d) => d.noHintWins),
    Achievement('explorer', 'Explorer', 'Win in 5 different games', Icons.explore_rounded, const Color(0xFF38BDF8), 5, (d) => d.distinctGames),
    Achievement('collector', 'Completionist', 'Win in all 15 games', Icons.grid_view_rounded, const Color(0xFF4ADE80), GameCatalog.all.length, (d) => d.distinctGames),
    Achievement('words', 'Wordsmith', 'Win 25 word puzzles', Icons.spellcheck_rounded, const Color(0xFF4ADE80), 25, (d) => d.wins(category: 'Words')),
    Achievement('logic', 'Logician', 'Win 25 logic puzzles', Icons.psychology_alt_rounded, const Color(0xFFFACC15), 25, (d) => d.wins(category: 'Logic')),
    Achievement('patterns', 'Pattern Seeker', 'Win 25 pattern puzzles', Icons.auto_awesome_mosaic_rounded, const Color(0xFFC084FC), 25, (d) => d.wins(category: 'Patterns')),
    Achievement('chess10', 'Checkmate!', 'Win 10 chess puzzles or games', Icons.extension_rounded, const Color(0xFFFB923C), 10, (d) => d.wins(game: 'chess')),
    Achievement('speedy', 'Speed Demon', 'Solve any puzzle in under a minute', Icons.bolt_rounded, const Color(0xFFFACC15), 1, (d) => d.fastWin(60) ? 1 : 0),
    Achievement('sudoku_fast', 'Sudoku Sprinter', 'Solve a Hard Sudoku in under 10 minutes', Icons.timer_rounded, const Color(0xFF38BDF8), 1, (d) => d.fastWin(600, game: 'sudoku', difficulty: 'Hard') ? 1 : 0),
    Achievement('night', 'Night Owl', 'Win a puzzle between midnight and 4am', Icons.nightlight_round, const Color(0xFF6366F1), 1, (d) => d.winsAtHours(0, 4)),
    Achievement('weekly', 'Weekly Warrior', 'Complete 4 weekly challenges', Icons.event_available_rounded, const Color(0xFFF43F5E), 4, (d) => d.weeklyDone),
  ];

  static AchievementData dataFrom(SharedPreferences prefs, EngagementSnapshot engagement) =>
      AchievementData(engagement, (prefs.getStringList(weeklyKey) ?? const []).length);

  /// Achievements unlocked since the last check. The very first check after
  /// installing this version records what is already unlocked silently.
  static List<Achievement> newlyUnlocked(SharedPreferences prefs, EngagementSnapshot engagement) {
    final data = dataFrom(prefs, engagement);
    final unlocked = [for (final a in all) if (a.unlocked(data)) a];
    final seen = prefs.getStringList(_seenKey);
    prefs.setStringList(_seenKey, [for (final a in unlocked) a.id]);
    if (seen == null) return const [];
    return [for (final a in unlocked) if (!seen.contains(a.id)) a];
  }
}
