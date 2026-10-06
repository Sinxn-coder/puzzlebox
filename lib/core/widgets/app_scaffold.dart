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
  final bool showSettingsAction;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
    this.showBackButton = false,
    this.showSettingsAction = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final parts = title.split(' — ');
    final mainTitle = parts.first;
    final modeTag = parts.length > 1 ? parts[1] : null;

    final prefs = ref.read(sharedPreferencesProvider);
    final rulesKey = 'has_seen_rules_$mainTitle';
    final hasSeenRules = prefs.getBool(rulesKey) ?? false;

    if (!hasSeenRules) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        prefs.setBool(rulesKey, true);
        final rules = rulesFor(title);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
              title: const Text('How to Play', style: TextStyle(fontWeight: FontWeight.w900)),
              content: SingleChildScrollView(
                child: Text(rules, style: const TextStyle(height: 1.4, fontWeight: FontWeight.w600)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mainTitle,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              if (modeTag != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(
                    modeTag,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        automaticallyImplyLeading: showBackButton,
        actions: [
          ...?actions,
          if (showSettingsAction)
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
                  icon: const Icon(Icons.settings_outlined, size: 20, color: Colors.black),
                  tooltip: 'Settings',
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const SingleChildScrollView(
                      child: SettingsSheet(),
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
            child: Stack(
              children: [
                body,
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2.0),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5), blurRadius: 0),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.info_outline_rounded, size: 24, color: Colors.black),
                      tooltip: 'How to play',
                      onPressed: () {
                      final rules = rulesFor(title);
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                          title: const Text('How to Play', style: TextStyle(fontWeight: FontWeight.w900)),
                          content: SingleChildScrollView(
                            child: Text(rules, style: const TextStyle(height: 1.4, fontWeight: FontWeight.w600)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ),
              ],
            ),
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
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final paletteOptions = const [
      ('Mixed', 0),
      ('Sunflower Yellow', 1),
      ('Lime Green', 2),
      ('Rose Pink', 3),
      ('Electric Cyan', 4),
      ('Neon Violet', 5),
      ('Neon Orange', 6),
      ('Minimal Slate', 7),
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
              for (final opt in paletteOptions)
                ChoiceChip(
                  avatar: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: opt.$2 == 0 ? null : AppTheme.neoPalettes[opt.$2],
                      gradient: opt.$2 == 0
                          ? const SweepGradient(
                              colors: [
                                Color(0xFFFACC15),
                                Color(0xFF4ADE80),
                                Color(0xFFF43F5E),
                                Color(0xFF38BDF8),
                                Color(0xFFC084FC),
                                Color(0xFFFB923C),
                                Color(0xFFFACC15),
                              ],
                            )
                          : null,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                  ),
                  label: Text(opt.$1),
                  selected: settings.palette == opt.$2,
                  onSelected: (_) =>
                      ref.read(settingsProvider.notifier).setPalette(opt.$2),
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
