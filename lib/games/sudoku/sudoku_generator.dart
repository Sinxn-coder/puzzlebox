import 'dart:math';
import '../../core/services/puzzle_progression.dart';
import 'sudoku_logic.dart';

class SudokuPuzzle {
  final List<int> givens;
  final List<int> solution;
  const SudokuPuzzle(this.givens, this.solution);
}

List<int> candidates(List<int> grid, int cell) {
  final row = cell ~/ 9, col = cell % 9;
  final used = <int>{};
  for (var i = 0; i < 9; i++) {
    used.add(grid[row * 9 + i]);
    used.add(grid[i * 9 + col]);
    used.add(grid[(row ~/ 3 * 3 + i ~/ 3) * 9 + col ~/ 3 * 3 + i % 3]);
  }
  return [
    for (var n = 1; n <= 9; n++)
      if (!used.contains(n)) n,
  ];
}

int countSudokuSolutions(List<int> source, {int limit = 2}) {
  if (source.length != 81 || source.any((n) => n < 0 || n > 9)) return 0;
  final grid = List<int>.from(source);
  for (var i = 0; i < 81; i++) {
    final value = grid[i];
    if (value == 0) continue;
    grid[i] = 0;
    final valid = candidates(grid, i).contains(value);
    grid[i] = value;
    if (!valid) return 0;
  }
  int solve() {
    var cell = -1;
    var options = <int>[];
    for (var i = 0; i < 81; i++) {
      if (grid[i] != 0) continue;
      final c = candidates(grid, i);
      if (c.isEmpty) return 0;
      if (cell == -1 || c.length < options.length) {
        cell = i;
        options = c;
      }
      if (c.length == 1) break;
    }
    if (cell == -1) return 1;
    var count = 0;
    for (final n in options) {
      grid[cell] = n;
      count += solve();
      if (count >= limit) break;
    }
    grid[cell] = 0;
    return count;
  }

  return solve();
}

class SudokuGenerator implements PuzzleGenerator<SudokuPuzzle> {
  /// Technique level each difficulty must require, and the clue floor that
  /// keeps Easy boards friendly.
  static const _tiers = {
    PuzzleDifficulty.easy: SudokuTier.singles,
    PuzzleDifficulty.medium: SudokuTier.intermediate,
    PuzzleDifficulty.hard: SudokuTier.advanced,
  };
  static const _minClues = {
    PuzzleDifficulty.easy: 36,
    PuzzleDifficulty.medium: 27,
    PuzzleDifficulty.hard: 22,
  };

  @override
  SudokuPuzzle generate(PuzzleRequest request) {
    final rand = Random(request.seed);
    final target = _tiers[request.difficulty]!;
    final floor = _minClues[request.difficulty]!;
    SudokuPuzzle? fallback;
    var fallbackTier = -1;

    for (var attempt = 0; attempt < 40; attempt++) {
      final solution = _randomSolution(rand);
      final grid = List<int>.from(solution);
      // Remove symmetric pairs, like hand-made puzzles, while the puzzle stays
      // solvable by logic no harder than the target level.
      final order = List.generate(41, (i) => i)..shuffle(rand);
      var clues = 81;
      for (final cell in order) {
        if (clues <= floor) break;
        final mirror = 80 - cell;
        final a = grid[cell], b = grid[mirror];
        grid[cell] = 0;
        grid[mirror] = 0;
        final tier = gradeSudoku(grid);
        if (tier == null || tier.index > target.index) {
          grid[cell] = a;
          grid[mirror] = b;
        } else {
          clues -= cell == mirror ? 1 : 2;
        }
      }
      if (target == SudokuTier.advanced) {
        // Hard boards: keep thinning single cells to reach a tougher core.
        final singles = List.generate(81, (i) => i)..shuffle(rand);
        for (final cell in singles) {
          if (clues <= floor || grid[cell] == 0) continue;
          final old = grid[cell];
          grid[cell] = 0;
          if (gradeSudoku(grid) == null) {
            grid[cell] = old;
          } else {
            clues--;
          }
        }
      }
      final tier = gradeSudoku(grid);
      if (tier == target) return SudokuPuzzle(grid, solution);
      if (tier != null && tier.index > fallbackTier) {
        fallbackTier = tier.index;
        fallback = SudokuPuzzle(List<int>.from(grid), solution);
      }
    }
    // Extremely rare: return the hardest logic-solvable board found.
    return fallback!;
  }

  static List<int> _randomSolution(Random rand) {
    final grid = List<int>.filled(81, 0);
    bool fill(int cell) {
      if (cell == 81) return true;
      final options = candidates(grid, cell)..shuffle(rand);
      for (final n in options) {
        grid[cell] = n;
        if (fill(cell + 1)) return true;
      }
      grid[cell] = 0;
      return false;
    }

    fill(0);
    return grid;
  }

  @override
  bool validate(SudokuPuzzle puzzle) =>
      puzzle.givens.length == 81 &&
      countSudokuSolutions(puzzle.givens) == 1 &&
      gradeSudoku(puzzle.givens) != null &&
      List.generate(81, (i) => i).every(
        (i) =>
            puzzle.solution[i] >= 1 &&
            puzzle.solution[i] <= 9 &&
            (puzzle.givens[i] == 0 || puzzle.givens[i] == puzzle.solution[i]),
      );
}

SudokuPuzzle generateSudoku(PuzzleRequest request) =>
    SudokuGenerator().generate(request);
