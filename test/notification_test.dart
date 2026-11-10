import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzlebox/core/providers/notification_settings_provider.dart';
import 'package:puzzlebox/core/providers/settings_provider.dart';
import 'package:puzzlebox/core/routing/game_router.dart';
import 'package:puzzlebox/core/services/notification_content.dart';
import 'package:puzzlebox/core/services/notification_service.dart';
import 'package:puzzlebox/screens/settings_screen.dart';
import 'package:puzzlebox/screens/widgets/notification_permission_sheet.dart';

class MockNotificationService implements NotificationService {
  bool hasPermissionResult = true;
  bool requestPermissionResult = true;
  int scheduleCount = 0;
  int cancelCount = 0;
  TimeOfDay? lastScheduledTime;
  void Function(String? payload)? tappedCallback;

  @override
  Future<void> initialize({void Function(String? payload)? onNotificationTapped}) async {
    tappedCallback = onNotificationTapped;
  }

  @override
  Future<bool> hasPermission() async => hasPermissionResult;

  @override
  Future<bool> requestPermission() async => requestPermissionResult;

  @override
  Future<void> scheduleDailyReminder({required TimeOfDay time}) async {
    scheduleCount++;
    lastScheduledTime = time;
  }

  @override
  Future<void> cancelDailyReminder() async {
    cancelCount++;
  }

  @override
  Future<void> showTestNotification() async {}

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNotificationService mockService;

  setUp(() {
    mockService = MockNotificationService();
    SharedPreferences.setMockInitialValues({});
  });

  group('Notification Catalog Tests', () {
    test('NotificationCatalog provides varied messages across days', () {
      expect(NotificationCatalog.messages.length, greaterThanOrEqualTo(15));
      final day1 = NotificationCatalog.getMessageForDay(1);
      final day2 = NotificationCatalog.getMessageForDay(2);
      expect(day1.title, isNotEmpty);
      expect(day2.title, isNotEmpty);
      expect(day1.title, isNot(equals(day2.title)));
    });

    test('NotificationCatalog maps to known games properly', () {
      final sudokuMsg = NotificationCatalog.messages.firstWhere((m) => m.gameId == 'sudoku');
      expect(sudokuMsg.title, contains('Sudoku'));
      final gameScreen = GameRouter.getScreenForGameId('sudoku');
      expect(gameScreen, isNotNull);
    });
  });

  group('NotificationSettingsNotifier State & Persistence', () {
    test('Defaults: notifications disabled, 9:00 AM, prompt unhandled', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(mockService),
        ],
      );

      final state = container.read(notificationSettingsProvider);
      expect(state.enabled, isFalse);
      expect(state.reminderTime, const TimeOfDay(hour: 9, minute: 0));
      expect(state.promptHandled, isFalse);
    });

    test('Enabling schedules notification and persists preference', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(mockService),
        ],
      );

      final notifier = container.read(notificationSettingsProvider.notifier);
      final success = await notifier.setEnabled(true);

      expect(success, isTrue);
      expect(container.read(notificationSettingsProvider).enabled, isTrue);
      expect(mockService.scheduleCount, 1);
      expect(mockService.lastScheduledTime, const TimeOfDay(hour: 9, minute: 0));
      expect(prefs.getBool('settings_notifications_enabled'), isTrue);
    });

    test('Disabling cancels notification and updates persistence', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(mockService),
        ],
      );

      final notifier = container.read(notificationSettingsProvider.notifier);
      await notifier.setEnabled(true);
      await notifier.setEnabled(false);

      expect(container.read(notificationSettingsProvider).enabled, isFalse);
      expect(mockService.cancelCount, 1);
      expect(prefs.getBool('settings_notifications_enabled'), isFalse);
    });

    test('Permission denied prevents enabling and does not schedule', () async {
      mockService.hasPermissionResult = false;
      mockService.requestPermissionResult = false;

      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(mockService),
        ],
      );

      final notifier = container.read(notificationSettingsProvider.notifier);
      final success = await notifier.setEnabled(true);

      expect(success, isFalse);
      expect(container.read(notificationSettingsProvider).enabled, isFalse);
      expect(mockService.scheduleCount, 0);
      expect(prefs.getBool('settings_notifications_enabled'), isFalse);
    });

    test('Changing reminder time updates schedule without duplicates', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(mockService),
        ],
      );

      final notifier = container.read(notificationSettingsProvider.notifier);
      await notifier.setEnabled(true);
      expect(mockService.scheduleCount, 1);

      await notifier.setReminderTime(const TimeOfDay(hour: 20, minute: 30));
      expect(container.read(notificationSettingsProvider).reminderTime, const TimeOfDay(hour: 20, minute: 30));
      expect(mockService.scheduleCount, 2);
      expect(mockService.lastScheduledTime, const TimeOfDay(hour: 20, minute: 30));
      expect(prefs.getInt('settings_notification_hour'), 20);
      expect(prefs.getInt('settings_notification_minute'), 30);
    });
  });

  group('First-launch Prompt & Settings UI Widgets', () {
    testWidgets('NotificationPermissionSheet enables reminders and marks prompt handled', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(mockService),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationPermissionSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Mindful Reminders'), findsOneWidget);
      expect(find.text('Enable Reminders'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      await tester.tap(find.text('Enable Reminders'));
      await tester.pumpAndSettle();

      expect(container.read(notificationSettingsProvider).enabled, isTrue);
      expect(container.read(notificationSettingsProvider).promptHandled, isTrue);
    });

    testWidgets('NotificationPermissionSheet skip marks prompt handled without enabling', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(mockService),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationPermissionSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      expect(container.read(notificationSettingsProvider).enabled, isFalse);
      expect(container.read(notificationSettingsProvider).promptHandled, isTrue);
    });

    testWidgets('SettingsScreen displays notification toggle and reminder time selector', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationServiceProvider.overrideWithValue(mockService),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to ensure bottom section is in view
      await tester.scrollUntilVisible(
        find.text('NOTIFICATIONS & REMINDERS'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOTIFICATIONS & REMINDERS'), findsOneWidget);
      expect(find.text('Daily Puzzle Reminders'), findsOneWidget);

      // Toggle ON
      await tester.tap(find.text('Daily Puzzle Reminders'));
      await tester.pumpAndSettle();

      expect(container.read(notificationSettingsProvider).enabled, isTrue);
      expect(find.text('Reminder Time'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
    });
  });

  group('GameRouter Notification Payload Navigation', () {
    test('GameRouter returns correct screen for all supported games', () {
      final games = [
        'chess',
        'sudoku',
        'daily_five',
        'connections',
        'mini_crossword',
        'spelling_bee',
        'crossword',
        'strands',
        'pips',
        'tiles',
        'letter_boxed',
        'vertex',
        'nonogram',
        'binary',
        'cages',
      ];
      for (final g in games) {
        expect(GameRouter.getScreenForGameId(g), isNotNull, reason: 'Failed for game: $g');
      }
      expect(GameRouter.getScreenForGameId('invalid_game'), isNull);
    });
  });
}
