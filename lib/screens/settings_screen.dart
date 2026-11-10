import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/notification_settings_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/services/app_feedback_service.dart';
import '../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final paletteOptions = const [
      ('Mixed Multi-Color', Color(0xFFFACC15), 0),
      ('Sunflower Yellow', Color(0xFFFACC15), 1),
      ('Lime Green', Color(0xFF4ADE80), 2),
      ('Rose Pink', Color(0xFFF43F5E), 3),
      ('Electric Cyan', Color(0xFF38BDF8), 4),
      ('Neon Violet', Color(0xFFC084FC), 5),
      ('Neon Orange', Color(0xFFFB923C), 6),
      ('Minimal Slate', Color(0xFF94A3B8), 7),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.getAccentColor(
                    const Color(0xFFFACC15),
                    state.palette,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                      ),
                    ),
                    Text(
                      'Customize Neo theme & preferences',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          const _Label('ACCENT COLOR PALETTE'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: paletteOptions.map((opt) {
              return ChoiceChip(
                avatar: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: opt.$3 == 0 ? null : opt.$2,
                    gradient: opt.$3 == 0
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
                selected: state.palette == opt.$3,
                onSelected: (_) => notifier.setPalette(opt.$3),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          const _Label('APPEARANCE MODE'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(3.5, 3.5),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: const Text(
                    'Light',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  icon: Icon(
                    Icons.light_mode_outlined,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: const Text(
                    'Dark',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  icon: Icon(
                    Icons.dark_mode_outlined,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: const Text(
                    'System',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  icon: Icon(
                    Icons.settings_brightness_outlined,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (v) => notifier.setThemeMode(v.first),
            ),
          ),
          const SizedBox(height: 28),

          const _Label('GAMEPLAY PREFERENCES'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(3.5, 3.5),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Default Difficulty',
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    initialValue: state.defaultDifficulty,
                    items: ['Easy', 'Medium', 'Hard']
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              v,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) notifier.setDefaultDifficulty(v);
                    },
                  ),
                  const Divider(color: Colors.black, thickness: 2),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor:
                        AppTheme.neoPalettes[state.palette.clamp(0, 4)],
                    title: const Text(
                      'Haptic Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      'Tactile vibrations on key taps & game wins',
                    ),
                    value: state.hapticsEnabled,
                    onChanged: (v) {
                      notifier.setHapticsEnabled(v);
                      if (v) AppFeedbackService.testHaptic();
                    },
                  ),

                  const Divider(color: Colors.black, thickness: 2),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor:
                        AppTheme.neoPalettes[state.palette.clamp(0, 4)],
                    title: const Text(
                      'Daily Five Hard Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      'Must use revealed hints in subsequent guesses',
                    ),
                    value: state.hardModeEnabled,
                    onChanged: notifier.setHardModeEnabled,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          const _Label('NOTIFICATIONS & REMINDERS'),
          const SizedBox(height: 12),
          const _NotificationsSettingsSection(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }
}

class _NotificationsSettingsSection extends ConsumerWidget {
  const _NotificationsSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifState = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final accent = AppTheme.getAccentColor(
      const Color(0xFFFACC15),
      settings.palette,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3.5, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: accent,
              title: const Text(
                'Daily Puzzle Reminders',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              subtitle: const Text(
                '100% offline reminder to solve puzzles and train your brain',
                style: TextStyle(fontSize: 13),
              ),
              value: notifState.enabled,
              onChanged: (val) async {
                final success = await notifier.setEnabled(val);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notification permission is disabled. Please enable it in system settings.',
                      ),
                    ),
                  );
                }
              },
            ),
            if (notifState.enabled) ...[
              const Divider(color: Colors.black, thickness: 2),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(
                    Icons.alarm_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Reminder Time',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                subtitle: Text(
                  notifState.reminderTime.format(context),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    side: const BorderSide(color: Colors.black, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: notifState.reminderTime,
                    );
                    if (picked != null) {
                      await notifier.setReminderTime(picked);
                    }
                  },
                  child: const Text(
                    'Change',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
            if (!notifState.systemPermissionGranted && notifState.enabled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade800, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Notifications are blocked in Android/iOS device settings.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
