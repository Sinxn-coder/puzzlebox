import 'dart:async';
import 'package:flutter/foundation.dart';

/// Hints are free but paced: a few per puzzle, then a short cooldown between
/// further hints, so they help without replacing the puzzle.
class HintBudget {
  static const freeHints = 3;
  /// Wait between hints once the free ones are used (adjustable for tests).
  static Duration cooldown = const Duration(seconds: 45);

  int _used = 0;
  DateTime? _last;
  Timer? _tick;

  /// Text for the badge on the hint button: hints left, a countdown, or null.
  final ValueNotifier<String?> badge = ValueNotifier<String?>('$freeHints');

  int get used => _used;

  /// Time until the next hint is allowed, or null when one is available now.
  Duration? get waitLeft {
    if (_used < freeHints || _last == null) return null;
    final left = cooldown - DateTime.now().difference(_last!);
    return left.isNegative || left == Duration.zero ? null : left;
  }

  void reset({int used = 0}) {
    _used = used;
    _last = used >= freeHints ? DateTime.now() : null;
    _refresh();
  }

  /// Spends a hint if one is available.
  bool tryUse() {
    if (waitLeft != null) return false;
    _used++;
    _last = DateTime.now();
    _refresh();
    return true;
  }

  static String format(Duration d) {
    final s = d.inSeconds + (d.inMilliseconds % 1000 > 0 ? 1 : 0);
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  void _refresh() {
    final wait = waitLeft;
    if (wait != null) {
      badge.value = format(wait);
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    } else {
      _tick?.cancel();
      _tick = null;
      badge.value = _used < freeHints ? '${freeHints - _used}' : null;
    }
  }

  void dispose() {
    _tick?.cancel();
    badge.dispose();
  }
}
