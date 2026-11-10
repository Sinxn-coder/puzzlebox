import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/notification_settings_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/routing/game_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/feedback_colors.dart';
import 'core/theme/neo.dart';
import 'games/daily_five/logic/word_list.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Nunito',
    ], await rootBundle.loadString('assets/fonts/Nunito-OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'English word list (dwyl)',
    ], await rootBundle.loadString('assets/words/english-LICENSE.md'));
  });

  // Load word lists before the app starts
  await WordList.init();

  // Initialise SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize notification service safely
  final notificationService = LocalNotificationService();
  try {
    await notificationService.initialize(
      onNotificationTapped: (payload) {
        GameRouter.openGame(payload);
      },
    );
  } catch (e) {
    debugPrint('Error initializing local notifications: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const PuzzleboxApp(),
    ),
  );
}

class PuzzleboxApp extends ConsumerStatefulWidget {
  const PuzzleboxApp({super.key});

  @override
  ConsumerState<PuzzleboxApp> createState() => _PuzzleboxAppState();
}

class _PuzzleboxAppState extends ConsumerState<PuzzleboxApp> {
  (NeoStyle, bool)? _applied;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final style = settings.neoStyle;
    Neo.style = style;
    FeedbackColors.colorblind = settings.colorblindMode;
    final applied = (style, settings.colorblindMode);
    if (_applied != null && _applied != applied) {
      // Outline weights and feedback colours are read statically, so refresh
      // every widget once when they change.
      WidgetsBinding.instance.addPostFrameCallback((_) => Neo.rebuildAll());
    }
    _applied = applied;

    return MaterialApp(
      navigatorKey: GameRouter.navigatorKey,
      title: 'Puzzlebox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light, settings.palette, style: style),
      darkTheme: AppTheme.build(Brightness.dark, settings.palette, style: style),
      themeMode: settings.themeMode,
      builder: (context, child) {
        Neo.dark = Theme.of(context).brightness == Brightness.dark;
        final media = MediaQuery.of(context);
        // Respect larger system text while keeping boards usable; a fixed
        // in-app choice overrides the system value.
        final scaler = settings.textScale > 0
            ? TextScaler.linear(settings.textScale)
            : media.textScaler.clamp(minScaleFactor: .85, maxScaleFactor: 1.4);
        return MediaQuery(
          data: media.copyWith(textScaler: scaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AppShell(),
    );
  }
}
