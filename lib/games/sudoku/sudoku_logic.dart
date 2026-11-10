/// Human-style Sudoku solver used to grade puzzles by the techniques they
/// require, the way hand-made puzzles are graded:
///
/// * [SudokuTier.singles]      — naked and hidden singles only.
/// * [SudokuTier.intermediate] — also pairs and pointing / claiming.
/// * [SudokuTier.advanced]     — also triples, X-Wing and XY-Wing.
///
/// A puzzle the solver cannot finish needs guessing and is rejected, so every
/// generated puzzle can be solved by logic alone.
enum SudokuTier { singles, intermediate, advanced }

final List<List<int>> _units = [
  for (var r = 0; r < 9; r++) [for (var c = 0; c < 9; c++) r * 9 + c],
  for (var c = 0; c < 9; c++) [for (var r = 0; r < 9; r++) r * 9 + c],
  for (var b = 0; b < 9; b++)
    [
      for (var i = 0; i < 9; i++)
        (b ~/ 3 * 3 + i ~/ 3) * 9 + b % 3 * 3 + i % 3,
    ],
];

final List<List<int>> _peers = [
  for (var cell = 0; cell < 81; cell++)
    {
      for (final unit in _units)
        if (unit.contains(cell)) ...unit,
    }.where((p) => p != cell).toList(),
];

int _bit(int digit) => 1 << digit;
int _count(int mask) {
  var n = 0;
  for (var m = mask; m != 0; m &= m - 1) {
    n++;
  }
  return n;
}

int _lowestDigit(int mask) {
  for (var d = 1; d <= 9; d++) {
    if (mask & _bit(d) != 0) return d;
  }
  return 0;
}

class _State {
  final List<int> grid;
  final List<int> cand;
  _State(List<int> givens)
    : grid = List<int>.from(givens),
      cand = List<int>.filled(81, 0) {
    for (var i = 0; i < 81; i++) {
      if (grid[i] != 0) continue;
      var mask = 0x3FE;
      for (final p in _peers[i]) {
        if (grid[p] != 0) mask &= ~_bit(grid[p]);
      }
      cand[i] = mask;
    }
  }

  bool get solved => !grid.contains(0);

  /// False when a contradiction appears (only possible for invalid input).
  bool place(int cell, int digit) {
    grid[cell] = digit;
    cand[cell] = 0;
    for (final p in _peers[cell]) {
      if (grid[p] == digit) return false;
      cand[p] &= ~_bit(digit);
    }
    return true;
  }

  bool eliminate(int cell, int mask) {
    if (grid[cell] != 0 || cand[cell] & mask == 0) return false;
    cand[cell] &= ~mask;
    return true;
  }
}

/// Returns the hardest tier needed to solve [givens] by logic, or null when
/// the puzzle cannot be finished without guessing (or is invalid).
SudokuTier? gradeSudoku(List<int> givens) {
  final s = _State(givens);
  var tier = SudokuTier.singles;
  while (!s.solved) {
    final single = _applySingles(s);
    if (single == null) return null; // contradiction
    if (single) continue;
    if (_intermediate(s)) {
      if (tier.index < SudokuTier.intermediate.index) {
        tier = SudokuTier.intermediate;
      }
      continue;
    }
    if (_advanced(s)) {
      tier = SudokuTier.advanced;
      continue;
    }
    return null;
  }
  return tier;
}

/// Places one naked or hidden single. Returns true if placed, false if none
/// found, null on contradiction.
bool? _applySingles(_State s) {
  for (var i = 0; i < 81; i++) {
    if (s.grid[i] != 0) continue;
    if (s.cand[i] == 0) return null;
    if (_count(s.cand[i]) == 1) {
      return s.place(i, _lowestDigit(s.cand[i])) ? true : null;
    }
  }
  for (final unit in _units) {
    for (var d = 1; d <= 9; d++) {
      var spot = -1;
      var spots = 0;
      var present = false;
      for (final c in unit) {
        if (s.grid[c] == d) present = true;
        if (s.grid[c] == 0 && s.cand[c] & _bit(d) != 0) {
          spot = c;
          spots++;
        }
      }
      if (present) continue;
      if (spots == 0) return null;
      if (spots == 1) return s.place(spot, d) ? true : null;
    }
  }
  return false;
}

bool _intermediate(_State s) =>
    _nakedSubsets(s, 2) || _hiddenPairs(s) || _pointingAndClaiming(s);

bool _advanced(_State s) => _nakedSubsets(s, 3) || _xWing(s) || _xyWing(s);

/// Naked pairs/triples: N cells in a unit sharing only N candidates.
bool _nakedSubsets(_State s, int size) {
  var changed = false;
  for (final unit in _units) {
    final open = [
      for (final c in unit)
        if (s.grid[c] == 0 && _count(s.cand[c]) <= size) c,
    ];
    void search(int start, List<int> chosen, int mask) {
      if (chosen.length == size) {
        if (_count(mask) != size) return;
        for (final c in unit) {
          if (s.grid[c] == 0 && !chosen.contains(c)) {
            changed = s.eliminate(c, mask) || changed;
          }
        }
        return;
      }
      for (var i = start; i < open.length; i++) {
        final next = mask | s.cand[open[i]];
        if (_count(next) > size) continue;
        search(i + 1, [...chosen, open[i]], next);
      }
    }

    search(0, [], 0);
    if (changed) return true;
  }
  return false;
}

