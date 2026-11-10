import 'package:flutter/material.dart';
import 'package:puzzlebox/core/theme/neo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/notification_settings_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pressable_scale.dart';

class NotificationPermissionSheet extends ConsumerWidget {
  const NotificationPermissionSheet({super.key});

  static Future<void> showIfNeeded(BuildContext context, WidgetRef ref) async {
    final notifState = ref.read(notificationSettingsProvider);
    if (notifState.promptHandled) return;
    if (!context.mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationPermissionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final accent = AppTheme.getAccentColor(const Color(0xFFFACC15), settings.palette);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Neo.border(3),
        boxShadow: Neo.shadow(0, -4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white38 : Colors.black26,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),

          // Neo badge
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(18),
              border: Neo.border(2.5),
              boxShadow: Neo.shadow(3),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.black,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Daily Mindful Reminders',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            'Get one thoughtful reminder each day to keep your puzzle streak alive and sharpen your mind. Completely offline, private, and customizable.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 24),

          // Turn on button
          PressableScale(
            child: GestureDetector(
              onTap: () async {
                final notifier = ref.read(notificationSettingsProvider.notifier);
                await notifier.markPromptHandled();
                await notifier.setEnabled(true);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(16),
                  border: Neo.border(2.5),
                  boxShadow: Neo.shadow(3),
                ),
                child: const Text(
                  'Enable Reminders',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Skip button
          PressableScale(
            child: GestureDetector(
              onTap: () async {
                final notifier = ref.read(notificationSettingsProvider.notifier);
                await notifier.markPromptHandled();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Skip for now',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
