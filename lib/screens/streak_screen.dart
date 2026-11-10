import '../core/game_catalog.dart';
import '../core/routing/game_router.dart';
import 'dart:async';
import 'package:puzzlebox/core/theme/neo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../core/providers/settings_provider.dart';
import '../core/services/engagement_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/pressable_scale.dart';
import '../core/widgets/streak_earned_dialog.dart';

class StreakScreen extends ConsumerStatefulWidget {
  /// True when shown as a bottom-navigation tab (no back arrow).
  final bool embedded;
  const StreakScreen({super.key, this.embedded = false});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const StreakScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.08);
          const end = Offset.zero;
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: begin, end: end).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen>
    with TickerProviderStateMixin {
  late DateTime _selectedMonth;
  late AnimationController _gradientController;
  late AnimationController _lottieController;

  late AnimationController _card1Controller;
  late AnimationController _card2Controller;
  late AnimationController _card3Controller;
  late AnimationController _card4Controller;
  late AnimationController _card5Controller;
  late AnimationController _flameDropController;

  late Animation<Offset> _card1Slide;
  late Animation<double> _card1Fade;
  late Animation<Offset> _card2Slide;
  late Animation<double> _card2Fade;
  late Animation<Offset> _card3Slide;
  late Animation<double> _card3Fade;
  late Animation<Offset> _card4Slide;
  late Animation<double> _card4Fade;
  late Animation<Offset> _card5Slide;
  late Animation<double> _card5Fade;
  late Animation<Offset> _flameDropSlide;
  late Animation<double> _flameDropFade;

  final List<Timer> _entranceTimers = [];

  static const _rainbowPalettes = [
    (Color(0xFFFB923C), 6), // Neon Orange
    (Color(0xFFFACC15), 1), // Sunflower Yellow
    (Color(0xFF4ADE80), 2), // Lime Green
    (Color(0xFF38BDF8), 4), // Electric Cyan
    (Color(0xFFC084FC), 5), // Neon Violet
    (Color(0xFFF43F5E), 3), // Rose Pink
    (Color(0xFFFB923C), 6), // Wrap back to Neon Orange
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _initStaggeredEntrance();
  }

  void _initStaggeredEntrance() {
    const cardDuration = Duration(milliseconds: 480);
    const curve = Curves.easeOutBack;

    _card1Controller = AnimationController(vsync: this, duration: cardDuration);
    _card2Controller = AnimationController(vsync: this, duration: cardDuration);
    _card3Controller = AnimationController(vsync: this, duration: cardDuration);
    _card4Controller = AnimationController(vsync: this, duration: cardDuration);
    _card5Controller = AnimationController(vsync: this, duration: cardDuration);
    _flameDropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    Animation<Offset> makeSlide(AnimationController c) => Tween<Offset>(
      begin: const Offset(0.0, 0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: c, curve: curve));

    Animation<double> makeFade(AnimationController c) => Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));

    _card1Slide = makeSlide(_card1Controller);
    _card1Fade = makeFade(_card1Controller);
    _card2Slide = makeSlide(_card2Controller);
    _card2Fade = makeFade(_card2Controller);
    _card3Slide = makeSlide(_card3Controller);
    _card3Fade = makeFade(_card3Controller);
    _card4Slide = makeSlide(_card4Controller);
    _card4Fade = makeFade(_card4Controller);
    _card5Slide = makeSlide(_card5Controller);
    _card5Fade = makeFade(_card5Controller);

    // Flame drops from above down into position with bounce
    _flameDropSlide =
        Tween<Offset>(begin: const Offset(0.0, -1.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _flameDropController,
            curve: Curves.bounceOut,
          ),
        );

    _flameDropFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flameDropController, curve: Curves.easeIn),
    );

    // Stagger sequence with thud vibration on arrival
    void triggerImpact() {
      if (!mounted) return;
      final haptics = ref.read(settingsProvider).hapticsEnabled;
      if (haptics) {
        HapticFeedback.heavyImpact();
      }
    }

    _entranceTimers.addAll([
      Timer(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        _card1Controller.forward().then((_) => triggerImpact());
      }),
      Timer(const Duration(milliseconds: 260), () {
        if (!mounted) return;
        _card2Controller.forward().then((_) => triggerImpact());
      }),
      Timer(const Duration(milliseconds: 440), () {
        if (!mounted) return;
        _card3Controller.forward().then((_) => triggerImpact());
      }),
      Timer(const Duration(milliseconds: 620), () {
        if (!mounted) return;
        _card4Controller.forward().then((_) => triggerImpact());
      }),
      Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _card5Controller.forward().then((_) {
          triggerImpact();
          // After all 5 cards have finished coming into place, drop the flame down from top
          _flameDropController.forward().then((_) => triggerImpact());
        });
      }),
    ]);
  }

  @override
  void dispose() {
    for (final timer in _entranceTimers) {
      timer.cancel();
    }
    _gradientController.dispose();
    _lottieController.dispose();
    _card1Controller.dispose();
    _card2Controller.dispose();
    _card3Controller.dispose();
    _card4Controller.dispose();
    _card5Controller.dispose();
    _flameDropController.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(engagementRevisionProvider);
    final engagement = ref.read(engagementServiceProvider).load();
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isMixed = settings.palette == 0;
    final primaryAccent = AppTheme.getAccentColor(
      const Color(0xFFFB923C),
      settings.palette,
    );
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Sunday of current week (weekday in Flutter: 1 = Mon ... 7 = Sun)
    final daysSinceSunday = now.weekday % 7;
    final startOfWeek = today.subtract(Duration(days: daysSinceSunday));

    final weekDays = List.generate(7, (i) {
      final date = startOfWeek.add(Duration(days: i));
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final isCompleted = engagement.playDays.contains(dateStr);
      final isToday =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final isFuture = date.isAfter(today);

      const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      return (
        label: labels[i],
        dayNum: date.day,
        isCompleted: isCompleted,
        isToday: isToday,
        isFuture: isFuture,
      );
    });

    final lottieAsset = StreakEarnedScreen.getLottieAsset(settings.palette);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (widget.embedded)
                    const SizedBox(width: 44, height: 44)
                  else
                  PressableScale(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
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
                          Icons.arrow_back_rounded,
                          color: textColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'STREAK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User's Hero Streak Card (Animated Entrance #1)
                      FadeTransition(
                        opacity: _card1Fade,
                        child: SlideTransition(
                          position: _card1Slide,
                          child: AnimatedBuilder(
                            animation: _gradientController,
                            builder: (context, child) {
                              Gradient gradient;
                              String asset1;
                              String asset2;
                              double crossFadeT = 0.0;

                              if (isMixed) {
                                final t = _gradientController.value;
                                final n = _rainbowPalettes.length - 1;
                                final pos = t * n;
                                final idx1 = pos.floor();
                                final idx2 =
                                    (idx1 + 1) % _rainbowPalettes.length;
                                final subT = pos - idx1;
                                final c1 = Color.lerp(
                                  _rainbowPalettes[idx1].$1,
                                  _rainbowPalettes[idx2].$1,
                                  subT,
                                )!;
                                final c2 = HSLColor.fromColor(c1)
                                    .withLightness(
                                      (HSLColor.fromColor(c1).lightness - 0.22)
                                          .clamp(0.12, 0.9),
                                    )
                                    .toColor();

                                gradient = LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [c1, c2],
                                );

                                asset1 = StreakEarnedScreen.getLottieAsset(
                                  _rainbowPalettes[idx1].$2,
                                );
                                asset2 = StreakEarnedScreen.getLottieAsset(
                                  _rainbowPalettes[idx2].$2,
                                );
                                crossFadeT = subT;
                              } else {
                                gradient = LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryAccent,
                                    HSLColor.fromColor(primaryAccent)
                                        .withLightness(
                                          (HSLColor.fromColor(
                                                    primaryAccent,
                                                  ).lightness -
                                                  0.22)
                                              .clamp(0.12, 0.9),
                                        )
                                        .toColor(),
                                  ],
                                );
                                asset1 = lottieAsset;
                                asset2 = lottieAsset;
                                crossFadeT = 0.0;
                              }

                              return Container(
                                height: 220,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  gradient: gradient,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Neo.border(3),
                                  boxShadow: Neo.shadow(5),
                                ),
                                child: Stack(
                                  children: [
                                    // Synchronized flame dropping from top after all cards arrive
                                    Positioned(
                                      right: -25,
                                      bottom: -45,
                                      width: 240,
                                      height: 240,
                                      child: FadeTransition(
                                        opacity: _flameDropFade,
                                        child: SlideTransition(
                                          position: _flameDropSlide,
                                          child: Stack(
                                            children: [
                                              Opacity(
                                                opacity:
                                                    (1.0 - crossFadeT) * 0.95,
                                                child: Lottie.asset(
                                                  asset1,
                                                  controller: _lottieController,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              if (isMixed && asset1 != asset2)
                                                Opacity(
                                                  opacity: crossFadeT * 0.95,
                                                  child: Lottie.asset(
                                                    asset2,
                                                    controller:
                                                        _lottieController,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 26,
                                        vertical: 26,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${engagement.currentStreak}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 68,
                                              fontWeight: FontWeight.w900,
                                              height: 1.0,
                                              letterSpacing: -1.5,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black45,
                                                  offset: Offset(2, 2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'day streak',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.95,
                                              ),
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.2,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black38,
                                                  offset: Offset(1, 1),
                                                  blurRadius: 3,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Current Week 7 Days Card (Animated Entrance #2)
                      FadeTransition(
                        opacity: _card2Fade,
                        child: SlideTransition(
                          position: _card2Slide,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Neo.border(2.5),
                              boxShadow: Neo.shadow(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                      'THIS WEEK',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryAccent.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Neo.border(1.5),
                                      ),
                                      child: Text(
                                        'Sun – Sat',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: SizedBox(
                                  width: 7 * 46,
                                  child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(weekDays.length, (i) {
                                    final day = weekDays[i];
                                    // All 7 rounds slide in first:
                                    // Round 0 slides at 720ms, Round 6 slides at 720 + 6*60 = 1080ms.
                                    // Slide animation takes ~300ms, so round 6 arrives at ~1380ms.
                                    // Flash sequence begins sequentially on round 0 at 1450ms, round 1 at 1450 + 1*120ms, etc.
                                    return _WeekDayItem(
                                      label: day.label,
                                      dayNum: day.dayNum,
                                      isCompleted: day.isCompleted,
                                      isToday: day.isToday,
                                      accentColor: primaryAccent,
                                      isDark: isDark,
                                      slideDelay: Duration(
                                        milliseconds: 700 + (i * 60),
                                      ),
                                      revealDelay: Duration(
                                        milliseconds: 1400 + (i * 130),
                                      ),
                                    );
                                  }),
                                ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats Card (Animated Entrance #3)
                      FadeTransition(
                        opacity: _card3Fade,
                        child: SlideTransition(
                          position: _card3Slide,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Neo.border(2.5),
                              boxShadow: Neo.shadow(3.5),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatMiniCard(
                                    title: 'BEST STREAK',
                                    value: '${engagement.bestStreak}d',
                                    icon: Icons.emoji_events_rounded,
                                    iconColor: const Color(0xFFFACC15),
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatMiniCard(
                                    title: 'TOTAL SOLVED',
                                    value: '${engagement.totalCompleted}',
                                    icon: Icons.military_tech_rounded,
                                    iconColor: primaryAccent,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Encouragement Message (Animated Entrance #4)
                      FadeTransition(
                        opacity: _card4Fade,
                        child: SlideTransition(
                          position: _card4Slide,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Neo.border(2),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: isDark
                                      ? primaryAccent
                                      : Colors.black87,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: engagement.playDays.isEmpty
                                      ? _FirstStreakGuide(textColor: textColor)
                                      : Text(
                                          engagement.currentStreak == 0
                                              ? 'Solve any puzzle today to start your streak!'
                                              : 'Keep playing daily to protect your flame!',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Full Calendar View with Next / Previous Month Navigation (Animated Entrance #5)
                      FadeTransition(
                        opacity: _card5Fade,
                        child: SlideTransition(
                          position: _card5Slide,
                          child: _StreakCalendarView(
                            month: _selectedMonth,
                            playDays: engagement.playDays,
                            accentColor: primaryAccent,
                            cardBg: cardBg,
                            textColor: textColor,
                            isDark: isDark,
                            onPrev: _prevMonth,
                            onNext: _nextMonth,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
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

class _StreakCalendarView extends StatelessWidget {
  final DateTime month;
  final List<String> playDays;
  final Color accentColor;
  final Color cardBg;
  final Color textColor;
  final bool isDark;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _StreakCalendarView({
    required this.month,
    required this.playDays,
    required this.accentColor,
    required this.cardBg,
    required this.textColor,
    required this.isDark,
    required this.onPrev,
    required this.onNext,
  });

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    // Sunday start: 0 for Sunday, 1 for Monday, ..., 6 for Saturday
    final firstWeekdayOffset = firstDayOfMonth.weekday % 7;

    // Count how many days played in this month
    final monthPrefix =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-';
    final playedInMonth = playDays
        .where((d) => d.startsWith(monthPrefix))
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Neo.border(2.5),
        boxShadow: Neo.shadow(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Calendar Header with Month/Year & Prev/Next Controls
          Row(
            children: [
              Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_monthNames[month.month - 1]} ${month.year}'
                        .toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$playedInMonth active ${playedInMonth == 1 ? 'day' : 'days'} this month',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              ),
              const SizedBox(width: 8),
              _MonthNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPrev,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MonthNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNext,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Weekday Headers (S M T W T F S)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((w) {
              return Expanded(
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Calendar Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: firstWeekdayOffset + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekdayOffset) {
                return const SizedBox.shrink();
              }
              final day = index - firstWeekdayOffset + 1;
              final date = DateTime(month.year, month.month, day);
              final dateStr =
                  '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final isCompleted = playDays.contains(dateStr);
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              return Container(
                decoration: BoxDecoration(
                  color: isCompleted
                      ? accentColor
                      : (isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isToday
                        ? Colors.black
                        : (isCompleted ? Colors.black : Colors.black12),
                    width: isToday ? 2.5 : 1.2,
                  ),
                  boxShadow: isCompleted
                      ? Neo.shadow(1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCompleted || isToday
                          ? FontWeight.w900
                          : FontWeight.w700,
                      color: isCompleted
                          ? Colors.black
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _MonthNavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Neo.border(2),
            boxShadow: Neo.shadow(2),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _WeekDayItem extends StatefulWidget {
  final String label;
  final int dayNum;
  final bool isCompleted;
  final bool isToday;
  final Color accentColor;
  final bool isDark;
  final Duration slideDelay;
  final Duration revealDelay;

  const _WeekDayItem({
    required this.label,
    required this.dayNum,
    required this.isCompleted,
    required this.isToday,
    required this.accentColor,
    required this.isDark,
    required this.slideDelay,
    required this.revealDelay,
  });

  @override
  State<_WeekDayItem> createState() => _WeekDayItemState();
}

class _WeekDayItemState extends State<_WeekDayItem>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _revealController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _whiteFlashAnimation;
  late Animation<double> _contentFadeAnimation;

  Timer? _slideTimer;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();

    // 1) Slide in controller (round slides into position)
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(-1.8, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeIn));

    // 2) Reveal controller (white round -> colored circle + shadow + content)
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Fade out the white round into the final colored circle: 0.0 -> 0.65
    _whiteFlashAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );

    // Content reveals as the white circle fades out: 0.35 -> 1.0
    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start slide-in
    _slideTimer = Timer(widget.slideDelay, () {
      if (mounted) {
        _slideController.forward();
      }
    });

    // Start white flash & reveal only after all rounds reach their place
    _revealTimer = Timer(widget.revealDelay, () {
      if (mounted) {
        _revealController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _revealTimer?.cancel();
    _slideController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: widget.isToday ? FontWeight.w900 : FontWeight.w700,
            color: widget.isToday
                ? (widget.isDark ? Colors.white : Colors.black)
                : (widget.isDark ? Colors.white54 : Colors.black54),
          ),
        ),
        const SizedBox(height: 8),
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedBuilder(
              animation: _revealController,
              builder: (context, child) {
                // Before reveal completes, interpolate from white round to target background & shadow
                final revealProgress = 1.0 - _whiteFlashAnimation.value;

                final targetBg = widget.isCompleted
                    ? widget.accentColor
                    : (widget.isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9));

                final currentBg = Color.lerp(
                  Colors.white,
                  targetBg,
                  revealProgress,
                )!;

                final currentBorderColor = Color.lerp(
                  Colors.black26,
                  widget.isToday
                      ? Colors.black
                      : (widget.isCompleted ? Colors.black : Colors.black38),
                  revealProgress,
                )!;

                final targetBorderWidth = widget.isToday ? 2.5 : 1.5;
                final currentBorderWidth =
                    1.5 + (targetBorderWidth - 1.5) * revealProgress;

                // 3D Shadow appears as white goes away
                final shadowOffset = widget.isCompleted
                    ? Offset(2 * revealProgress, 2 * revealProgress)
                    : Offset.zero;

                return Container(
                  width: 42,
                  height: 42,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: currentBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: currentBorderColor,
                      width: currentBorderWidth,
                    ),
                    boxShadow: widget.isCompleted && revealProgress > 0.05
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: revealProgress.clamp(0.0, 1.0),
                              ),
                              offset: shadowOffset,
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: _contentFadeAnimation.value,
                      child: widget.isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 24,
                            )
                          : Text(
                              '${widget.dayNum}',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: widget.isToday
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: widget.isDark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _StatMiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Neo.border(1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white60 : Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// First-run explanation of how streaks work, with a quick way to start.
class _FirstStreakGuide extends StatelessWidget {
  final Color textColor;
  const _FirstStreakGuide({required this.textColor});

  @override
  Widget build(BuildContext context) {
    final pick = GameCatalog.todaysPicks(DateTime.now()).first;
    TextStyle style(double size, FontWeight weight) =>
        TextStyle(fontSize: size, fontWeight: weight, color: textColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('No streak yet — start one today', style: style(14, FontWeight.w900)),
        const SizedBox(height: 6),
        for (final line in const [
          '1. Solve any puzzle, any difficulty.',
          '2. Come back tomorrow and solve another.',
          '3. Each day in a row grows your flame.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(line, style: style(12.5, FontWeight.w700)),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () {
            Navigator.of(context).maybePop();
            GameRouter.openGame(pick.id);
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Play ${pick.name}'),
        ),
      ],
    );
  }
}
