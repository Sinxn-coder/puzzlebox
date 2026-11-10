String rulesFor(String title) {
  if (title.contains('Daily Five')) {
    return 'Objective: Guess the hidden 5-letter word within 6 tries.\n\n'
        'How to Play:\n'
        '• Type a 5-letter word and tap enter to submit your guess.\n'
        '• After each guess, the color of the tiles will change to show how close your guess was.\n\n'
        'Color Guide:\n'
        '• Green: The letter is in the word and in the correct spot.\n'
        '• Yellow: The letter is in the word but in the wrong spot.\n'
        '• Gray: The letter is not in the word in any spot.\n'
        '• Colorblind Friendly (Settings): orange means correct spot, blue means wrong spot, and small ✓ / ⇄ marks repeat the meaning.\n\n'
        'Rules:\n'
        '• Repeated letters are counted individually. If a letter appears twice in the word, you can get two green/yellow clues for it!\n'
        '• Answers are common, well-known words. In Unlimited, a word never repeats until you have played every word at that level.\n'
        '• Easy: five different letters and no rare letters. Hard: repeated or rare letters (J, K, Q, V, X, Z) or words with many look-alikes (like _IGHT).\n'
        '• Daily Five Hard Mode (Settings): revealed hints must be used in later guesses.';
  }
  if (title.contains('Sudoku')) {
    return 'Objective: Fill the 9x9 grid so that every row, column, and 3x3 box contains the digits 1 through 9 exactly once.\n\n'
        'How to Play:\n'
        '• Tap an empty cell to select it.\n'
        '• Tap a number from the keypad below to place it into the selected cell.\n'
        '• Given numbers (in black) cannot be changed.\n'
        '• Your entered numbers appear in the accent color.\n\n'
        'Tools:\n'
        '• Pencil Mode: Tap the pencil icon to toggle notes. When active, tapping numbers adds tiny candidate notes to the cell instead of a final answer.\n'
        '• Undo: Reverts your last move or note.\n\n'
        'Difficulty: Every puzzle has exactly one solution and can be solved by logic alone, no guessing.\n'
        '• Easy: singles only (a cell with one option, or a digit with one spot).\n'
        '• Medium: also needs pairs and pointing/claiming eliminations.\n'
        '• Hard: also needs advanced patterns such as X-Wing and XY-Wing.';
  }
  if (title.contains('Connections')) {
    return 'Objective: Group all 16 words into four separate categories of exactly four words each.\n\n'
        'How to Play:\n'
        '• Read through the 16 words and look for common threads or themes.\n'
        '• Tap exactly four words that you believe share a category.\n'
        '• Tap \'Submit\' to check your guess.\n'
        '• If correct, the group will be highlighted and removed from the board.\n'
        '• You win when you successfully group all four categories!\n\n'
        'Rules & Tips:\n'
        '• You have a maximum of 4 mistakes allowed.\n'
        '• If your guess contains 3 correct words, you\'ll be told you are "One away".\n'
        '• Be careful of trick words! Some words might seem to belong to multiple categories.\n'
        '• Difficulty levels change the complexity of the categories (harder levels include fill-in-the-blanks, rhymes, and compound words).';
  }
  if (title.contains('Spelling Bee')) {
    return 'Objective: Build as many real words as possible using the 7 letters provided in the honeycomb.\n\n'
        'How to Play:\n'
        '• Words must contain at least 4 letters.\n'
        '• Every single word MUST include the center letter.\n'
        '• Letters can be used more than once in a single word.\n'
        '• Tap letters to build a word, then tap Submit.\n\n'
        'Scoring:\n'
        '• 4-letter words earn 1 point.\n'
        '• Words with 5 or more letters earn 1 point per letter (e.g., a 6-letter word is 6 points).\n'
        '• Pangram: A word that uses ALL 7 letters earns a massive 7-point bonus!\n\n'
        'Progress:\n'
        '• Watch the progress bar fill up as your score increases.\n'
        '• Reach the target goal displayed to officially "win" and advance to the next puzzle.\n'
        '• Only words in our built-in offline dictionary are accepted.';
  }
  if (title.contains('Crossword') || title.contains('Mini')) {
    return 'Objective: Fill every empty white square with the correct letters to solve the crossing clues.\n\n'
        'How to Play:\n'
        '• Tap a square or a clue from the list to highlight it.\n'
        '• The current direction (Across or Down) is highlighted in yellow.\n'
        '• Tap a square a second time to switch the typing direction.\n'
        '• Type on the keyboard to fill the squares. The cursor will automatically advance.\n\n'
        'Tools:\n'
        '• Hint: Reveals the correct letter for your currently selected square.\n'
        '• Undo: Reverts your last typed letter.\n'
        '• Check: Validates the board and temporarily marks any incorrect letters in red.\n\n'
        'Note: All puzzles are uniquely generated crisscross grids with fresh original clues!';
  }
  if (title.contains('Strands')) {
    return 'Objective: Find hidden words connected on the grid to uncover the overarching theme.\n\n'
        'How to Play:\n'
        '• Trace your finger (or tap) across adjacent letters to form words.\n'
        '• Words can snake in any direction, including diagonally!\n'
        '• Every single letter on the board must be used exactly once.\n'
        '• Find the "Spangram" — a special theme word that spans from one edge of the board to the other, describing the puzzle\'s category.\n\n'
        'Tools & Rules:\n'
        '• If you make a mistake tracing, tap an earlier letter in your path to back up.\n'
        '• Tap \'Undo\' to completely release the last word you traced.\n'
        '• Easy mode shows you the exact words you are looking for at the bottom.\n'
        '• Hard mode hides the target words and forces you to figure out the theme on your own.';
  }
  if (title.contains('Pips')) {
    return 'Objective: Place your dominoes into the correct slots so the halves sum perfectly to the target numbers.\n\n'
        'How to Play:\n'
        '• You have a hand of dominoes at the bottom. Each domino has two halves with varying dots (pips).\n'
        '• The board has empty slots, each displaying a target number.\n'
        '• Tap a domino in your hand, then tap an empty slot to place it.\n'
        '• The sum of the pips on the placed domino MUST equal the target number of the slot.\n'
        '• Every domino can be used exactly once.\n\n'
        'Tips:\n'
        '• If you need to rearrange, simply tap a placed domino on the board to return it to your hand.\n'
        '• Placing a new domino into an occupied slot will automatically return the old one to your hand.\n'
        '• Higher difficulties increase the number of dominoes and slots you must manage.';
  }
  if (title.contains('Tiles')) {
    return 'Objective: Clear the entire board by matching pairs of identical tiles.\n\n'
        'How to Play:\n'
        '• Look for two tiles with the exact same symbol.\n'
        '• Tap the first tile, then tap its matching partner to clear both from the board.\n'
        '• You can only match tiles that are not "blocked" (they must be accessible without other tiles directly covering them).\n\n'
        'Combos & Strategy:\n'
        '• Matching consecutive pairs without errors builds your Combo Multiplier!\n'
        '• If you tap two tiles that do not match, your combo resets to zero.\n'
        '• Every board is completely solvable with at least one perfect matching path.\n'
        '• Higher difficulties dramatically increase the number of tile pairs.';
  }
  if (title.contains('Letter Boxed')) {
    return 'Objective: Form real words by connecting letters around the edges of the box until every letter has been used.\n\n'
        'How to Play:\n'
        '• Tap letters to start forming a word.\n'
        '• CRITICAL RULE: Consecutive letters cannot be from the same side of the box. You must alternate to different sides.\n'
        '• Tap the checkmark to submit a valid word.\n'
        '• Your next word MUST start with the final letter of the previous word.\n'
        '• Win by using all 12 letters across your entire chain of words.\n\n'
        'Tools:\n'
        '• Use the backspace button to erase letters in your current word.\n'
        '• Use the \'Undo\' button to completely remove your last submitted word.\n'
        '• Easy mode will automatically pre-fill the first suggested word for you to help you get started.';
  }
  if (title.contains('Vertex')) {
    return 'Objective: Connect pairs of dots to form a complete geometric shape based on the numeric rules.\n\n'
        'How to Play:\n'
        '• Each dot has a number inside it indicating exactly how many lines must connect to it.\n'
        '• Tap a dot, then tap another dot to draw a line connecting them.\n'
        '• Tap an existing connected pair again to remove the line.\n'
        '• Lines are allowed to cross each other!\n'
        '• A dot turns green when it has the exact correct number of connections.\n'
        '• You win when every single dot is perfectly satisfied.\n\n'
        'Tools:\n'
        '• Hint: Temporarily highlights one correct connection required for a known solution. Note that multiple valid solutions may exist!';
  }
  if (title.contains('Nonogram')) {
    return 'Objective: Use the numerical clues to deduce which cells should be filled to reveal a hidden picture.\n\n'
        'How to Play:\n'
        '• The numbers next to rows and columns tell you the lengths of consecutive filled blocks.\n'
        '• For example, a clue of "3 1" means there is a block of 3 filled cells, followed by at least one empty space, and then a block of 1 filled cell.\n'
        '• Tap a cell once to FILL it (turns black).\n'
        '• Long-press a cell to MARK it as empty (adds an \'X\' to help you keep track).\n'
        '• When you correctly satisfy an entire row or column, its numerical clue will turn bright.\n\n'
        'Tools:\n'
        '• Undo: Reverts your last tap or long-press.\n'
        '• Hint: Safely reveals the correct state of one random cell.';
  }
  if (title.contains('Binary')) {
    return 'Objective: Fill the entire grid with 0s and 1s following three strict logic rules.\n\n'
        'Rules of Binary:\n'
        '1. Balance: Every row and every column must contain an equal number of 0s and 1s.\n'
        '2. No Trios: You cannot have three of the same digit next to each other (e.g., 0-0-0 or 1-1-1 is invalid).\n'
        '3. Uniqueness: No two rows can be exactly identical, and no two columns can be exactly identical.\n\n'
        'How to Play:\n'
        '• Tap any empty cell to cycle its value: Blank → 0 → 1 → Blank.\n'
        '• If your placement violates any rule, the conflicting cells will briefly highlight in red.\n'
        '• Use pure logic to deduce the rest of the board!\n\n'
        'Tools:\n'
        '• Undo: Reverts your last move.\n'
        '• Hint: Automatically fills one cell correctly for you.';
  }
  if (title.contains('Cages')) {
    return 'Objective: Fill the grid using math and logic so no numbers repeat in any row or column.\n\n'
        'Rules of Cages:\n'
        '1. Latin Square: Fill the grid with numbers 1 through N (the grid size). A number cannot appear twice in the same row or column.\n'
        '2. Math Cages: The board is divided into heavily outlined regions called cages.\n'
        '3. The top corner of each cage shows a target number and a math operation (+, -, ×, ÷).\n'
        '4. The numbers you place inside that cage must use that operation to equal the target number (in any order).\n\n'
        'How to Play:\n'
        '• Tap a cell to select it.\n'
        '• Tap a number on the keypad to place it.\n'
        '• Use the \'Note\' (pencil) tool to draft potential numbers without committing them.\n\n'
        'Tools:\n'
        '• Undo: Reverts your last move or note.\n'
        '• Hint: Correctly reveals one cell.';
  }
  if (title.contains('Chess')) {
    return 'Objective: Checkmate the opponent\'s king.\n\n'
        'Game Modes:\n'
        '• Daily Puzzles: Force checkmate. Easy puzzles are mate in one; Medium and Hard are mate in two. Any move that still forces mate counts, and a wrong move is simply taken back so you can try again.\n'
        '• Vs AI: Play a full game against an intelligent computer opponent. Choose from Easy, Medium, or Hard difficulties.\n'
        '• Pass & Play: Play a local match against a friend on the same device.\n\n'
        'How to Play:\n'
        '• Tap a piece to select it and view its valid moves.\n'
        '• Tap a valid highlighted square to move there.\n'
        '• If your pawn reaches the opposite end of the board, you will be prompted to promote it.\n'
        '• The top and bottom trays display which pieces have been captured by each side.\n\n'
        'Tools:\n'
        '• Undo: Reverts the last move.\n'
        '• Flip Board: Rotates the board 180 degrees.\n'
        '• Restart: Resets the current puzzle or match.';
  }
  return 'Choose any of the games to begin. Unlimited play has no level cap, ads, payments or accounts. Daily challenges are separate from unlimited totals. Your progress and theme are stored securely on this device.';
}
