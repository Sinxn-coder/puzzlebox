import 'package:flutter/material.dart';
import 'package:puzzlebox/core/theme/neo.dart';

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
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Mode Segmented Capsule (pinned position)
                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Neo.border(2.2),
                      boxShadow: Neo.shadow(2.5),
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

                  const SizedBox(width: 12),

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
                        border: Neo.border(1.8),
                        boxShadow: Neo.shadow(2),
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
          border: isSelected ? Neo.border(1.5) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            // Unselected tabs sit on the card background, so follow the theme
            // (black on dark slate was unreadable in dark mode).
            color: isSelected ? Colors.black : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

/// One compact row of game controls: Daily/Unlimited, a difficulty chip that
/// opens Easy/Medium/Hard, and a Next button. Replaces the old two-row
/// toggle + difficulty bar so the board gets more room.
class GameControlBar extends StatelessWidget {
  final GameMode mode;
  final ValueChanged<GameMode> onModeChanged;
  final String difficulty;
  final ValueChanged<String> onDifficultyChanged;
  final VoidCallback onNext;
  final int practiceSolvedCount;
  final List<String> difficulties;

  const GameControlBar({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.difficulty,
    required this.onDifficultyChanged,
    required this.onNext,
    this.practiceSolvedCount = 0,
    this.difficulties = const ['Easy', 'Medium', 'Hard'],
  });

  static Color difficultyColor(String d) => switch (d.toLowerCase()) {
    'easy' => const Color(0xFF4ADE80),
    'medium' => const Color(0xFFFACC15),
    'hard' => const Color(0xFFF43F5E),
    _ => const Color(0xFF38BDF8),
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final ink = isDark ? Colors.white : Colors.black;
    // Grow with the text size; FittedBox then shrinks to fit narrow phones.
    final k = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final h = 40 * k;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: SizedBox(
        height: h + 2,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 336 * k,
            height: h + 2,
            child: Row(
              children: [
                // Daily / Unlimited
                Container(
                  height: h,
                  padding: const EdgeInsets.all(3.0),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Neo.border(2.2),
                    boxShadow: Neo.shadow(2.5),
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
                const SizedBox(width: 8),
                // Difficulty chip
                Expanded(
                  child: PopupMenuButton<String>(
                    tooltip: 'Difficulty: $difficulty',
                    onSelected: onDifficultyChanged,
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: Neo.side(2),
                    ),
                    color: surface,
                    itemBuilder: (_) => [
                      for (final d in difficulties)
                        PopupMenuItem(
                          value: d,
                          child: Row(
                            children: [
                              _Dot(color: difficultyColor(d)),
                              const SizedBox(width: 10),
                              Text(
                                d,
                                style: TextStyle(
                                  fontWeight: d == difficulty ? FontWeight.w900 : FontWeight.w700,
                                  color: ink,
                                ),
                              ),
                              if (d == difficulty) ...[
                                const Spacer(),
                                Icon(Icons.check_rounded, size: 18, color: ink),
                              ],
                            ],
                          ),
                        ),
                      if (mode == GameMode.practice && practiceSolvedCount > 0)
                        PopupMenuItem<String>(
                          enabled: false,
                          height: 32,
                          child: Text(
                            'Unlimited solved: $practiceSolvedCount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                    child: Container(
                      height: h,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: difficultyColor(difficulty),
                        borderRadius: BorderRadius.circular(12),
                        border: Neo.border(2.0),
                        boxShadow: Neo.shadow(2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              difficulty,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const Icon(Icons.expand_more_rounded, size: 18, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Next puzzle
                Container(
                  width: 44 * k,
                  height: h,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Neo.border(2.2),
                    boxShadow: Neo.shadow(2.5),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Next puzzle',
                    onPressed: onNext,
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.black, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Neo.border(1.0),
    ),
  );
}

/// Asks before throwing away a puzzle the player has started.
Future<bool> confirmSkipPuzzle(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Skip this puzzle?'),
      content: const Text('Your progress on this puzzle will be lost.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Keep playing'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    ),
  );
  return result ?? false;
}
