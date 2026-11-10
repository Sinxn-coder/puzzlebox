import 'package:flutter/material.dart';
import '../../games/chess/chess_screen.dart';
import '../../games/sudoku/sudoku_screen.dart';
import '../../games/daily_five/widgets/daily_five_screen.dart';
import '../../games/connections/connections_screen.dart';
import '../../games/mini_crossword/mini_crossword_screen.dart';
import '../../games/spelling_bee/spelling_bee_screen.dart';
import '../../games/crossword/crossword_screen.dart';
import '../../games/strands/strands_screen.dart';
import '../../games/pips/pips_screen.dart';
import '../../games/tiles/tiles_screen.dart';
import '../../games/letter_boxed/letter_boxed_screen.dart';
import '../../games/vertex/vertex_screen.dart';
import '../../games/nonogram/nonogram_screen.dart';
import '../../games/binary/binary_screen.dart';
import '../../games/cages/cages_screen.dart';

class GameRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Returns the corresponding game screen if valid, or null.
  static Widget? getScreenForGameId(String gameId) {
    switch (gameId) {
      case 'chess':
        return const ChessScreen();
      case 'sudoku':
        return const SudokuScreen();
      case 'daily_five':
        return const DailyFiveScreen();
      case 'connections':
        return const ConnectionsScreen();
      case 'mini_crossword':
        return const MiniCrosswordScreen();
      case 'spelling_bee':
        return const SpellingBeeScreen();
      case 'crossword':
        return const CrosswordScreen();
      case 'strands':
        return const StrandsScreen();
      case 'pips':
        return const PipsScreen();
      case 'tiles':
        return const TilesScreen();
      case 'letter_boxed':
        return const LetterBoxedScreen();
      case 'vertex':
        return const VertexScreen();
      case 'nonogram':
        return const NonogramScreen();
      case 'binary':
        return const BinaryScreen();
      case 'cages':
        return const CagesScreen();
      default:
        return null;
    }
  }

  /// Safely open a game by ID using the global navigator key.
  static void openGame(String? gameId) {
    if (gameId == null || gameId.isEmpty || gameId == 'home') return;
    final screen = getScreenForGameId(gameId);
    if (screen == null) return;

    final navState = navigatorKey.currentState;
    if (navState != null) {
      navState.push(
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }
}
