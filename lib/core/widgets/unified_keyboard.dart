import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_feedback_service.dart';

const _defaultRows = [
  ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
  ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
];

const _noEnterRows = [
  ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
  ['Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
];

/// Shared Neo-Brutalist QWERTY keyboard used across word and crossword games.
class UnifiedKeyboard extends ConsumerWidget {
  final ValueChanged<String> onKeyTap;
  final Map<String, Color>? keyColors;
  final bool showEnter;
  final bool enabled;

  const UnifiedKeyboard({
    super.key,
    required this.onKeyTap,
    this.keyColors,
    this.showEnter = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = showEnter ? _defaultRows : _noEnterRows;

    void handleTap(String key) {
      if (!enabled) return;
      AppFeedbackService.tap(ref);
      onKeyTap(key);
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
                  children: rows.map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: row.map((key) {
                          final isWide = key == 'ENTER' || key == '⌫';
                          final color = keyColors?[key.toLowerCase()];
                          return Expanded(
                            flex: isWide ? (showEnter ? 15 : 14) : 10,
                            child: _UnifiedKeyButton(
                              label: key,
                              bgColor: color,
                              isWide: isWide,
                              onTap: () => handleTap(key),
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

class _UnifiedKeyButton extends StatelessWidget {
  final String label;
  final Color? bgColor;
  final bool isWide;
  final VoidCallback onTap;

  const _UnifiedKeyButton({
    required this.label,
    required this.bgColor,
    required this.isWide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        height: 54,
        decoration: BoxDecoration(
          color: bgColor ?? defaultBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(1.5, 1.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: label == '⌫'
              ? const Icon(Icons.backspace_outlined, size: 18, color: Colors.black)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: label == 'ENTER' ? 10.5 : 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
        ),
      ),
    );
  }
}
