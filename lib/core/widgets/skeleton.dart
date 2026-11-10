import 'package:flutter/material.dart';
import '../theme/neo.dart';

/// Gently pulsing placeholder shown while content is being prepared, so the
/// screen keeps its shape instead of flashing a spinner.
class SkeletonPulse extends StatefulWidget {
  final Widget child;
  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect "reduce motion": keep a static placeholder.
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: Tween(begin: .45, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Square grid placeholder sized like a puzzle board.
class SkeletonBoard extends StatelessWidget {
  final int rows;
  final int columns;
  final double maxSize;

  const SkeletonBoard({
    super.key,
    this.rows = 6,
    this.columns = 6,
    this.maxSize = 340,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cell = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return Semantics(
      label: 'Preparing puzzle',
      liveRegion: true,
      child: SkeletonPulse(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxSize, maxHeight: maxSize),
          child: AspectRatio(
            aspectRatio: columns / rows,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Neo.border(2.5),
                boxShadow: Neo.shadow(3),
              ),
              child: Column(
                children: [
                  for (var r = 0; r < rows; r++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var c = 0; c < columns; c++)
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  color: cell,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
