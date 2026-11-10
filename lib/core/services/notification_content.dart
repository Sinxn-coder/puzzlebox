/// Notification content definition and catalog.
class NotificationContent {
  final String title;
  final String body;
  final String? gameId;

  const NotificationContent({
    required this.title,
    required this.body,
    this.gameId,
  });
}

class NotificationCatalog {
  static const List<NotificationContent> messages = [
    // 1. General logic & brain workouts
    NotificationContent(
      title: 'A little logic goes a long way 🧩',
      body: 'Take 5 minutes for a mindful brain break with Puzzlebox.',
    ),
    NotificationContent(
      title: 'Your daily brain workout is waiting 🧠',
      body: 'Sharpen your pattern recognition and deduction skills today.',
    ),
    NotificationContent(
      title: 'Got a few minutes? There’s a puzzle for that ☕',
      body: 'A quick puzzle is the perfect mindful break for your day.',
    ),
    NotificationContent(
      title: 'Give your mind a playful challenge ✨',
      body: 'Keep your logic sharp with today’s offline puzzles.',
    ),
    NotificationContent(
      title: 'Ready to solve something new? 🎯',
      body: 'Choose from 15 offline word and logic puzzles ready to play.',
    ),

    // 2. Specific puzzle discovery (linking to games)
    NotificationContent(
      title: 'Today’s Sudoku is ready 🔢',
      body: 'Can you place 1 to 9 without repeating in any row or column?',
      gameId: 'sudoku',
    ),
    NotificationContent(
      title: 'Time for Daily Five 🟩',
      body: 'Six tries to deduce today’s secret 5-letter word. Give it a shot!',
      gameId: 'daily_five',
    ),
    NotificationContent(
      title: 'Connect the clues 🔗',
      body: 'Can you sort today’s 16 words into 4 secret categories?',
      gameId: 'connections',
    ),
    NotificationContent(
      title: 'The Mini Crossword awaits ✏️',
      body: 'A quick 5x5 grid designed to test your vocabulary in under 2 minutes.',
      gameId: 'mini_crossword',
    ),
    NotificationContent(
      title: 'Tactics check: Play Chess ♟️',
      body: 'Test your tactical foresight against the AI or try a tactic.',
      gameId: 'chess',
    ),
    NotificationContent(
      title: 'Spelling Bee is buzzing 🐝',
      body: 'How many words can you find using the 7 letters today?',
      gameId: 'spelling_bee',
    ),
    NotificationContent(
      title: 'Unravel the Strands 🧵',
      body: 'Follow the letter paths to find today’s hidden theme words.',
      gameId: 'strands',
    ),
    NotificationContent(
      title: 'Domino logic with Pips 🎲',
      body: 'Place the dominoes and balance the equations in Pips.',
      gameId: 'pips',
    ),
    NotificationContent(
      title: 'Pattern matching in Tiles 🀄',
      body: 'Spot shared shapes and colors to clear the board in Tiles.',
      gameId: 'tiles',
    ),
    NotificationContent(
      title: 'Picture logic: Nonogram 🖼️',
      body: 'Use the row and column number clues to reveal the hidden pixel art.',
      gameId: 'nonogram',
    ),
    NotificationContent(
      title: 'Binary puzzle balance ⚖️',
      body: 'Fill the grid with 0s and 1s without three consecutive identical digits.',
      gameId: 'binary',
    ),
    NotificationContent(
      title: 'Cages arithmetic challenge 🧮',
      body: 'Combine Sudoku placement with math sums inside cages.',
      gameId: 'cages',
    ),
    NotificationContent(
      title: 'Letter Boxed word chains 📦',
      body: 'Connect letters around the square to solve the puzzle in fewest turns.',
      gameId: 'letter_boxed',
    ),
    NotificationContent(
      title: 'Vertex graph balance 🕸️',
      body: 'Connect the vertices so every point matches its degree number.',
      gameId: 'vertex',
    ),
    NotificationContent(
      title: 'Full Crossword challenge 📰',
      body: 'Expand your word power with a full-size crossword grid.',
      gameId: 'crossword',
    ),
  ];

  /// Deterministically select message based on day of year to ensure variety
  static NotificationContent getMessageForDay(int dayOfYear) {
    final index = dayOfYear % messages.length;
    return messages[index];
  }
}
