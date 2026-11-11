import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Shakes its child sideways each time [trigger] changes (a wrong move).
class Shake extends StatefulWidget {
  final ValueListenable<int> trigger;
  final Widget child;
  const Shake({super.key, required this.trigger, required this.child});

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_play);
  }

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      old.trigger.removeListener(_play);
      widget.trigger.addListener(_play);
    }
  }

  void _play() {
    if (!mounted || _reduceMotion(context)) return;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_play);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) {
      final t = _c.value;
      final dx = math.sin(t * math.pi * 6) * 9 * (1 - t);
      return Transform.translate(offset: Offset(dx, 0), child: child);
    },
    child: widget.child,
  );
}

/// A diagonal light sweep across its child each time [trigger] changes
/// (a solved puzzle), the "board lights up" moment before the confetti.
class WinSweep extends StatefulWidget {
  final ValueListenable<int> trigger;
  final Widget child;
  const WinSweep({super.key, required this.trigger, required this.child});

  @override
  State<WinSweep> createState() => _WinSweepState();
}

class _WinSweepState extends State<WinSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_play);
  }

  @override
  void didUpdateWidget(WinSweep old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      old.trigger.removeListener(_play);
      widget.trigger.addListener(_play);
    }
  }

  void _play() {
    if (!mounted || _reduceMotion(context)) return;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_play);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              if (!_c.isAnimating) return const SizedBox.shrink();
              final t = Curves.easeInOut.transform(_c.value);
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.6 + 3.2 * t, -1),
                    end: Alignment(-0.6 + 3.2 * t, 1),
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: .45),
                      Colors.white.withValues(alpha: 0),
                    ],
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

/// Pops (1.0 → 1.12 → 1.0) whenever [value] changes, e.g. a placed number.
class PopOnChange extends StatelessWidget {
  final Object? value;
  final Widget child;
  const PopOnChange({super.key, required this.value, required this.child});

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      builder: (context, t, child) {
        final bump = value == null || value == '' || value == 0
            ? 0.0
            : math.sin(t * math.pi) * .12;
        return Transform.scale(scale: 1 + bump, child: child);
      },
      child: child,
    );
  }
}

/// Fades and slides its child in after [delay], the first time it builds.
class EntranceFade extends StatelessWidget {
  final Duration delay;
  final bool enabled;
  final Widget child;
  const EntranceFade({
    super.key,
    required this.delay,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || _reduceMotion(context)) return child;
    final total = delay + const Duration(milliseconds: 360);
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, v, child) {
        final t = Curves.easeOutCubic.transform(
          ((v - start) / (1 - start)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
        );
      },
      child: child,
    );
  }
}
