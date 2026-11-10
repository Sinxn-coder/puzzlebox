import 'package:chess/chess.dart' as chess_lib;

/// Small exhaustive search for short forced checkmates.
///
/// Used to verify puzzles and to judge the player's move: any move that keeps
/// a forced mate on the board is correct, not just the one written in the
/// puzzle data.
abstract final class MateSolver {
  /// True when the side to move can force checkmate within [moves] moves.
  static bool canForceMate(chess_lib.Chess game, int moves) {
    if (moves <= 0) return false;
    for (final move in game.generate_moves()) {
      game.make_move(move);
      final wins = game.in_checkmate ||
          (moves > 1 && defenderIsLost(game, moves - 1));
      game.undo_move();
      if (wins) return true;
    }
    return false;
  }

  /// True when every reply of the side to move still allows the attacker to
  /// mate within [moves] moves. Stalemate or no legal reply counts as a save.
  static bool defenderIsLost(chess_lib.Chess game, int moves) {
    final replies = game.generate_moves();
    if (replies.isEmpty) return false;
    for (final reply in replies) {
      game.make_move(reply);
      final lost = canForceMate(game, moves);
      game.undo_move();
      if (!lost) return false;
    }
    return true;
  }

  /// Whether the move just played (by the attacker) keeps a forced mate with
  /// [remaining] attacker moves left after it.
  static bool moveKeepsMate(chess_lib.Chess gameAfterMove, int remaining) {
    if (gameAfterMove.in_checkmate) return true;
    if (remaining <= 0) return false;
    return defenderIsLost(gameAfterMove, remaining);
  }

  /// Every first move that forces mate in exactly [moves] (or sooner).
  static List<chess_lib.Move> keyMoves(chess_lib.Chess game, int moves) {
    final keys = <chess_lib.Move>[];
    for (final move in game.generate_moves()) {
      game.make_move(move);
      final wins = game.in_checkmate ||
          (moves > 1 && defenderIsLost(game, moves - 1));
      game.undo_move();
      if (wins) keys.add(move);
    }
    return keys;
  }

  /// The defender's most stubborn reply: one that does not allow a faster
  /// mate than necessary. Falls back to the first legal reply.
  static chess_lib.Move? stubbornReply(chess_lib.Chess game, int attackerMovesLeft) {
    final replies = game.generate_moves();
    if (replies.isEmpty) return null;
    if (attackerMovesLeft <= 1) return replies.first;
    for (final reply in replies) {
      game.make_move(reply);
      final quick = canForceMate(game, attackerMovesLeft - 1);
      game.undo_move();
      if (!quick) return reply;
    }
    return replies.first;
  }
}
