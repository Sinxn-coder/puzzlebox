import '../models/chess_puzzle.dart';

/// Checkmate puzzles, every one verified by [MateSolver] in
/// test/chess_puzzles_test.dart: the stated mate length is exact, there is no
/// faster mate, and the first move is the only one that forces it.
///
/// Easy = mate in 1, Medium = mate in 2 starting with a check,
/// Hard = mate in 2 starting with a quiet move.
class ChessPuzzlesData {
  /// (FEN with White to move, mate in N, difficulty, main line in SAN).
  static const List<(String, int, String, List<String>)> _whiteToMove = [
    ('4k2b/3ppp2/1r6/8/8/4KN2/1Q6/8 w - - 0 1', 1, 'Easy', ['Qxh8#']),
    ('1k6/2p5/6N1/8/3R4/8/7Q/1N1K3n w - - 0 1', 2, 'Medium', ['Qb2+', 'Kc8', 'Ne7#']),
    ('k7/p7/8/8/5p2/7K/8/Q5R1 w - - 0 1', 2, 'Hard', ['Rb1', 'a6', 'Qxa6#']),
    ('7k/6pp/8/8/8/K7/6qB/2Q3r1 w - - 0 1', 1, 'Easy', ['Qc8#']),
    ('8/1qp1k3/3p4/3Q4/2N5/8/8/K5R1 w - - 0 1', 2, 'Medium', ['Rg7+', 'Kd8', 'Qg8#']),
    ('3rk3/3Np2p/1b2P3/8/8/1KR5/8/8 w - - 0 1', 2, 'Hard', ['Rg3', 'Rxd7', 'Rg8#']),
    ('5k2/2Q3p1/4p3/8/R7/b7/K7/8 w - - 0 1', 1, 'Easy', ['Ra8#']),
    ('Q7/5k1N/5Pp1/8/2P5/8/8/1K6 w - - 0 1', 2, 'Medium', ['Qb7+', 'Ke8', 'Qe7#']),
    ('3k4/3p3N/8/8/B4p2/5Q2/8/4K3 w - - 0 1', 2, 'Hard', ['Qb7', 'Ke8', 'Qxd7#']),
    ('k7/pp6/1P6/2N5/3R4/4K3/8/3b4 w - - 0 1', 1, 'Easy', ['Rd8#']),
    ('8/7k/3N3p/1Q4p1/1R6/4K3/8/8 w - - 0 1', 2, 'Medium', ['Qd7+', 'Kg8', 'Rb8#']),
    ('5k2/4p1p1/8/8/6B1/4K3/1Q6/8 w - - 0 1', 2, 'Hard', ['Be6', 'Ke8', 'Qb8#']),
    ('3k4/3p4/4Q2R/8/6Bb/8/6K1/8 w - - 0 1', 1, 'Easy', ['Qxd7#']),
    ('4r1R1/k7/pp6/8/8/8/1Q6/K7 w - - 0 1', 2, 'Medium', ['Qg7+', 'Re7', 'Qxe7#']),
    ('5rk1/5p2/4Q1p1/8/2N5/8/6KR/8 w - - 0 1', 2, 'Hard', ['Qf6', 'Re8', 'Qh8#']),
    ('3N4/k7/p7/1Q6/8/8/2K5/8 w - - 0 1', 1, 'Easy', ['Qb7#']),
    ('4k3/q5R1/5Q2/8/8/8/4K3/b7 w - - 0 1', 2, 'Medium', ['Qe6+', 'Kf8', 'Rg8#']),
    ('4k3/3p1p2/8/8/4P2B/1K5R/5Q2/8 w - - 0 1', 2, 'Hard', ['Qf6', 'Kf8', 'Qh8#']),
    ('7k/q6p/3R4/2B5/6Q1/8/2b5/2K5 w - - 0 1', 1, 'Easy', ['Rd8#']),
    ('8/4k3/3p4/8/5B2/8/2R5/qQ1R2K1 w - - 0 1', 2, 'Medium', ['Rc7+', 'Kd8', 'Qb8#']),
    ('4k3/7R/2P5/8/8/2K5/7B/4n2r w - - 0 1', 2, 'Hard', ['c7', 'Kf8', 'c8=Q#']),
    ('k7/pp6/6R1/4Q3/5bR1/2n4K/8/8 w - - 0 1', 1, 'Easy', ['Rg8#']),
    ('1k6/1p4B1/2b5/8/3R3N/8/3Q4/3K4 w - - 0 1', 2, 'Medium', ['Be5+', 'Kc8', 'Rd8#']),
    ('7k/2B3Rp/8/6N1/1p6/4K3/8/1B6 w - - 0 1', 2, 'Hard', ['Be5', 'h6', 'Rg6#']),
    ('1k6/b1p5/8/8/4B3/8/5n1R/4K3 w - - 0 1', 1, 'Easy', ['Rh8#']),
    ('8/2k5/Qp1p4/8/3P3R/1K6/8/8 w - - 0 1', 2, 'Medium', ['Rh7+', 'Kb8', 'Qb7#']),
    ('7k/6pB/Q3n3/2R5/8/7p/7K/8 w - - 0 1', 2, 'Hard', ['Qxe6', 'Kxh7', 'Rh5#']),
    ('4k3/4p3/7N/8/3Q2B1/8/5b2/2K5 w - - 0 1', 1, 'Easy', ['Qh8#']),
    ('k2n3R/p7/8/8/8/8/8/2K1R3 w - - 0 1', 2, 'Hard', ['Re7', 'Kb8', 'Rxd8#']),
    ('5k2/5p2/1r3P2/8/3b3R/3n3K/8/7R w - - 0 1', 1, 'Easy', ['Rh8#']),
    ('R7/2k5/8/4N3/8/bP2nK2/8/5Q2 w - - 0 1', 2, 'Hard', ['Qa6', 'Bb4', 'Rc8#']),
    ('7k/R2b1Q1p/6p1/8/8/8/1K6/8 w - - 0 1', 1, 'Easy', ['Qf8#']),
    ('2k5/8/1R4b1/8/3Q4/p1K5/3N4/n7 w - - 0 1', 2, 'Hard', ['Qd6', 'Bf7', 'Rb8#']),
    ('k6b/1p6/8/6R1/r1n5/8/8/4K1B1 w - - 0 1', 1, 'Easy', ['Rg8#']),
    ('3k4/8/7R/n7/2Q3p1/3K4/3B4/8 w - - 0 1', 2, 'Hard', ['Qf7', 'Kc8', 'Rh8#']),
    ('5k2/4p1p1/8/4N3/7Q/7K/8/8 w - - 0 1', 1, 'Easy', ['Qh8#']),
    ('2k2N1B/1p6/3Q2n1/8/2P5/8/5K2/8 w - - 0 1', 2, 'Hard', ['Ne6', 'b6', 'Qc7#']),
    ('7k/6pp/8/8/8/K3Q3/1B2P2n/8 w - - 0 1', 1, 'Easy', ['Qe8#']),
    ('5k2/6p1/4R3/8/4B3/4b3/4K3/8 w - - 0 1', 2, 'Hard', ['Bg6', 'Kg8', 'Re8#']),
    ('6k1/2B2pp1/3R4/5bN1/8/8/8/2K5 w - - 0 1', 1, 'Easy', ['Rd8#']),
    ('5N1k/7B/8/8/3n4/7R/P7/7K w - - 0 1', 2, 'Hard', ['Rg3', 'Nb5', 'Rg8#']),
    ('4k3/3ppp2/8/8/8/8/5K1P/6Q1 w - - 0 1', 1, 'Easy', ['Qg8#']),
    ('k7/7Q/N5Pn/8/4p3/8/4K3/8 w - - 0 1', 2, 'Hard', ['Qc7', 'Nf7', 'Qb8#']),
    ('4k3/3pp3/1R2B3/r7/8/4P1K1/8/8 w - - 0 1', 1, 'Easy', ['Rb8#']),
    ('3kr2R/1pRb4/p2q4/8/3Q4/8/5K2/8 w - - 0 1', 2, 'Hard', ['Qxd6', 'Rf8+', 'Rxf8#']),
    ('5b1k/6pp/5B2/5Q2/8/8/2B3K1/8 w - - 0 1', 1, 'Easy', ['Qxh7#']),
    ('5k2/6p1/8/3RQ3/8/8/1n5K/8 w - - 0 1', 2, 'Hard', ['Rd7', 'Kg8', 'Qxg7#']),
    ('7k/2N3pp/8/4b3/8/8/8/Q1R2K2 w - - 0 1', 1, 'Easy', ['Qa8#']),
    ('7k/6pp/7P/B7/8/4b3/6K1/4Q3 w - - 0 1', 2, 'Hard', ['Qc3', 'Kg8', 'Qxg7#']),
    ('k6b/p7/8/8/7N/Q5B1/4K3/8 w - - 0 1', 1, 'Easy', ['Qf3#']),
    ('4k3/4pp2/p4B2/1R4Q1/8/8/2K5/8 w - - 0 1', 2, 'Hard', ['Rb7', 'Kf8', 'Rb8#']),
    ('2k5/4R3/n7/8/7b/8/1Q4K1/8 w - - 0 1', 1, 'Easy', ['Qh8#']),
    ('3k4/4R3/3p4/8/2P5/2p5/1Q4B1/1b4K1 w - - 0 1', 2, 'Hard', ['Qb7', 'd5', 'Qc7#']),
    ('k2N4/pp5n/8/2Q5/8/8/4K3/8 w - - 0 1', 1, 'Easy', ['Qc8#']),
    ('1Bk5/Qp1p4/8/8/8/1p6/6BK/5r1n w - - 0 1', 2, 'Hard', ['Bd6', 'Kd8', 'Qa8#']),
    ('7k/6pp/8/4R3/N7/8/8/2K2N2 w - - 0 1', 1, 'Easy', ['Re8#']),
    ('6k1/N4ppp/8/3R3P/8/8/3K1n2/8 w - - 0 1', 1, 'Easy', ['Rd8#']),
    ('5k2/4ppp1/8/8/8/Q6K/8/1nN5 w - - 0 1', 1, 'Easy', ['Qa8#']),
    ('4k3/4n3/3Q4/8/8/B7/8/5K1b w - - 0 1', 1, 'Easy', ['Qxe7#']),
    ('2k5/2pp4/5qn1/3Q4/7R/p7/3K4/8 w - - 0 1', 1, 'Easy', ['Qa8#']),
    ('2k5/1pp5/3Q4/1N6/2R5/8/1K6/8 w - - 0 1', 1, 'Easy', ['Qxc7#']),
    ('k2q4/p7/pR6/1B6/5b2/7n/8/1K6 w - - 0 1', 1, 'Easy', ['Bc6#']),
  ];

