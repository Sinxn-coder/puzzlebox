import 'package:flutter/material.dart';

/// Static description of one game, shared by Home, Stats and the game top bar.
class GameInfo {
  final String id;
  final String name;
  final String tagline;
  final IconData icon;
  final String category;
  final Color color;

  /// True when the game records a guess count (drives the guess chart).
  final bool tracksGuesses;

  const GameInfo(
    this.id,
    this.name,
    this.tagline,
    this.icon,
    this.category,
    this.color, {
    this.tracksGuesses = false,
  });

  /// Tag shared by the Home card icon and the game screen's title badge.
  String get heroTag => 'game-icon-$id';
}

abstract final class GameCatalog {
  static const categories = ['Words', 'Logic', 'Patterns'];

  static const all = <GameInfo>[
    GameInfo('chess', 'Chess', 'Tactics & vs AI practice',
        Icons.extension_rounded, 'Logic', Color(0xFFFB923C)),
    GameInfo('sudoku', 'Sudoku', 'Classic 9x9 logic placement',
        Icons.apps_rounded, 'Logic', Color(0xFFFACC15)),
    GameInfo('daily_five', 'Daily Five', '6 tries to guess 5-letter word',
        Icons.grid_on_rounded, 'Words', Color(0xFF4ADE80),
        tracksGuesses: true),
    GameInfo('connections', 'Connections', 'Group 4 sets of 4 words',
        Icons.hub_rounded, 'Words', Color(0xFFF43F5E)),
    GameInfo('mini_crossword', 'The Mini', 'Quick daily 5x5 crossword',
        Icons.space_dashboard_rounded, 'Words', Color(0xFF38BDF8)),
    GameInfo('spelling_bee', 'Spelling Bee', 'Spell words with 7 letters',
        Icons.hive_rounded, 'Words', Color(0xFFC084FC)),
    GameInfo('crossword', 'Crossword', 'Full size crossword puzzle',
        Icons.border_all_rounded, 'Words', Color(0xFFFB923C)),
    GameInfo('strands', 'Strands', 'Trace hidden theme words',
        Icons.gesture_rounded, 'Words', Color(0xFF4ADE80)),
    GameInfo('pips', 'Pips', 'Domino sum grid logic', Icons.casino_rounded,
        'Logic', Color(0xFFF43F5E)),
    GameInfo('tiles', 'Tiles', 'Match pattern traits', Icons.layers_rounded,
        'Patterns', Color(0xFFFACC15)),
    GameInfo('letter_boxed', 'Letter Boxed', 'Chain words around sides',
        Icons.crop_square_rounded, 'Words', Color(0xFF38BDF8)),
    GameInfo('vertex', 'Vertex', 'Connect edges to balance',
        Icons.polyline_rounded, 'Patterns', Color(0xFFC084FC)),
    GameInfo('nonogram', 'Nonogram', 'Picross picture logic',
        Icons.table_chart_rounded, 'Patterns', Color(0xFF4ADE80)),
    GameInfo('binary', 'Binary', 'Balance 0s and 1s in grid',
        Icons.filter_2_rounded, 'Logic', Color(0xFFF43F5E)),
    GameInfo('cages', 'Cages', 'Killer Sudoku math arithmetic',
        Icons.calculate_rounded, 'Logic', Color(0xFFFACC15)),
  ];

  static GameInfo? byId(String? id) {
    for (final game in all) {
      if (game.id == id) return game;
    }
    return null;
  }

  /// Today's featured trio: one game from each category, rotating daily so
  /// every game gets a turn in the spotlight.
  static List<GameInfo> todaysPicks(DateTime day) {
    final dayIndex = DateTime.utc(day.year, day.month, day.day)
            .difference(DateTime.utc(2024))
            .inDays;
    return [
      for (final (i, category) in categories.indexed)
        () {
          final pool = all.where((g) => g.category == category).toList();
          return pool[(dayIndex + i * 3) % pool.length];
        }(),
    ];
  }
}
