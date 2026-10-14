import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzlebox/core/providers/settings_provider.dart';
import 'package:puzzlebox/core/theme/app_theme.dart';
import 'package:puzzlebox/core/widgets/app_scaffold.dart';
import 'package:puzzlebox/core/widgets/game_mode_toggle.dart';
import 'package:puzzlebox/screens/app_shell.dart';
import 'package:puzzlebox/screens/home_screen.dart';
import 'package:puzzlebox/screens/unified_stats_screen.dart';
import 'package:puzzlebox/screens/settings_screen.dart';
import 'package:puzzlebox/screens/about_screen.dart';
import 'package:puzzlebox/games/daily_five/logic/word_list.dart';
import 'package:puzzlebox/games/daily_five/widgets/daily_five_screen.dart';
import 'package:puzzlebox/games/connections/connections_screen.dart';
import 'package:puzzlebox/games/spelling_bee/spelling_bee_screen.dart';
import 'package:puzzlebox/games/crossword/crossword_screen.dart';
import 'package:puzzlebox/games/mini_crossword/mini_crossword_screen.dart';
import 'package:puzzlebox/games/sudoku/sudoku_screen.dart';
import 'package:puzzlebox/games/strands/strands_screen.dart';
import 'package:puzzlebox/games/pips/pips_screen.dart';
import 'package:puzzlebox/games/tiles/tiles_screen.dart';
import 'package:puzzlebox/games/letter_boxed/letter_boxed_screen.dart';
import 'package:puzzlebox/games/vertex/vertex_screen.dart';
import 'package:puzzlebox/games/chess/chess_screen.dart';
import 'package:puzzlebox/games/nonogram/nonogram_screen.dart';
import 'package:puzzlebox/games/binary/binary_screen.dart';
import 'package:puzzlebox/games/cages/cages_screen.dart';
import 'package:puzzlebox/games/chess/widgets/pawn_promotion_dialog.dart';
import 'package:puzzlebox/games/daily_five/widgets/result_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await WordList.init();
  });

  final testScreens = <String, Widget>{
    'app_shell': const AppShell(),
    'home': const Scaffold(body: HomeScreen()),
    'unified_stats': const Scaffold(body: UnifiedStatsScreen()),
    'settings': const Scaffold(body: SettingsScreen()),
    'about': const Scaffold(body: AboutScreen()),
    'daily_five': const DailyFiveScreen(),
    'connections': const ConnectionsScreen(),
    'spelling_bee': const SpellingBeeScreen(),
    'crossword': const CrosswordScreen(),
    'mini_crossword': const MiniCrosswordScreen(),
    'sudoku': const SudokuScreen(),
    'strands': const StrandsScreen(),
    'pips': const PipsScreen(),
    'tiles': const TilesScreen(),
    'letter_boxed': const LetterBoxedScreen(),
    'vertex': const VertexScreen(),
    'chess': const ChessScreen(),
    'nonogram': const NonogramScreen(),
    'binary': const BinaryScreen(),
    'cages': const CagesScreen(),
  };

  final testConfigurations = [
    (const Size(320, 568), 1.0, '320x568_scale1.0'),
    (const Size(320, 568), 1.3, '320x568_scale1.3'),
    (const Size(360, 640), 1.0, '360x640_scale1.0'),
    (const Size(360, 640), 1.3, '360x640_scale1.3'),
    (const Size(360, 640), 1.5, '360x640_scale1.5'),
  ];

  for (final (size, scale, label) in testConfigurations) {
    for (final entry in testScreens.entries) {
      testWidgets('${entry.key} on $label', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: child!,
                );
              },
              home: entry.value,
            ),
          ),
        );

        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Info button GameRulesSheet opens cleanly on small screen without overflow and dismisses', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();
    // Mark as seen so first-launch dialog doesn't appear
    await prefs.setBool('has_seen_rules_Chess', true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.4),
              ),
              child: child!,
            );
          },
          home: const AppScaffold(
            title: 'Chess',
            showInfoAction: true,
            body: Center(child: Text('Game Body')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify info button is present
    final infoButton = find.byIcon(Icons.info_outline_rounded);
    expect(infoButton, findsOneWidget);

    // Tap info button to open bottom sheet
    await tester.tap(infoButton);
    await tester.pumpAndSettle();

    // GameRulesSheet should be displayed
    expect(find.byType(GameRulesSheet), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);

    // "Got it, let's play!" button should be visible on-screen
    final gotItButton = find.text("Got it, let's play!");
    expect(gotItButton, findsOneWidget);

    // Tap "Got it, let's play!"
    await tester.tap(gotItButton);
    await tester.pumpAndSettle();

    // Sheet should be dismissed
    expect(find.byType(GameRulesSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SettingsSheet opens cleanly on small screen without overflow and dismisses', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.4),
              ),
              child: child!,
            );
          },
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap settings button on home screen
    final settingsButton = find.byIcon(Icons.tune_rounded);
    expect(settingsButton, findsOneWidget);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // SettingsSheet should be displayed
    expect(find.byType(SettingsSheet), findsOneWidget);
    expect(find.text('Neo Customization'), findsOneWidget);

    // Tap "Done" button
    final doneButton = find.text('Done');
    expect(doneButton, findsOneWidget);
    await tester.tap(doneButton);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PawnPromotionDialog opens and renders on small screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? selectedPiece;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.4),
            ),
            child: child!,
          );
        },
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selectedPiece = await PawnPromotionDialog.show(context, true);
            },
            child: const Text('Open Promotion'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Promotion'));
    await tester.pumpAndSettle();

    expect(find.byType(PawnPromotionDialog), findsOneWidget);
    expect(find.text('Queen'), findsOneWidget);
    expect(find.text('Knight'), findsOneWidget);

    await tester.tap(find.text('Queen'));
    await tester.pumpAndSettle();

    expect(selectedPiece, 'q');
    expect(find.byType(PawnPromotionDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ResultModal renders on small screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.4),
              ),
              child: child!,
            );
          },
          home: const Scaffold(
            body: SingleChildScrollView(
              child: ResultModal(mode: GameMode.practice),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ResultModal), findsOneWidget);
    expect(find.text('Played'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}


