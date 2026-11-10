import 'package:flutter/material.dart';
import '../services/game_tutorials.dart';
import '../theme/neo.dart';

/// First-time, three-step tutorial for a game: swipe or tap Next through
/// short cards instead of reading a wall of rules.
class GameTutorialSheet extends StatefulWidget {
  final String gameName;
  final List<TutorialStep> steps;

  const GameTutorialSheet({
    super.key,
    required this.gameName,
    required this.steps,
  });

  static Future<void> show(BuildContext context, String gameName, String title) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => GameTutorialSheet(gameName: gameName, steps: tutorialFor(title)),
      );

  @override
  State<GameTutorialSheet> createState() => _GameTutorialSheetState();
}

class _GameTutorialSheetState extends State<GameTutorialSheet> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) => _pages.animateToPage(
    i,
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final last = _index == widget.steps.length - 1;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: Neo.side(3), left: Neo.side(3), right: Neo.side(3)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white38 : Colors.black26,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'How to play ${widget.gameName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -.4),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 190 * textScale.clamp(1.0, 1.6),
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      for (final (i, step) in widget.steps.indexed)
                        _StepCard(step: step, number: i + 1, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.steps.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index ? colors.primary : colors.outlineVariant.withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(4),
                          border: i == _index ? Neo.border(1.2) : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (_index > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _go(_index - 1),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: last ? () => Navigator.pop(context) : () => _go(_index + 1),
                        child: Text(last ? "Let's play!" : 'Next step'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final TutorialStep step;
  final int number;
  final bool isDark;

  const _StepCard({required this.step, required this.number, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, title, body) = step;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Neo.border(2),
        boxShadow: Neo.shadow(2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(14),
                  border: Neo.border(2),
                ),
                child: Icon(icon, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'STEP $number',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              body,
              style: TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w600, color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
