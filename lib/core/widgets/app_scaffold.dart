import '../services/game_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/app_feedback_service.dart';
import '../theme/app_theme.dart';

/// Common scaffold used by all game screens and the home screen.
class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final bool showInfoAction;
  final bool showSettingsAction;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
    this.showBackButton = false,
    this.showInfoAction = true,
    this.showSettingsAction = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final mainTitle = title.split(' — ').first;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            mainTitle,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        automaticallyImplyLeading: showBackButton,
        actions: [
          ...?actions,
          if (showInfoAction)
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 2),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2.0),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.info_outline_rounded, size: 21, color: Colors.black),
                  tooltip: 'How to play',
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => GameRulesSheet(
                      title: mainTitle,
                      rules: rulesFor(title),
                    ),
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: Container(
            height: 2.5,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Top-right icon button used in AppBar actions.
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 38,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: Colors.black),
        onPressed: onTap,
        tooltip: tooltip,
      ),
    );
  }
}

/// Settings bottom sheet accessible from every game screen.
class SettingsSheet extends ConsumerWidget {
  final String? helpText;
  const SettingsSheet({super.key, this.helpText});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final paletteNames = [
      'Sunflower Yellow',
      'Lime Green',
      'Rose Pink',
      'Electric Cyan',
      'Neon Violet',
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: Colors.black, width: 3.0)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Neo Customization',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Select your favorite accent color & appearance mode',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          const Text(
            'ACCENT COLOR PALETTE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < paletteNames.length; i++)
                ChoiceChip(
                  avatar: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.neoPalettes[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                  ),
                  label: Text(paletteNames[i]),
                  selected: settings.palette == i,
                  onSelected: (_) =>
                      ref.read(settingsProvider.notifier).setPalette(i),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _SettingRow(
                  label: 'Dark Mode',
                  subtitle: 'Switch app appearance theme',
                  child: Switch(
                    value: settings.themeMode == ThemeMode.dark,
                    activeThumbColor: colors.primary,
                    onChanged: (v) {
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ),
                const Divider(color: Colors.black, thickness: 2),
                _SettingRow(
                  label: 'Haptic Feedback',
                  subtitle: 'Tactile vibrations on key taps & game wins',
                  child: Switch(
                    value: settings.hapticsEnabled,
                    activeThumbColor: colors.primary,
                    onChanged: (v) {
                      ref.read(settingsProvider.notifier).setHapticsEnabled(v);
                      if (v) AppFeedbackService.testHaptic();
                    },
                  ),
                ),

              ],
            ),
          ),
          if (helpText != null) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.black, width: 2.0),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.black, width: 2.0),
              ),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              collapsedBackgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: const Text('How to Play', style: TextStyle(fontWeight: FontWeight.w900)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(helpText!, style: const TextStyle(height: 1.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final Widget child;

  const _SettingRow({
    required this.label,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// Neo-Brutalist rules / info bottom sheet shown from the in-game info button.
class GameRulesSheet extends StatelessWidget {
  final String title;
  final String rules;

  const GameRulesSheet({
    super.key,
    required this.title,
    required this.rules,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(
          top: BorderSide(color: Colors.black, width: 3.0),
          left: BorderSide(color: Colors.black, width: 3.0),
          right: BorderSide(color: Colors.black, width: 3.0),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag indicator handle
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
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
                    ],
                  ),
                  child: const Icon(Icons.help_outline_rounded, size: 22, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to Play',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Rules Content Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2.0),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                ],
              ),
              child: Text(
                rules,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // "Got it!" Neo-Brutalist button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Got it, let's play!",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
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
