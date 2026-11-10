import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzlebox/core/providers/settings_provider.dart';
import 'package:puzzlebox/core/theme/app_theme.dart';
import 'package:puzzlebox/games/chess/chess_screen.dart';

Future<void> _mount(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({'has_seen_rules_Chess': true});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(theme: AppTheme.light, home: const ChessScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _move(WidgetTester tester, String from, String to) async {
  await tester.tap(find.byKey(ValueKey('chess_square_$from')));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('chess_square_$to')));
  await tester.pump();
}

void main() {
  testWidgets('undo before the AI replies takes back only the player move', (
    tester,
  ) async {
    await _mount(tester);
    final dynamic state = tester.state(find.byType(ChessScreen));
    await _move(tester, 'e2', 'e4');
    // Undo inside the AI's thinking delay.
    await tester.tap(find.byTooltip('Undo Move'));
    await tester.pump();
    expect((state as dynamic).debugFen, startsWith('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w'));
    // The pending AI move must not then play for White on the new board.
    await tester.pump(const Duration(milliseconds: 500));
    expect((state as dynamic).debugFen, startsWith('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w'));
  });

  testWidgets('a new game cancels the pending AI reply', (tester) async {
    await _mount(tester);
    final dynamic state = tester.state(find.byType(ChessScreen));
    await _move(tester, 'd2', 'd4');
    await tester.tap(find.byTooltip('New Game'));
    await tester.pump(const Duration(milliseconds: 500));
    expect((state as dynamic).debugFen, startsWith('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w'));
  });

  testWidgets('after a real reply, undo takes back both moves', (tester) async {
    await _mount(tester);
    final dynamic state = tester.state(find.byType(ChessScreen));
    await _move(tester, 'g1', 'f3');
    await tester.pump(const Duration(milliseconds: 600));
    expect((state as dynamic).debugFen, contains(' w '));
    await tester.tap(find.byTooltip('Undo Move'));
    await tester.pump();
    expect((state as dynamic).debugFen, startsWith('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w'));
  });
}