/// Hidden pairs: two digits confined to the same two cells of a unit.
bool _hiddenPairs(_State s) {
  for (final unit in _units) {
    final places = <int, List<int>>{};
    for (var d = 1; d <= 9; d++) {
      final cells = [
        for (final c in unit)
          if (s.grid[c] == 0 && s.cand[c] & _bit(d) != 0) c,
      ];
      if (cells.length == 2) places[d] = cells;
    }
    final digits = places.keys.toList();
    for (var i = 0; i < digits.length; i++) {
      for (var j = i + 1; j < digits.length; j++) {
        final a = places[digits[i]]!, b = places[digits[j]]!;
        if (a[0] != b[0] || a[1] != b[1]) continue;
        final keep = _bit(digits[i]) | _bit(digits[j]);
        var changed = false;
        for (final c in a) {
          changed = s.eliminate(c, ~keep & 0x3FE) || changed;
        }
        if (changed) return true;
      }
    }
  }
  return false;
}

/// Pointing (box → line) and claiming (line → box) eliminations.
bool _pointingAndClaiming(_State s) {
  for (var d = 1; d <= 9; d++) {
    final bit = _bit(d);
    for (var b = 18; b < 27; b++) {
      final cells = [
        for (final c in _units[b])
          if (s.grid[c] == 0 && s.cand[c] & bit != 0) c,
      ];
      if (cells.length < 2) continue;
      for (final lineOf in [(int c) => c ~/ 9, (int c) => 9 + c % 9]) {
        final line = lineOf(cells.first);
        if (!cells.every((c) => lineOf(c) == line)) continue;
        var changed = false;
        for (final c in _units[line]) {
          if (!_units[b].contains(c)) changed = s.eliminate(c, bit) || changed;
        }
        if (changed) return true;
      }
    }
    for (var line = 0; line < 18; line++) {
      final cells = [
        for (final c in _units[line])
          if (s.grid[c] == 0 && s.cand[c] & bit != 0) c,
      ];
      if (cells.length < 2) continue;
      int boxOf(int c) => 18 + c ~/ 27 * 3 + c % 9 ~/ 3;
      final box = boxOf(cells.first);
      if (!cells.every((c) => boxOf(c) == box)) continue;
      var changed = false;
      for (final c in _units[box]) {
        if (!_units[line].contains(c)) changed = s.eliminate(c, bit) || changed;
      }
      if (changed) return true;
    }
  }
  return false;
}

/// X-Wing on rows and on columns.
bool _xWing(_State s) {
  for (var d = 1; d <= 9; d++) {
    final bit = _bit(d);
    for (final rowsFirst in [true, false]) {
      int at(int line, int i) => rowsFirst ? line * 9 + i : i * 9 + line;
      final pairs = <int, List<int>>{};
      for (var line = 0; line < 9; line++) {
        final spots = [
          for (var i = 0; i < 9; i++)
            if (s.grid[at(line, i)] == 0 && s.cand[at(line, i)] & bit != 0) i,
        ];
        if (spots.length == 2) pairs[line] = spots;
      }
      final lines = pairs.keys.toList();
      for (var a = 0; a < lines.length; a++) {
        for (var b = a + 1; b < lines.length; b++) {
          final p = pairs[lines[a]]!, q = pairs[lines[b]]!;
          if (p[0] != q[0] || p[1] != q[1]) continue;
          var changed = false;
          for (var other = 0; other < 9; other++) {
            if (other == lines[a] || other == lines[b]) continue;
            for (final i in p) {
              changed = s.eliminate(at(other, i), bit) || changed;
            }
          }
          if (changed) return true;
        }
      }
    }
  }
  return false;
}

/// XY-Wing: pivot {A,B} with wings {A,C} and {B,C} removes C from cells
/// that see both wings.
bool _xyWing(_State s) {
  final bivalue = [
    for (var i = 0; i < 81; i++)
      if (s.grid[i] == 0 && _count(s.cand[i]) == 2) i,
  ];
  for (final pivot in bivalue) {
    final pm = s.cand[pivot];
    final wings = [
      for (final w in bivalue)
        if (w != pivot &&
            _peers[pivot].contains(w) &&
            _count(s.cand[w] & pm) == 1)
          w,
    ];
    for (var i = 0; i < wings.length; i++) {
      for (var j = i + 1; j < wings.length; j++) {
        final a = s.cand[wings[i]], b = s.cand[wings[j]];
        final shared = a & b & ~pm;
        if (_count(shared) != 1 || (a & pm) == (b & pm)) continue;
        if ((a | b) & ~(pm | shared) != 0) continue;
        var changed = false;
        for (final c in _peers[wings[i]]) {
          if (c != pivot && _peers[wings[j]].contains(c)) {
            changed = s.eliminate(c, shared) || changed;
          }
        }
        if (changed) return true;
      }
    }
  }
  return false;
}
