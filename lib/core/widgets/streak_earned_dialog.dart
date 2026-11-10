import 'dart:async';
import 'package:puzzlebox/core/theme/neo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../providers/settings_provider.dart';
import '../services/app_feedback_service.dart';
import '../theme/app_theme.dart';
import 'pressable_scale.dart';

/// Full celebration screen shown when a player earns or extends a daily streak.
/// Uses native [Lottie.asset] for 100% crisp, zero-latency vector animation
/// with transparent background, dynamic palette synchronization, celebratory
/// victory haptics, and a fast rolling vertical number counter animation.
class StreakEarnedScreen extends ConsumerStatefulWidget {
  final int streak;

  const StreakEarnedScreen({super.key, required this.streak});

  /// Map user-selected palette to the corresponding pre-compiled Lottie asset
  static String getLottieAsset(int palette) {
    switch (palette) {
      case 2: // Lime Green
        return 'assets/streak_green.json';
      case 3: // Rose Pink
        return 'assets/streak_pink.json';
      case 4: // Electric Cyan
        return 'assets/streak_cyan.json';
      case 5: // Neon Violet
        return 'assets/streak_violet.json';
      case 6: // Neon Orange
        return 'assets/streak_orange.json';
      case 7: // Minimal Slate
        return 'assets/streak_slate.json';
      case 0: // Mixed Multi-Color -> Sunflower Yellow
      case 1: // Sunflower Yellow
      default:
        return 'assets/streak_yellow.json';
    }
  }

  static Future<void> show(BuildContext context, {required int streak}) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (ctx, anim, secondaryAnim) =>
            StreakEarnedScreen(streak: streak),
        transitionsBuilder: (ctx, anim, secondaryAnim, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: curved, child: child),
          );
        },
      ),
    );
  }

  @override
  ConsumerState<StreakEarnedScreen> createState() => _StreakEarnedScreenState();
}

class _StreakEarnedScreenState extends ConsumerState<StreakEarnedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _badgeScale;
  int _displayedCount = 0;
  Timer? _countTimer;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _badgeScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    );

    _entranceController.forward();

    // Trigger victory fanfare vibration pattern and fast counting animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _triggerVictoryHaptics();
      _startCounterRoll();
    });
  }

  /// Celebratory victory vibration sequence:
  /// Hearty triple pulse rhythm matching the celebratory triumph feeling.
  Future<void> _triggerVictoryHaptics() async {
    final hapticsOn = ref.read(settingsProvider).hapticsEnabled;
    if (!hapticsOn) return;

    // Victory opening pulse
    await AppFeedbackService.victory(ref);
  }

  /// Fast rolling counter that counts from 0 up to widget.streak.
  /// Each number roll gives a light/medium haptic tick, ending with a solid celebration impact.
  void _startCounterRoll() {
    final target = widget.streak;
    if (target <= 0) {
      _displayedCount = 0;
      return;
    }

    // Delay roll slightly until badge starts scaling in
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;

      int current = 0;
      // Calculate interval so total roll finishes in ~350-450ms for a rapid, satisfying roll
      final stepDelayMs = (400 / target).clamp(30, 90).toInt();

      _countTimer?.cancel();
      _countTimer = Timer.periodic(Duration(milliseconds: stepDelayMs), (
        timer,
      ) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        current++;
        setState(() {
          _displayedCount = current;
        });

        // Haptic pulse on each roll step
        final hapticsOn = ref.read(settingsProvider).hapticsEnabled;
        if (hapticsOn) {
          if (current >= target) {
            HapticFeedback.heavyImpact();
          } else {
            HapticFeedback.selectionClick();
          }
        }

        if (current >= target) {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final accent = AppTheme.getAccentColor(
      const Color(0xFFFACC15),
      settings.palette,
    );
    final lottieAsset = StreakEarnedScreen.getLottieAsset(settings.palette);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Top App Bar with Close / Back Button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Neo.border(2.5),
                      boxShadow: Neo.shadow(3),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: textColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // Main Centered Celebration Content
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Native Lottie Vector Animation
                      // Scaled up for prominent, vibrant presentation with responsive sizing
                      // Colors 100% matched to user's selected app palette
                      Transform.scale(
                        scale: 1.75,
                        child: SizedBox(
                          width: 280,
                          height: 280,
                          child: Lottie.asset(
                            lottieAsset,
                            key: ValueKey(lottieAsset),
                            width: 280,
                            height: 280,
                            fit: BoxFit.contain,
                            repeat: true,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.local_fire_department_rounded,
                                size: 180,
                                color: accent,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Streak Count Pill with Animated Rolling Number Counter
                      ScaleTransition(
                        scale: _badgeScale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(30),
                            border: Neo.border(3),
                            boxShadow: Neo.shadow(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: Colors.black,
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                              // Fast vertical roll transition for the number
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 140),
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      final inAnimation =
                                          Tween<Offset>(
                                            begin: const Offset(0.0, 0.8),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutBack,
                                            ),
                                          );
                                      return SlideTransition(
                                        position: inAnimation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                child: Text(
                                  '$_displayedCount',
                                  key: ValueKey<int>(_displayedCount),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const Text(
                                ' DAY STREAK!',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Streak Kept Burning!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Neo.border(2.5),
                          boxShadow: Neo.shadow(4),
                        ),
                        child: Text(
                          widget.streak == 1
                              ? 'Awesome start! You ignited your daily brain-training streak today. Come back tomorrow to keep the flame alive!'
                              : 'Incredible dedication! You have solved puzzles ${widget.streak} days in a row without breaking the chain.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF334155),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Action Button
                      PressableScale(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(18),
                            border: Neo.border(3),
                            boxShadow: Neo.shadow(4),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () => Navigator.of(context).pop(),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'KEEP IT UP!',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Backward compatibility alias so existing calls to StreakEarnedDialog.show(...)
/// seamlessly navigate to the new full-screen StreakEarnedScreen.
class StreakEarnedDialog {
  static Future<void> show(BuildContext context, {required int streak}) {
    return StreakEarnedScreen.show(context, streak: streak);
  }
}
