import 'package:flutter/material.dart';

enum GameMode { daily, practice }

class GameModeToggle extends StatelessWidget {
  final GameMode mode;
  final ValueChanged<GameMode> onModeChanged;
  final int practiceSolvedCount;

  const GameModeToggle({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.practiceSolvedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = constraints.maxWidth < 380 ? 380.0 : constraints.maxWidth;
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: targetWidth,
              child: Row(
                children: [
                  // Mode Segmented Capsule (pinned position)
                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2.2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ModeTab(
                          label: 'Daily',
                          isSelected: mode == GameMode.daily,
                          onTap: () => onModeChanged(GameMode.daily),
                        ),
                        _ModeTab(
                          label: 'Unlimited',
                          isSelected: mode == GameMode.practice,
                          onTap: () => onModeChanged(GameMode.practice),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Practice Session Counter Badge (reserved slot, never moves or collapses)
                  Visibility(
                    visible: mode == GameMode.practice,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black, width: 1.8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            'Solved: $practiceSolvedCount',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.black, width: 1.5) : null,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
