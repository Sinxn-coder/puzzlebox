import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'date_service.dart';

/// A puzzle the player started but has not finished.
class ResumeInfo {
  final String gameId;
  final String mode;
  final String difficulty;
  final DateTime savedAt;
  final int elapsedSeconds;

  const ResumeInfo({
    required this.gameId,
    required this.mode,
    required this.difficulty,
    required this.savedAt,
    required this.elapsedSeconds,
  });

  bool get isDaily => mode == 'daily';
}

/// Remembers which in-progress puzzle each game should reopen, so Home can
/// offer "Continue" and the game can restore the right mode and difficulty.
abstract final class SessionResume {
  static String key(String gameId) => 'resume_v1_$gameId';

  static ResumeInfo? read(SharedPreferences prefs, String gameId) {
    try {
      final raw = prefs.getString(key(gameId));
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final mode = data['mode'] as String? ?? 'practice';
      // Yesterday's daily puzzle is gone; only today's can be continued.
      if (mode == 'daily' && data['day'] != DateService.todayKey()) {
        return null;
      }
      return ResumeInfo(
        gameId: gameId,
        mode: mode,
        difficulty: data['difficulty'] as String? ?? 'Medium',
        savedAt:
            DateTime.tryParse(data['savedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        elapsedSeconds: data['elapsed'] as int? ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(
    SharedPreferences prefs, {
    required String gameId,
    required String mode,
    required String difficulty,
    required int elapsedSeconds,
  }) => prefs.setString(
    key(gameId),
    jsonEncode({
      'mode': mode,
      'difficulty': difficulty,
      'day': DateService.todayKey(),
      'savedAt': DateTime.now().toIso8601String(),
      'elapsed': elapsedSeconds,
    }),
  );

  static Future<void> clear(SharedPreferences prefs, String gameId) =>
      prefs.remove(key(gameId));

  /// Every resumable game, most recently played first.
  static List<ResumeInfo> all(SharedPreferences prefs, Iterable<String> ids) {
    final list = [
      for (final id in ids)
        ?read(prefs, id),
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }
}
