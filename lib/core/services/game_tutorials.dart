import 'package:flutter/material.dart';

/// One step of a first-time tutorial.
typedef TutorialStep = (IconData icon, String title, String body);

/// Three short steps per game, shown the first time a game is opened.
/// The full rules stay available from the game's ⋮ menu.
List<TutorialStep> tutorialFor(String title) {
  if (title.contains('Daily Five')) {
    return const [
      (Icons.keyboard_rounded, 'Type a guess', 'Enter any 5-letter word with the keyboard and tap ENTER.'),
      (Icons.palette_rounded, 'Read the colours', 'Green = right letter, right spot. Yellow = in the word, wrong spot. Grey = not in the word.'),
      (Icons.emoji_events_rounded, 'Solve in 6', 'Use the clues to find the word in six tries or fewer.'),
    ];
  }
  if (title.contains('Sudoku')) {
    return const [
      (Icons.touch_app_rounded, 'Pick a cell', 'Tap an empty square on the board.'),
      (Icons.dialpad_rounded, 'Place a number', 'Tap 1–9. Each row, column and 3×3 box needs every digit once.'),
      (Icons.edit_note_rounded, 'Use notes', 'Turn on Pencil to jot candidates. Stuck? The bulb gives a hint.'),
    ];
  }
  if (title.contains('Connections')) {
    return const [
      (Icons.grid_view_rounded, 'Spot a link', 'Find four words that share something in common.'),
      (Icons.check_box_rounded, 'Select four', 'Tap four words, then Submit.'),
      (Icons.favorite_rounded, 'Mind your mistakes', 'You can make a few wrong guesses. Find all four groups to win.'),
    ];
  }
  if (title.contains('Spelling Bee')) {
    return const [
      (Icons.hive_rounded, 'Use the letters', 'Make words of 4+ letters from the seven tiles.'),
      (Icons.center_focus_strong_rounded, 'Always use the centre', 'Every word must include the centre letter. Letters can repeat.'),
      (Icons.star_rounded, 'Find the pangram', 'A word using all seven letters scores big.'),
    ];
  }
  if (title.contains('Crossword') || title.contains('Mini')) {
    return const [
      (Icons.touch_app_rounded, 'Pick a square', 'Tap a square; tap again to switch between across and down.'),
      (Icons.keyboard_rounded, 'Fill the answer', 'Type letters to answer the highlighted clue.'),
      (Icons.fact_check_rounded, 'Check as you go', 'Use Check to spot mistakes, or the bulb to reveal a letter.'),
    ];
  }
  if (title.contains('Strands')) {
    return const [
      (Icons.gesture_rounded, 'Trace words', 'Tap neighbouring letters (any direction) to spell a theme word, then submit.'),
      (Icons.auto_awesome_rounded, 'Find the spangram', 'One special word spans the whole board and names the theme.'),
      (Icons.grid_on_rounded, 'Use every letter', 'Every letter belongs to exactly one answer.'),
    ];
  }
  if (title.contains('Pips')) {
    return const [
      (Icons.casino_rounded, 'Pick a domino', 'Tap a domino in the tray. Use the rotate button to turn it.'),
      (Icons.grid_4x4_rounded, 'Place it', 'Tap a board cell to drop it there. Tap a placed domino to pick it back up.'),
      (Icons.rule_rounded, 'Meet every rule', 'Each coloured region has a rule: a sum, all equal, all different, more or less than.'),
    ];
  }
  if (title.contains('Tiles')) {
    return const [
      (Icons.layers_rounded, 'Find a pair', 'Look for two tiles that share the same pattern.'),
      (Icons.touch_app_rounded, 'Tap both', 'Tap one tile, then its match to clear them.'),
      (Icons.bolt_rounded, 'Chain combos', 'Clear matches in a row for a combo. Clear the board to win.'),
    ];
  }
  if (title.contains('Letter Boxed')) {
    return const [
      (Icons.crop_square_rounded, 'Chain letters', 'Build words by tapping letters around the square.'),
      (Icons.swap_horiz_rounded, 'Switch sides', 'Consecutive letters must come from different sides.'),
      (Icons.link_rounded, 'Link the words', 'Each new word starts with the last letter of the previous one. Use every letter.'),
    ];
  }
  if (title.contains('Vertex')) {
    return const [
      (Icons.radio_button_checked_rounded, 'Read the numbers', 'Each dot shows how many lines it needs.'),
      (Icons.polyline_rounded, 'Connect dots', 'Tap two dots to draw a line between them; tap the pair again to remove it.'),
      (Icons.check_circle_rounded, 'Balance them all', 'Solve it when every dot has exactly its number of lines.'),
    ];
  }
  if (title.contains('Nonogram')) {
    return const [
      (Icons.format_list_numbered_rounded, 'Read the clues', 'Numbers show the runs of filled squares in each row and column.'),
      (Icons.touch_app_rounded, 'Fill squares', 'Tap to fill a square. Long-press to mark one you know is empty.'),
      (Icons.image_rounded, 'Reveal the picture', 'Satisfy every clue to finish the picture.'),
    ];
  }
  if (title.contains('Binary')) {
    return const [
      (Icons.touch_app_rounded, 'Tap to cycle', 'Tap a cell to switch between 0, 1 and empty.'),
      (Icons.balance_rounded, 'Keep it balanced', 'Every row and column has equal 0s and 1s.'),
      (Icons.block_rounded, 'No three in a row', 'Never put three of the same digit side by side.'),
    ];
  }
  if (title.contains('Cages')) {
    return const [
      (Icons.dialpad_rounded, 'Like Sudoku', 'Fill every row, column and box with each digit once.'),
      (Icons.calculate_rounded, 'Add up the cages', 'Digits in each outlined cage must add up to its small number.'),
      (Icons.block_rounded, 'No repeats in a cage', 'A digit can appear only once inside a cage.'),
    ];
  }
  if (title.contains('Chess')) {
    return const [
      (Icons.touch_app_rounded, 'Move a piece', 'Tap a piece to see its moves, then tap a highlighted square.'),
      (Icons.extension_rounded, 'Daily Puzzles', 'Find the checkmate. Any move that forces mate counts.'),
      (Icons.smart_toy_rounded, 'Or play a game', 'Take on the AI at three levels, or pass the phone to a friend.'),
    ];
  }
  return const [
    (Icons.touch_app_rounded, 'Have a go', 'Tap around the board to start.'),
    (Icons.lightbulb_rounded, 'Get a hint', 'The bulb in the top bar nudges you along.'),
    (Icons.info_outline_rounded, 'Full rules', 'Open ⋮ → How to play any time.'),
  ];
}
