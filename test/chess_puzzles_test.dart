import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlebox/games/chess/logic/chess_puzzles_data.dart';
import 'package:puzzlebox/games/chess/logic/mate_solver.dart';

void main() {
  test('every chess puzzle is a sound, exact, unique forced mate', () {
    final fens = <String>{};
    for (final puzzle in ChessPuzzlesData.puzzles) {
      final reason = '${puzzle.id} ${puzzle.fen}';
      expect(fens.add(puzzle.fen), isTrue, reason: 'duplicate $reason');
      final game = chess_lib.Chess();
      expect(game.load(puzzle.fen), isTrue, reason: reason);
      expect(game.in_check, isFalse, reason: reason);

      // Exact length: mate in N exists, but not in N-1.
      expect(MateSolver.canForceMate(game, puzzle.mateIn), isTrue, reason: reason);
      if (puzzle.mateIn > 1) {
        expect(
          MateSolver.canForceMate(game, puzzle.mateIn - 1),
          isFalse,
          reason: reason,
        );
      }
      // Unique key move, and it is the first move of the stored line.
      final keys = MateSolver.keyMoves(game, puzzle.mateIn);
      expect(keys.length, 1, reason: reason);
      expect(game.move_to_san(keys.first), puzzle.solutionMoves.first, reason: reason);

      // The stored main line is legal and ends in checkmate.
      for (final san in puzzle.solutionMoves) {
        expect(game.move(san), isTrue, reason: '$reason $san');
      }
      expect(game.in_checkmate, isTrue, reason: reason);
      expect(puzzle.difficulty, puzzle.mateIn == 1 ? 'Easy' : isNot('Easy'));
    }
    expect(ChessPuzzlesData.puzzles.length, greaterThanOrEqualTo(100));
  });

  test('a wrong first move is rejected and any mating reply is accepted', () {
    final puzzle = ChessPuzzlesData.puzzles.firstWhere((p) => p.mateIn == 2);
    final game = chess_lib.Chess.fromFEN(puzzle.fen);
    final key = MateSolver.keyMoves(game, 2).first;
    final wrong = game.generate_moves().firstWhere(
      (m) => m.from != key.from || m.to != key.to,
    );
    game.make_move(wrong);
    expect(MateSolver.moveKeepsMate(game, 1), isFalse);
    game.undo_move();
    game.make_move(key);
    expect(MateSolver.moveKeepsMate(game, 1), isTrue);
    final reply = MateSolver.stubbornReply(game, 1)!;
    game.make_move(reply);
    expect(MateSolver.keyMoves(game, 1), isNotEmpty);
  });

  test('mirrored puzzles keep Black to move', () {
    final half = ChessPuzzlesData.puzzles.length ~/ 2;
    expect(ChessPuzzlesData.puzzles[half].fen.split(' ')[1], 'b');
    expect(ChessPuzzlesData.mirrorSan('Qxa6#'), 'Qxa3#');
  });
}
