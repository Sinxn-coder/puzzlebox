class ChessPuzzle {
  final String id;
  final String title;
  final String fen;
  final List<String> solutionMoves; // main line in SAN, e.g. ['Qxf7#']

  /// Number of moves the solver has to force mate in.
  final int mateIn;
  final String description;
  final String difficulty;
  final String hint;

  const ChessPuzzle({
    required this.id,
    required this.title,
    required this.fen,
    required this.solutionMoves,
    this.mateIn = 1,
    required this.description,
    required this.difficulty,
    required this.hint,
  });
}