  /// All puzzles: the White-to-move set, then the same ideas mirrored with
  /// Black to move, so the daily cycle is twice as long.
  static final List<ChessPuzzle> puzzles = [
    for (final (i, p) in _whiteToMove.indexed) _build(i, p, mirrored: false),
    for (final (i, p) in _whiteToMove.indexed)
      _build(i + _whiteToMove.length, p, mirrored: true),
  ];

  static ChessPuzzle _build(
    int index,
    (String, int, String, List<String>) data, {
    required bool mirrored,
  }) {
    final (fen, mateIn, difficulty, line) = data;
    final side = mirrored ? 'Black' : 'White';
    final moves = mirrored ? line.map(mirrorSan).toList() : line;
    return ChessPuzzle(
      id: 'mate_${index + 1}',
      title: mateIn == 1 ? 'Mate in One' : 'Mate in Two',
      fen: mirrored ? mirrorFen(fen) : fen,
      solutionMoves: moves,
      mateIn: mateIn,
      description: mateIn == 1
          ? '$side to move. Checkmate in one move.'
          : '$side to move. Force checkmate in two moves.',
      difficulty: difficulty,
      hint: _hint(moves.first, mateIn),
    );
  }

  static String _hint(String key, int mateIn) {
    const names = {'Q': 'queen', 'R': 'rook', 'B': 'bishop', 'N': 'knight', 'K': 'king'};
    final piece = names[key[0]] ?? 'pawn';
    if (mateIn == 1) return 'Your $piece delivers the final blow.';
    if (key.contains('+')) return 'Start with a check from your $piece.';
    return 'A quiet $piece move sets the trap. It does not need to give check.';
  }

