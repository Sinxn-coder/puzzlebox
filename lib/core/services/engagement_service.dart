import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';

final engagementServiceProvider = Provider(
  (ref) => EngagementService(ref.watch(sharedPreferencesProvider)),
);
final engagementRevisionProvider = StateProvider<int>((ref) => 0);

class EngagementSnapshot {
  final int currentStreak;
  final int bestStreak;
  final int totalCompleted;
  final List<String> playDays;
  final List<Map<String, dynamic>> history;
  final int storedPlaytimeSeconds;
  final bool streakEarnedToday;

  /// Streak freezes in hand (max [EngagementService.maxFreezes]).
  final int freezes;

  /// Missed days that a freeze covered (they keep the streak alive).
  final List<String> frozenDays;

  const EngagementSnapshot(
    this.currentStreak,
    this.bestStreak,
    this.totalCompleted,
    this.playDays,
    this.history, {
    this.storedPlaytimeSeconds = 0,
    this.streakEarnedToday = false,
    this.freezes = 0,
    this.frozenDays = const [],
  });

  int get totalSeconds {
    final historySeconds = history.fold(0, (sum, item) => sum + (item['seconds'] as int? ?? 0));
    return storedPlaytimeSeconds > historySeconds ? storedPlaytimeSeconds : historySeconds;
  }

  int completedFor(String game) =>
      history.where((item) => item['game'] == game).length;

  int? bestSecondsFor(String game) {
    final times = history
        .where(
          (item) => item['game'] == game && (item['seconds'] as int? ?? 0) > 0,
        )
        .map((item) => item['seconds'] as int)
        .toList();
    return times.isEmpty ? null : times.reduce((a, b) => a < b ? a : b);
  }

  int get hardWins =>
      history.where((item) => item['difficulty'] == 'Hard').length;
}

class EngagementService {
  final SharedPreferences prefs;
  EngagementService(this.prefs);
  static const _key = 'engagement_v1';

  /// One freeze is earned for every 7 days of streak, up to this many.
  static const maxFreezes = 2;

  EngagementSnapshot load({DateTime? now, bool streakEarnedToday = false}) {
    final todayStr = _day(now ?? DateTime.now());
    try {
      final data =
          jsonDecode(prefs.getString(_key) ?? '{}') as Map<String, dynamic>;
      final days = List<String>.from(
        data['days'] ?? const <String>[],
      ).toSet().toList()..sort();
      final frozen = List<String>.from(data['frozen'] ?? const <String>[]);
      // Frozen days count toward the streak but are not "played".
      final active = {...days, ...frozen};
      var streak = 0;
      final todayDt = _parseDay(todayStr);
      final yesterdayStr = _day(_prevDay(todayDt));

      if (active.contains(todayStr)) {
        var cursor = todayDt;
        while (active.contains(_day(cursor))) {
          streak++;
          cursor = _prevDay(cursor);
        }
      } else if (active.contains(yesterdayStr)) {
        var cursor = _prevDay(todayDt);
        while (active.contains(_day(cursor))) {
          streak++;
          cursor = _prevDay(cursor);
        }
      } else {
        streak = 0;
      }
      return EngagementSnapshot(
        streak,
        data['best'] as int? ?? 0,
        data['total'] as int? ?? 0,
        days,
        List<Map<String, dynamic>>.from(
          (data['history'] as List? ?? const []).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        ),
        storedPlaytimeSeconds: data['playtime_seconds'] as int? ?? 0,
        streakEarnedToday: streakEarnedToday,
        freezes: (data['freezes'] as int? ?? 0).clamp(0, maxFreezes),
        frozenDays: frozen,
      );
    } catch (_) {
      return const EngagementSnapshot(0, 0, 0, [], []);
    }
  }

  Future<void> addPlayTime(int seconds) async {
    if (seconds <= 0) return;
    try {
      final raw = prefs.getString(_key) ?? '{}';
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final currentSeconds = data['playtime_seconds'] as int? ?? 0;
      data['playtime_seconds'] = currentSeconds + seconds;
      await prefs.setString(_key, jsonEncode(data));
    } catch (_) {}
  }

  Future<EngagementSnapshot> recordCompletion({
    required String game,
    required String difficulty,
    int seconds = 0,
    int? hints,
    DateTime? now,
  }) async {
    final current = load(now: now);
    final today = _day(now ?? DateTime.now());
    final isNewDay = !current.playDays.contains(today);
    final days = {...current.playDays, today}.toList()..sort();
    final history = [
      ...current.history,
      {
        'game': game,
        'difficulty': difficulty,
        'seconds': seconds,
        'hints': ?hints,
        'at': (now ?? DateTime.now()).toIso8601String(),
      },
    ];
    final currentStreak = _streakFor({...days, ...current.frozenDays}.toList(), today);
    var freezes = current.freezes;
    if (isNewDay && currentStreak > 0 && currentStreak % 7 == 0) {
      freezes = (freezes + 1).clamp(0, maxFreezes);
    }
    final newBest = current.bestStreak > currentStreak
        ? current.bestStreak
        : currentStreak;
    // Play time is already accumulated live via addPlayTime; [seconds] is
    // the solve time for this puzzle and must not be counted twice.
    final newPlaytime = current.storedPlaytimeSeconds;

    await prefs.setString(
      _key,
      jsonEncode({
        'days': days.takeLast(400),
        'best': newBest,
        'total': current.totalCompleted + 1,
        'history': history.takeLast(200),
        'playtime_seconds': newPlaytime,
        'freezes': freezes,
        'frozen': current.frozenDays.takeLast(60),
      }),
    );
    final streakEarned = isNewDay && currentStreak > 0;
    return load(now: now, streakEarnedToday: streakEarned);
  }

  /// Uses streak freezes to cover days missed since the last play, if there
  /// are enough of them. Call on app start. Returns how many were used.
  Future<int> applyFreezes({DateTime? now}) async {
    try {
      final snap = load(now: now);
      if (snap.freezes == 0) return 0;
      final raw = jsonDecode(prefs.getString(_key) ?? '{}') as Map<String, dynamic>;
      final active = {...snap.playDays, ...snap.frozenDays};
      final today = _parseDay(_day(now ?? DateTime.now()));
      if (active.contains(_day(today))) return 0;
      final missed = <String>[];
      var cursor = _prevDay(today);
      while (!active.contains(_day(cursor)) && missed.length <= snap.freezes) {
        missed.add(_day(cursor));
        cursor = _prevDay(cursor);
      }
      // Only bridge a gap back to a real streak, and only if freezes cover it.
      if (missed.isEmpty || missed.length > snap.freezes || !active.contains(_day(cursor))) {
        return 0;
      }
      raw['frozen'] = [...snap.frozenDays, ...missed].takeLast(60);
      raw['freezes'] = snap.freezes - missed.length;
      await prefs.setString(_key, jsonEncode(raw));
      return missed.length;
    } catch (_) {
      return 0;
    }
  }

  static String _day(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static DateTime _parseDay(String dayStr) {
    final parts = dayStr.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  static DateTime _prevDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day - 1);
  }

  static int _streakFor(List<String> days, String todayStr) {
    var streak = 0;
    var cursor = _parseDay(todayStr);
    while (days.contains(_day(cursor))) {
      streak++;
      cursor = _prevDay(cursor);
    }
    return streak;
  }
}

extension<T> on List<T> {
  List<T> takeLast(int count) =>
      skip(length > count ? length - count : 0).toList();
}

