import '../services/game_rules.dart';
import 'package:puzzlebox/core/theme/neo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/app_feedback_service.dart';
import '../theme/app_theme.dart';
import '../game_catalog.dart';

/// Common scaffold used by all game screens and the home screen.
///
/// Game screens get one consistent top bar: game badge and title on the left,
/// then (when provided) timer, undo and hint, followed by How to play and
/// display settings. Game-specific [actions] sit just before the timer.
class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final bool showInfoAction;
  final bool showSettingsAction;

  /// Catalog id of the game; adds the coloured badge that flies in from Home.
  final String? gameId;

  /// Elapsed seconds for the current puzzle, shown as a timer chip.
  final ValueListenable<int>? timer;
  final VoidCallback? onUndo;
  final VoidCallback? onHint;
  final String undoTooltip;
  final String hintTooltip;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
    this.showBackButton = false,
    this.showInfoAction = true,
    this.showSettingsAction = false,
    this.gameId,
    this.timer,
    this.onUndo,
    this.onHint,
    this.undoTooltip = 'Undo',
    this.hintTooltip = 'Hint',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final mainTitle = title.split(' — ').first;
    final game = GameCatalog.byId(gameId);
    final palette = ref.watch(settingsProvider.select((s) => s.palette));

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
                side: Neo.side(2.5),
              ),
              title: const Text('How to Play', style: TextStyle(fontWeight: FontWeight.w900)),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: Text(rules, style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600)),
                ),
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

    void showRules() => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameRulesSheet(title: mainTitle, rules: rulesFor(title)),
    );

    void showSettings() => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsSheet(),
    );

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        elevation: 0,
        titleSpacing: showBackButton ? 0 : 16,
        title: Row(
          children: [
            if (game != null) ...[
              GameBadge(
                game: game,
                color: AppTheme.getAccentColor(game.color, palette),
                size: 30,
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Semantics(
                  header: true,
                  child: Text(
                    mainTitle,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: showBackButton,
        actions: [
          ...?actions,
          if (timer != null) _TimerChip(seconds: timer!),
          if (onUndo != null)
            AppBarIconButton(
              icon: Icons.undo_rounded,
              tooltip: undoTooltip,
              onTap: onUndo!,
            ),
          if (onHint != null)
            AppBarIconButton(
              icon: Icons.lightbulb_outline_rounded,
              tooltip: hintTooltip,
              onTap: onHint!,
            ),
          // Games fold rules + display settings into one menu so the bar
          // keeps room for the timer, undo and hint on small phones.
          if (game != null)
            _MoreMenu(
              onRules: showInfoAction ? showRules : null,
              onSettings: showSettings,
            )
          else ...[
            if (showInfoAction)
              AppBarIconButton(
                icon: Icons.info_outline_rounded,
                tooltip: 'How to play',
                onTap: showRules,
              ),
            if (showSettingsAction)
              AppBarIconButton(
                icon: Icons.tune_rounded,
                tooltip: 'Display settings',
                onTap: showSettings,
              ),
          ],
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(Neo.width(2.5)),
          child: Container(
            height: Neo.width(2.5),
            color: Neo.ink,
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

/// Coloured icon tile for a game; flies between Home and the game screen.
class GameBadge extends StatelessWidget {
  final GameInfo game;
  final Color color;
  final double size;
  final bool hero;

  const GameBadge({
    super.key,
    required this.game,
    required this.color,
    this.size = 38,
    this.hero = true,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * .32),
        border: Neo.border(2.0),
      ),
      child: Icon(game.icon, color: Colors.black, size: size * .53),
    );
    final badge = ExcludeSemantics(child: tile);
    if (!hero) return badge;
    return Hero(
      tag: game.heroTag,
      child: Material(type: MaterialType.transparency, child: badge),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final VoidCallback? onRules;
  final VoidCallback onSettings;
  const _MoreMenu({required this.onRules, required this.onSettings});

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
        border: Neo.border(2.0),
      ),
      child: PopupMenuButton<VoidCallback>(
        padding: EdgeInsets.zero,
        tooltip: 'More options',
        icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: Neo.side(2),
        ),
        onSelected: (action) => action(),
        itemBuilder: (_) => [
          if (onRules != null)
            PopupMenuItem(
              value: onRules,
              child: const _MenuRow(Icons.info_outline_rounded, 'How to play'),
            ),
          PopupMenuItem(
            value: onSettings,
            child: const _MenuRow(Icons.tune_rounded, 'Display settings'),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

class _TimerChip extends StatelessWidget {
  final ValueListenable<int> seconds;
  const _TimerChip({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<int>(
      valueListenable: seconds,
      builder: (context, value, _) {
        return Semantics(
          label: 'Time ${value ~/ 60} minutes ${value % 60} seconds',
          excludeSemantics: true,
          child: Container(
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Neo.border(2.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 14, color: isDark ? Colors.white : Colors.black),
                const SizedBox(width: 3),
                Text(
                  formatClock(value),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Formats seconds as m:ss (or h:mm:ss for long sessions).
String formatClock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

// Top-right icon button used in AppBar actions.
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
        border: Neo.border(2.0),
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
    final media = MediaQuery.of(context);
    final maxHeight = (media.size.height * 0.85).clamp(280.0, 620.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: Neo.side(3.0),
              left: Neo.side(3.0),
              right: Neo.side(3.0),
            ),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Neo.border(2.0),
                        boxShadow: Neo.shadow(2),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 20, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Neo Customization',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -.5),
                          ),
                          Text(
                            'Appearance & haptic preferences',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.onSurfaceVariant),
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
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACCENT COLOR PALETTE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: isDark ? Colors.white : Colors.black,
                          ),
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
                                    border: Neo.border(1.5),
                                  ),
                                ),
                                label: Text(opt.$1),
                                selected: settings.palette == opt.$2,
                                onSelected: (_) =>
                                    ref.read(settingsProvider.notifier).setPalette(opt.$2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Neo.border(2.0),
                            boxShadow: Neo.shadow(2.5),
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
                              const Divider(color: Colors.black, thickness: 1.5),
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
                              Divider(color: Neo.ink, thickness: Neo.width(1.5)),
                              _SettingRow(
                                label: 'Soft Outlines',
                                subtitle: 'Thinner borders and gentle shadows',
                                child: Switch(
                                  value: settings.neoStyle == NeoStyle.soft,
                                  activeThumbColor: colors.primary,
                                  onChanged: (v) => ref
                                      .read(settingsProvider.notifier)
                                      .setNeoStyle(v ? NeoStyle.soft : NeoStyle.bold),
                                ),
                              ),
                              Divider(color: Neo.ink, thickness: Neo.width(1.5)),
                              _SettingRow(
                                label: 'Colorblind Friendly',
                                subtitle: 'Blue/orange feedback with shape cues',
                                child: Switch(
                                  value: settings.colorblindMode,
                                  activeThumbColor: colors.primary,
                                  onChanged: (v) => ref
                                      .read(settingsProvider.notifier)
                                      .setColorblindMode(v),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'TEXT SIZE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const TextSizeChips(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(14),
                        border: Neo.border(2.5),
                        boxShadow: Neo.shadow(2.5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 15.5,
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
        ),
      ),
    );
  }
}

/// Text size picker shared by the settings sheet and the Settings tab.
class TextSizeChips extends ConsumerWidget {
  const TextSizeChips({super.key});

  static String _label(double scale) => switch (scale) {
    0 => 'System',
    1.0 => 'Default',
    1.15 => 'Large',
    1.3 => 'Larger',
    _ => '${(scale * 100).round()}%',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsProvider.select((s) => s.textScale));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in SettingsNotifier.textScaleOptions)
          ChoiceChip(
            label: Text(_label(option)),
            selected: current == option,
            onSelected: (_) =>
                ref.read(settingsProvider.notifier).setTextScale(option),
          ),
      ],
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
    final media = MediaQuery.of(context);
    final maxHeight = (media.size.height * 0.78).clamp(240.0, 580.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: Neo.side(3.0),
              left: Neo.side(3.0),
              right: Neo.side(3.0),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SafeArea(
            top: false,
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
                const SizedBox(height: 12),

                // Header Row
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Neo.border(2.0),
                        boxShadow: Neo.shadow(2),
                      ),
                      child: const Icon(Icons.help_outline_rounded, size: 20, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How to Play',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
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
                const SizedBox(height: 12),

                // Rules Content Card - Scrollable within pinned layout
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Neo.border(2.0),
                      boxShadow: Neo.shadow(2.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            rules,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // "Got it!" Neo-Brutalist button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(14),
                        border: Neo.border(2.5),
                        boxShadow: Neo.shadow(2.5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Got it, let's play!",
                        style: TextStyle(
                          fontSize: 15.5,
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
        ),
      ),
    );
  }
}
