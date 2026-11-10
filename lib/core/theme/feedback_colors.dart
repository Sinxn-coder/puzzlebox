import 'package:flutter/material.dart';

/// Right-spot / wrong-spot feedback colours, with a colour-vision-friendly
/// alternative (orange/blue instead of green/yellow).
abstract final class FeedbackColors {
  static bool colorblind = false;

  static Color get correct =>
      colorblind ? const Color(0xFFFB923C) : const Color(0xFF4ADE80);

  static Color get present =>
      colorblind ? const Color(0xFF38BDF8) : const Color(0xFFFACC15);

  /// Small glyph that repeats the colour's meaning, shown in colorblind mode.
  static IconData? cueFor({required bool correct, required bool present}) {
    if (!colorblind) return null;
    if (correct) return Icons.check_rounded;
    if (present) return Icons.swap_horiz_rounded;
    return null;
  }
}
