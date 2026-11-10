import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'notification_content.dart';

/// Service interface to allow complete unit test mocking.
abstract class NotificationService {
  Future<void> initialize({void Function(String? payload)? onNotificationTapped});
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<void> scheduleDailyReminder({required TimeOfDay time});
  Future<void> cancelDailyReminder();
  Future<void> showTestNotification();
  Future<List<PendingNotificationRequest>> getPendingNotifications();
}

class LocalNotificationService implements NotificationService {
  static const int dailyReminderNotificationId = 1001;
  static const int testNotificationId = 9999;
  static const String channelId = 'puzzlebox_daily_reminder';
  static const String channelName = 'Daily Puzzle Reminders';
  static const String channelDescription =
      'Friendly offline reminders for daily puzzle challenges and brain workouts.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  void Function(String? payload)? _onTapped;

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize({void Function(String? payload)? onNotificationTapped}) async {
    if (_initialized) return;
    _onTapped = onNotificationTapped;

    // Timezone setup
    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      debugPrint('[NotificationService] Local timezone detected: ${timezoneInfo.identifier}');
    } catch (e) {
      debugPrint('[NotificationService] Error initializing local timezone: $e. Falling back to UTC.');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[NotificationService] Notification tapped: ${response.payload}');
        if (_onTapped != null) {
          _onTapped!(response.payload);
        }
      },
    );

    // Create channel explicitly on Android
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.defaultImportance,
          ),
        );
        debugPrint('[NotificationService] Android notification channel initialized: $channelId');
      }
    }

    // Check if launched from notification
    final NotificationAppLaunchDetails? launchDetails =
        await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      if (_onTapped != null) {
        _onTapped!(launchDetails.notificationResponse!.payload);
      }
    }

    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestNotificationsPermission();
          return granted ?? false;
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final enabled = await androidPlugin.areNotificationsEnabled();
          return enabled ?? false;
        }
      } else if (Platform.isIOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          final settings = await iosPlugin.checkPermissions();
          return settings?.isEnabled ?? false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  @override
  Future<void> scheduleDailyReminder({required TimeOfDay time}) async {
    // Cancel existing reminder first to guarantee idempotency and avoid duplicates
    await cancelDailyReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final dayOfYear = scheduledDate.difference(DateTime(scheduledDate.year, 1, 1)).inDays + 1;
    final content = NotificationCatalog.getMessageForDay(scheduledDate.year * 366 + dayOfYear);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    debugPrint('[NotificationService] Scheduling daily reminder for: $scheduledDate (ID: $dailyReminderNotificationId, payload: ${content.gameId})');

    try {
      await _plugin.zonedSchedule(
        id: dailyReminderNotificationId,
        title: content.title,
        body: content.body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: content.gameId ?? 'home',
      );
      debugPrint('[NotificationService] Daily reminder successfully scheduled.');
    } catch (e, stack) {
      debugPrint('[NotificationService] Failed to schedule daily reminder: $e\n$stack');
      rethrow;
    }
  }

  @override
  Future<void> cancelDailyReminder() async {
    debugPrint('[NotificationService] Canceling daily reminder with ID: $dailyReminderNotificationId');
    await _plugin.cancel(id: dailyReminderNotificationId);
  }

  @override
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    debugPrint('[NotificationService] Delivering immediate test notification (ID: $testNotificationId)');
    await _plugin.show(
      id: testNotificationId,
      title: 'Puzzlebox Test Notification 🧩',
      body: 'Notifications are working perfectly on this device! Tap to open.',
      notificationDetails: notificationDetails,
      payload: 'home',
    );
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }
}
