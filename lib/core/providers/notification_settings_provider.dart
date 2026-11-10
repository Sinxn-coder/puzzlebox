import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

class NotificationSettingsState {
  final bool enabled;
  final TimeOfDay reminderTime;
  final bool promptHandled;
  final bool systemPermissionGranted;

  const NotificationSettingsState({
    required this.enabled,
    required this.reminderTime,
    required this.promptHandled,
    required this.systemPermissionGranted,
  });

  NotificationSettingsState copyWith({
    bool? enabled,
    TimeOfDay? reminderTime,
    bool? promptHandled,
    bool? systemPermissionGranted,
  }) {
    return NotificationSettingsState(
      enabled: enabled ?? this.enabled,
      reminderTime: reminderTime ?? this.reminderTime,
      promptHandled: promptHandled ?? this.promptHandled,
      systemPermissionGranted:
          systemPermissionGranted ?? this.systemPermissionGranted,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettingsState> {
  static const _enabledKey = 'settings_notifications_enabled';
  static const _hourKey = 'settings_notification_hour';
  static const _minuteKey = 'settings_notification_minute';
  static const _promptHandledKey = 'settings_notification_prompt_handled';

  // Default time: 09:00 AM (ideal morning brain workout)
  static const defaultHour = 9;
  static const defaultMinute = 0;

  @override
  NotificationSettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final hour = prefs.getInt(_hourKey) ?? defaultHour;
    final minute = prefs.getInt(_minuteKey) ?? defaultMinute;
    final promptHandled = prefs.getBool(_promptHandledKey) ?? false;

    return NotificationSettingsState(
      enabled: enabled,
      reminderTime: TimeOfDay(hour: hour, minute: minute),
      promptHandled: promptHandled,
      systemPermissionGranted: true, // will be verified via checkPermission
    );
  }

  Future<void> checkPermissionStatus() async {
    final service = ref.read(notificationServiceProvider);
    final granted = await service.hasPermission();
    state = state.copyWith(systemPermissionGranted: granted);
    // If system permission was revoked outside the app, reflect it safely
    if (!granted && state.enabled) {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(_enabledKey, false);
      state = state.copyWith(enabled: false);
      await service.cancelDailyReminder();
    }
  }

  Future<bool> setEnabled(bool enable) async {
    final service = ref.read(notificationServiceProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    if (enable) {
      final hasPermission = await service.hasPermission();
      bool granted = hasPermission;
      if (!granted) {
        granted = await service.requestPermission();
      }

      state = state.copyWith(systemPermissionGranted: granted);

      if (!granted) {
        // Permission denied by OS; do not falsely display enabled
        await prefs.setBool(_enabledKey, false);
        state = state.copyWith(enabled: false);
        return false;
      }

      await prefs.setBool(_enabledKey, true);
      state = state.copyWith(enabled: true);
      await service.scheduleDailyReminder(time: state.reminderTime);
      return true;
    } else {
      await prefs.setBool(_enabledKey, false);
      state = state.copyWith(enabled: false);
      await service.cancelDailyReminder();
      return true;
    }
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);
    state = state.copyWith(reminderTime: time);

    // If notifications are active, update schedule immediately with no duplicates
    if (state.enabled) {
      final service = ref.read(notificationServiceProvider);
      await service.scheduleDailyReminder(time: time);
    }
  }

  Future<bool> sendTestNotification() async {
    final service = ref.read(notificationServiceProvider);
    final granted = await service.hasPermission();
    if (!granted) {
      final req = await service.requestPermission();
      if (!req) return false;
    }
    await service.showTestNotification();
    return true;
  }

  Future<void> markPromptHandled() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_promptHandledKey, true);
    state = state.copyWith(promptHandled: true);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
  NotificationSettingsNotifier.new,
);
