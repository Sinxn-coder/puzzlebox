import 'package:flutter/material.dart';
import 'package:puzzlebox/core/theme/neo.dart';

/// Neo-Brutalist Difficulty Selector & Next Control Bar used across all game practice modes.
class NeoDifficultyBar extends StatelessWidget {
  final String currentDifficulty;
  final ValueChanged<String> onDifficultyChanged;
  final VoidCallback onNextPressed;
  final List<String> difficulties;

  const NeoDifficultyBar({
    super.key,
    required this.currentDifficulty,
    required this.onDifficultyChanged,
    required this.onNextPressed,
    this.difficulties = const ['Easy', 'Medium', 'Hard'],
  });

  Color _getDifficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4ADE80); // Lime Green
      case 'medium':
        return const Color(0xFFFACC15); // Yellow
      case 'hard':
        return const Color(0xFFF43F5E); // Rose Pink
      default:
        return const Color(0xFF38BDF8); // Cyan
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
                children: difficulties.map((d) {
                  final isSelected = d.toLowerCase() == currentDifficulty.toLowerCase();
                  final diffColor = _getDifficultyColor(d);

                  return Expanded(
                    child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: '$d difficulty',
                      excludeSemantics: true,
                      child: PressableScale(
                      onTap: () => onDifficultyChanged(d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? diffColor
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Neo.border(2.0),
                          boxShadow: Neo.isSoft
                              ? (isSelected ? Neo.shadow(2) : null)
                              : [
                                  BoxShadow(
                                    color: isSelected ? Colors.black : Colors.black45,
                                    offset: const Offset(2.0, 2.0),
                                    blurRadius: 0,
                                  ),
                                ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: diffColor,
                                shape: BoxShape.circle,
                                border: Neo.border(1.0),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              d,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                color: isSelected
                                    ? Colors.black
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                    ),
                    ),
                  );
                }).toList(),
            ),
          ),
          const SizedBox(width: 0),
          PressableScale(
            onTap: onNextPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
                border: Neo.border(2.2),
                boxShadow: Neo.shadow(2.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.skip_next_rounded, size: 18, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const PressableScale({super.key, required this.child, required this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