  /// Flips the board top-to-bottom and swaps colours.
  static String mirrorFen(String fen) {
    final parts = fen.split(' ');
    final ranks = parts[0].split('/').reversed.map(
      (r) => String.fromCharCodes(
        r.codeUnits.map((c) {
          final ch = String.fromCharCode(c);
          return (ch == ch.toUpperCase() ? ch.toLowerCase() : ch.toUpperCase())
              .codeUnitAt(0);
        }),
      ),
    );
    final turn = parts[1] == 'w' ? 'b' : 'w';
    return '${ranks.join('/')} $turn - - 0 1';
  }

  /// Mirrors the ranks inside a SAN move (e.g. Qxa6# becomes Qxa3#).
  static String mirrorSan(String san) => san.replaceAllMapped(
    RegExp(r'[1-8]'),
    (m) => '${9 - int.parse(m[0]!)}',
  );

  /// Puzzle for a calendar day (Daily Puzzle mode).
  static ChessPuzzle getPuzzleForDate(DateTime date) {
    final index = date.difference(DateTime(2026, 1, 1)).inDays;
    return getPuzzleAtIndex(index < 0 ? 0 : index);
  }

  /// Puzzle by running index; cycles through the verified set.
  static ChessPuzzle getPuzzleAtIndex(int index) =>
      puzzles[(index < 0 ? 0 : index) % puzzles.length];
}
