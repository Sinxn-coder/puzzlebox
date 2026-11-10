import 'package:flutter/material.dart';
import 'package:puzzlebox/core/theme/neo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/feedback_colors.dart';
import '../../../core/widgets/game_mode_toggle.dart';
import '../models/letter_state.dart';
import '../providers/daily_five_provider.dart';

import '../../../core/services/app_feedback_service.dart';

const _rows = [
  ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
  ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
];

/// On-screen QWERTY keyboard with per-letter colour feedback.
class KeyboardWidget extends ConsumerWidget {
  final GameMode mode;

  const KeyboardWidget({super.key, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(dailyFiveProvider(mode));

    void onKey(String key) {
      AppFeedbackService.tap(ref);
      if (key == '⌫') {
        ref.read(dailyFiveProvider(mode).notifier).deleteLetter();
      } else if (key == 'ENTER') {
        ref.read(dailyFiveProvider(mode).notifier).submitGuess();
      } else {
        ref.read(dailyFiveProvider(mode).notifier).addLetter(key);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 380,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _rows.map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: row.map((key) {
                          final state = game.keyStates[key.toLowerCase()];
                          return Expanded(
                            flex: key == 'ENTER' || key == '⌫' ? 15 : 10,
                            child: _KeyButton(
                              label: key,
                              state: state,
                              onTap: () => onKey(key),
                              isWide: key == 'ENTER' || key == '⌫',
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final LetterState? state;
  final VoidCallback onTap;
  final bool isWide;

  const _KeyButton({
    required this.label,
    required this.state,
    required this.onTap,
    this.isWide = false,
  });

  Color _bg(BuildContext context, bool isDark) {
    switch (state) {
      case LetterState.correct:
        return FeedbackColors.correct;
      case LetterState.present:
        return FeedbackColors.present;
      case LetterState.absent:
        return isDark ? Colors.grey.shade800 : Colors.grey.shade400;
      default:
        return isDark ? const Color(0xFF1E293B) : Colors.white;
    }
  }

  Color _fg(BuildContext context, bool isDark) {
    if (state == LetterState.correct || state == LetterState.present) {
      return Colors.black;
    }
    return isDark ? Colors.white : Colors.black;
  }

  String get _semanticLabel {
    final name = switch (label) {
      '⌫' => 'Delete',
      'ENTER' => 'Enter',
      _ => label,
    };
    return switch (state) {
      LetterState.correct => '$name, correct spot',
      LetterState.present => '$name, in word',
      LetterState.absent => '$name, not in word',
      _ => name,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: _semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        height: 54,
        decoration: BoxDecoration(
          color: _bg(context, isDark),
          borderRadius: BorderRadius.circular(8),
          border: Neo.border(1.5),
          boxShadow: Neo.shadow(1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: label == 'ENTER' ? 10.5 : 15,
              fontWeight: FontWeight.w900,
              color: _fg(context, isDark),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
