import 'letter_state.dart';

/// A single cell on the board.
class TileData {
  final String letter;
  final LetterState state;

  const TileData({this.letter = '', this.state = LetterState.empty});

  TileData copyWith({String? letter, LetterState? state}) =>
      TileData(letter: letter ?? this.letter, state: state ?? this.state);
}

/// Phase the game is in.
enum GamePhase { playing, won, lost }

/// Full immutable state of a Daily Five game session.
class DailyFiveState {
  static const int maxGuesses = 6;
  static const int wordLength = 5;

  /// 6 rows × 5 columns of tile data.
  final List<List<TileData>> board;

  /// Which row the player is currently entering.
  final int currentRow;

  /// Letters typed in the active row (not yet submitted).
  final List<String> currentInput;

  /// Best known state for every keyboard key (a–z).
  final Map<String, LetterState> keyStates;

  /// The answer for today's puzzle.
  final String answer;

  /// Current game phase.
  final GamePhase phase;

  /// Puzzle number shown in the share string.
  final int puzzleNumber;

  /// Whether the flip animation for [currentRow - 1] is still playing.
  final bool isAnimating;

  /// Transient shake trigger for invalid word submission.
  final int shakeCount;

  /// Whether a streak was earned today upon winning.
  final bool streakEarnedToday;

  /// The current streak number when earned.
  final int earnedStreak;

  const DailyFiveState({
    required this.board,
    required this.currentRow,
    required this.currentInput,
    required this.keyStates,
    required this.answer,
    required this.phase,
    required this.puzzleNumber,
    this.isAnimating = false,
    this.shakeCount = 0,
    this.streakEarnedToday = false,
    this.earnedStreak = 0,
  });

  /// Creates a blank starting state.
  factory DailyFiveState.initial({
    required String answer,
    required int puzzleNumber,
  }) {
    return DailyFiveState(
      board: List.generate(
        maxGuesses,
        (_) => List.generate(wordLength, (_) => const TileData()),
      ),
      currentRow: 0,
      currentInput: [],
      keyStates: {},
      answer: answer,
      phase: GamePhase.playing,
      puzzleNumber: puzzleNumber,
    );
  }

  DailyFiveState copyWith({
    List<List<TileData>>? board,
    int? currentRow,
    List<String>? currentInput,
    Map<String, LetterState>? keyStates,
    String? answer,
    GamePhase? phase,
    int? puzzleNumber,
    bool? isAnimating,
    int? shakeCount,
    bool? streakEarnedToday,
    int? earnedStreak,
  }) {
    return DailyFiveState(
      board: board ?? this.board,
      currentRow: currentRow ?? this.currentRow,
      currentInput: currentInput ?? this.currentInput,
      keyStates: keyStates ?? this.keyStates,
      answer: answer ?? this.answer,
      phase: phase ?? this.phase,
      puzzleNumber: puzzleNumber ?? this.puzzleNumber,
      isAnimating: isAnimating ?? this.isAnimating,
      shakeCount: shakeCount ?? this.shakeCount,
      streakEarnedToday: streakEarnedToday ?? this.streakEarnedToday,
      earnedStreak: earnedStreak ?? this.earnedStreak,
    );
  }

  bool get isComplete => phase != GamePhase.playing;
}
