import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/neo_toast.dart';
import '../../core/services/app_feedback_service.dart';
import '../../core/services/practice_service.dart';
import '../../core/services/stats_service.dart';
import '../../core/widgets/pressable_scale.dart';
import 'models/chess_puzzle.dart';
import 'logic/chess_puzzles_data.dart';
import 'logic/chess_ai.dart';
import 'widgets/chess_board_widget.dart';
import 'widgets/pawn_promotion_dialog.dart';
import 'widgets/chess_piece_widget.dart';

enum ChessGameMode { dailyPuzzle, vsAI, passAndPlay }

class ChessScreen extends ConsumerStatefulWidget {
  const ChessScreen({super.key});

  @override
  ConsumerState<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends ConsumerState<ChessScreen> {
  ChessGameMode _mode = ChessGameMode.dailyPuzzle;
  AIDifficulty _aiDifficulty = AIDifficulty.medium;

  late chess_lib.Chess _game;
  String? _selectedSquare;
  List<String> _validMoves = [];
  Map<String, String>? _lastMove;
  bool _isFlipped = false;
  final List<String> _fenHistory = [];

  // Daily puzzle state
  late ChessPuzzle _currentPuzzle;
  int _currentPuzzleIndex = 0;
  int _puzzleStepIndex = 0;
  bool _puzzleCompleted = false;

  @override
  void initState() {
    super.initState();
    _startDailyPuzzle();
  }

  void _startDailyPuzzle() {
    final now = DateTime.now();
    _currentPuzzleIndex = now.difference(DateTime(2026, 1, 1)).inDays;
    if (_currentPuzzleIndex < 0) _currentPuzzleIndex = 0;
    _loadPuzzle(ChessPuzzlesData.getPuzzleAtIndex(_currentPuzzleIndex));
  }

  void _startNextPuzzle() {
    _currentPuzzleIndex++;
    _loadPuzzle(ChessPuzzlesData.getPuzzleAtIndex(_currentPuzzleIndex));
  }

  void _loadPuzzle(ChessPuzzle puzzle) {
    _currentPuzzle = puzzle;
    _game = chess_lib.Chess.fromFEN(_currentPuzzle.fen);
    _selectedSquare = null;
    _validMoves = [];
    _lastMove = null;
    _isFlipped = (_game.turn == chess_lib.Color.BLACK);
    _puzzleStepIndex = 0;
    _puzzleCompleted = false;
    _fenHistory.clear();
    _fenHistory.add(_game.fen);
  }

  void _startVsAIGame() {
    _game = chess_lib.Chess();
    _selectedSquare = null;
    _validMoves = [];
    _lastMove = null;
    _isFlipped = false;
    _puzzleCompleted = false;
    _fenHistory.clear();
    _fenHistory.add(_game.fen);

    if (_isFlipped && _game.turn == chess_lib.Color.WHITE) {
      _makeAIMove();
    }
  }

  void _startPassAndPlayGame() {
    _game = chess_lib.Chess();
    _selectedSquare = null;
    _validMoves = [];
    _lastMove = null;
    _isFlipped = false;
    _puzzleCompleted = false;
    _fenHistory.clear();
    _fenHistory.add(_game.fen);
  }

  /// Calculates missing White pieces on current board (captured White pieces)
  String _getCapturedWhiteText() {
    final Map<String, int> initialCount = {'p': 8, 'n': 2, 'b': 2, 'r': 2, 'q': 1};
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    for (int rank = 1; rank <= 8; rank++) {
      for (final file in files) {
        final p = _game.get('$file$rank');
        if (p != null && p.color == chess_lib.Color.WHITE) {
          final t = p.type.name.toLowerCase();
          if (initialCount.containsKey(t) && initialCount[t]! > 0) {
            initialCount[t] = initialCount[t]! - 1;
          }
        }
      }
    }
    final List<String> captured = [];
    final symbols = {'p': '♙', 'n': '♘', 'b': '♗', 'r': '♖', 'q': '♕'};
    initialCount.forEach((t, missing) {
      for (int i = 0; i < missing; i++) {
        captured.add(symbols[t]!);
      }
    });
    return captured.join(' ');
  }

  /// Calculates missing Black pieces on current board (captured Black pieces)
  String _getCapturedBlackText() {
    final Map<String, int> initialCount = {'p': 8, 'n': 2, 'b': 2, 'r': 2, 'q': 1};
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    for (int rank = 1; rank <= 8; rank++) {
      for (final file in files) {
        final p = _game.get('$file$rank');
        if (p != null && p.color == chess_lib.Color.BLACK) {
          final t = p.type.name.toLowerCase();
          if (initialCount.containsKey(t) && initialCount[t]! > 0) {
            initialCount[t] = initialCount[t]! - 1;
          }
        }
      }
    }
    final List<String> captured = [];
    final symbols = {'p': '♟', 'n': '♞', 'b': '♝', 'r': '♜', 'q': '♛'};
    initialCount.forEach((t, missing) {
      for (int i = 0; i < missing; i++) {
        captured.add(symbols[t]!);
      }
    });
    return captured.join(' ');
  }

  Map<chess_lib.PieceType, int> _getCapturedCounts(bool isWhite) {
    final targetColor = isWhite ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;
    final Map<chess_lib.PieceType, int> initialCount = {
      chess_lib.PieceType.PAWN: 8,
      chess_lib.PieceType.KNIGHT: 2,
      chess_lib.PieceType.BISHOP: 2,
      chess_lib.PieceType.ROOK: 2,
      chess_lib.PieceType.QUEEN: 1,
    };
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    for (int rank = 1; rank <= 8; rank++) {
      for (final file in files) {
        final p = _game.get('$file$rank');
        if (p != null && p.color == targetColor) {
          if (initialCount.containsKey(p.type) && initialCount[p.type]! > 0) {
            initialCount[p.type] = initialCount[p.type]! - 1;
          }
        }
      }
    }
    final Map<chess_lib.PieceType, int> result = {};
    for (final entry in initialCount.entries) {
      if (entry.value > 0) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  Widget _buildCapturedRow(bool isWhite) {
    final counts = _getCapturedCounts(isWhite);
    if (counts.isEmpty) {
      return const SizedBox(height: 20);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in counts.entries)
          for (int i = 0; i < entry.value; i++)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: ChessPieceWidget.fromType(
                type: entry.key,
                isWhite: isWhite,
                size: 20,
              ),
            ),
      ],
    );
  }

  void _onSquareTap(String square) {
    if (_puzzleCompleted || _game.in_checkmate || _game.in_stalemate) return;
    AppFeedbackService.tap(ref);

    if (_mode == ChessGameMode.vsAI) {
      final isPlayerTurn = (_isFlipped && _game.turn == chess_lib.Color.BLACK) ||
          (!_isFlipped && _game.turn == chess_lib.Color.WHITE);
      if (!isPlayerTurn) return;
    }

    // Deselect if tapping same square
    if (_selectedSquare == square) {
      setState(() {
        _selectedSquare = null;
        _validMoves = [];
      });
      return;
    }

    // Execute move if destination is valid
    if (_selectedSquare != null && _validMoves.contains(square)) {
      _executeMove(_selectedSquare!, square);
      return;
    }

    // Select piece on square if matching turn
    final piece = _game.get(square);
    if (piece != null && piece.color == _game.turn) {
      final List<chess_lib.Move> allLegalMoves =
          _game.generate_moves({'verbose': true});
      final validDestinations = <String>[];
      for (final m in allLegalMoves) {
        if (chess_lib.Chess.algebraic(m.from) == square) {
          validDestinations.add(chess_lib.Chess.algebraic(m.to));
        }
      }

      setState(() {
        _selectedSquare = square;
        _validMoves = validDestinations;
      });
    } else {
      setState(() {
        _selectedSquare = null;
        _validMoves = [];
      });
    }
  }

  Future<void> _executeMove(String from, String to) async {
    final piece = _game.get(from);
    final isPawn = piece?.type == chess_lib.PieceType.PAWN;
    final isPromotionRank = (piece?.color == chess_lib.Color.WHITE && to.endsWith('8')) ||
        (piece?.color == chess_lib.Color.BLACK && to.endsWith('1'));

    String? promotionPiece;
    if (isPawn && isPromotionRank) {
      promotionPiece = await PawnPromotionDialog.show(
        context,
        piece?.color == chess_lib.Color.WHITE,
      );
      if (promotionPiece == null) return;
    }

    // Find native legal Move object
    final List<chess_lib.Move> legalMoves = _game.generate_moves({'verbose': true});
    chess_lib.Move? targetMove;
    for (final m in legalMoves) {
      final fromAlg = chess_lib.Chess.algebraic(m.from);
      final toAlg = chess_lib.Chess.algebraic(m.to);
      if (fromAlg == from && toAlg == to) {
        if (promotionPiece != null) {
          if (m.promotion?.name.toLowerCase() == promotionPiece.toLowerCase()) {
            targetMove = m;
            break;
          }
        } else {
          targetMove = m;
          break;
        }
      }
    }

    if (targetMove == null) return;

    final sanMove = _game.move_to_san(targetMove);

    // Make native move
    _game.make_move(targetMove);
    _fenHistory.add(_game.fen);

    _lastMove = {'from': from, 'to': to};
    _selectedSquare = null;
    _validMoves = [];

    if (_mode == ChessGameMode.dailyPuzzle) {
      _handleDailyPuzzleMove(sanMove);
    } else if (_mode == ChessGameMode.vsAI) {
      setState(() {});
      _checkEndState();
      if (!_game.in_checkmate && !_game.in_stalemate && !_game.in_draw) {
        Future.delayed(const Duration(milliseconds: 350), _makeAIMove);
      }
    } else {
      setState(() {});
      _checkEndState();
    }
  }

  void _handleDailyPuzzleMove(String playedSan) {
    final expectedSan = _currentPuzzle.solutionMoves[_puzzleStepIndex];

    if (playedSan == expectedSan || _matchSanBase(playedSan, expectedSan)) {
      _puzzleStepIndex++;
      setState(() {});

      if (_puzzleStepIndex >= _currentPuzzle.solutionMoves.length) {
        _puzzleCompleted = true;
        _recordPuzzleWin();
        _showVictoryDialog('Puzzle Solved!', 'Great tactics! You solved puzzle #${_currentPuzzleIndex + 1}.');
      } else {
        // Play opponent response move automatically
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          final responseSan = _currentPuzzle.solutionMoves[_puzzleStepIndex];
          _game.move(responseSan);
          _fenHistory.add(_game.fen);
          _puzzleStepIndex++;
          _lastMove = null;
          setState(() {});
        });
      }
    } else {
      NeoToast.show(
        context,
        'Not the best move! Resetting board...',
        icon: Icons.refresh_rounded,
        color: const Color(0xFFF43F5E),
        duration: const Duration(seconds: 2),
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _loadPuzzle(_currentPuzzle));
      });
    }
  }

  bool _matchSanBase(String a, String b) {
    final cleanA = a.replaceAll('#', '').replaceAll('+', '');
    final cleanB = b.replaceAll('#', '').replaceAll('+', '');
    return cleanA == cleanB;
  }

  void _makeAIMove() {
    if (!mounted || _game.in_checkmate || _game.in_stalemate) return;
    final bestMove = ChessAI.getBestMove(_game, _aiDifficulty);
    if (bestMove != null) {
      final from = chess_lib.Chess.algebraic(bestMove.from);
      final to = chess_lib.Chess.algebraic(bestMove.to);

      _game.make_move(bestMove);
      _fenHistory.add(_game.fen);

      _lastMove = {'from': from, 'to': to};
      setState(() {});
      _checkEndState();
    }
  }

  void _checkEndState() {
    if (_game.in_checkmate) {
      final winner = _game.turn == chess_lib.Color.WHITE ? 'Black' : 'White';
      _recordPuzzleWin();
      _showVictoryDialog('Checkmate!', '$winner wins the match!');
    } else if (_game.in_stalemate || _game.in_draw) {
      _showVictoryDialog('Draw!', 'The game ended in a stalemate/draw.');
    }
  }

  Future<void> _recordPuzzleWin() async {
    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    await ref.read(statsServiceProvider).recordResult(
          gameType: 'chess',
          todayKey: todayKey,
          won: true,
        );
    await ref.read(practiceServiceProvider).recordSolved('chess', _currentPuzzle.id);
  }

  void _showVictoryDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(title, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 56),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Next Puzzle ➔'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  if (_mode == ChessGameMode.dailyPuzzle) {
                    _startNextPuzzle();
                  } else if (_mode == ChessGameMode.vsAI) {
                    _startVsAIGame();
                  } else {
                    _startPassAndPlayGame();
                  }
                });
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Home'),
            ),
          ],
        );
      },
    );
  }

  void _undoMove() {
    if (_fenHistory.length <= 1) return;
    setState(() {
      _fenHistory.removeLast();
      if (_mode == ChessGameMode.vsAI && _fenHistory.length > 1) {
        _fenHistory.removeLast(); // Undo AI move as well
      }
      _game = chess_lib.Chess.fromFEN(_fenHistory.last);
      _lastMove = null;
      _selectedSquare = null;
      _validMoves = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Chess',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Mode tab bar (pinned at top)
            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _buildNeoModeTab('Daily Puzzles', ChessGameMode.dailyPuzzle, colors)),
                  Expanded(child: _buildNeoModeTab('Vs AI', ChessGameMode.vsAI, colors)),
                  Expanded(child: _buildNeoModeTab('Pass & Play', ChessGameMode.passAndPlay, colors)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Fixed-height Info Card Slot (never collapses or resizes)
            SizedBox(
              height: 92,
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: _mode == ChessGameMode.dailyPuzzle
                    ? Container(
                        key: const ValueKey('chess_daily_card'),
                        width: double.infinity,
                        height: 92,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.black, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Puzzle #${_currentPuzzleIndex + 1}: ${_currentPuzzle.title}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: Text(
                                    _currentPuzzle.difficulty,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _currentPuzzle.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() => _startNextPuzzle()),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black, width: 1.5),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Next', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.black),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : _mode == ChessGameMode.vsAI
                        ? Container(
                            key: const ValueKey('chess_ai_card'),
                            width: double.infinity,
                            height: 92,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.black, width: 2.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'AI Opponent',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'On-device minimax chess engine',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: DropdownButton<AIDifficulty>(
                                    value: _aiDifficulty,
                                    underline: const SizedBox(),
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _aiDifficulty = val;
                                          _startVsAIGame();
                                        });
                                      }
                                    },
                                    items: const [
                                      DropdownMenuItem(
                                        value: AIDifficulty.easy,
                                        child: Text('Easy'),
                                      ),
                                      DropdownMenuItem(
                                        value: AIDifficulty.medium,
                                        child: Text('Medium'),
                                      ),
                                      DropdownMenuItem(
                                        value: AIDifficulty.hard,
                                        child: Text('Hard'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            key: const ValueKey('chess_pass_card'),
                            width: double.infinity,
                            height: 92,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.black, width: 2.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5), blurRadius: 0),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: const Icon(Icons.people_alt_rounded, size: 22, color: Colors.black),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Pass & Play',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Play side-by-side on this device',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 10),

            // Top captured row (fixed 26px height - never collapses)
            SizedBox(
              height: 26,
              child: Row(
                children: [
                  const Text('Captured: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildCapturedRow(_isFlipped),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Chess Board Widget (single AspectRatio(1.0), identical size and location across all modes)
            AspectRatio(
              aspectRatio: 1.0,
              child: ChessBoardWidget(
                game: _game,
                selectedSquare: _selectedSquare,
                validMoves: _validMoves,
                lastMove: _lastMove,
                isFlipped: _isFlipped,
                onSquareTap: _onSquareTap,
              ),
            ),
            const SizedBox(height: 6),

            // Bottom captured row (fixed 26px height - never collapses)
            SizedBox(
              height: 26,
              child: Row(
                children: [
                  const Text('Captured: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildCapturedRow(!_isFlipped),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Bottom control action buttons (fixed 4-slot row; Hint slot maintained when hidden)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNeoActionButton(
                  icon: Icons.undo_rounded,
                  tooltip: 'Undo Move',
                  onPressed: _undoMove,
                  colors: colors,
                ),
                _buildNeoActionButton(
                  icon: Icons.flip_camera_android_rounded,
                  tooltip: 'Flip Board',
                  onPressed: () => setState(() => _isFlipped = !_isFlipped),
                  colors: colors,
                ),
                _buildNeoActionButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Restart Puzzle',
                  onPressed: () {
                    setState(() {
                      if (_mode == ChessGameMode.dailyPuzzle) {
                        _loadPuzzle(_currentPuzzle);
                      } else if (_mode == ChessGameMode.vsAI) {
                        _startVsAIGame();
                      } else {
                        _startPassAndPlayGame();
                      }
                    });
                  },
                  colors: colors,
                ),
                Visibility(
                  visible: _mode == ChessGameMode.dailyPuzzle,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: _buildNeoActionButton(
                    icon: Icons.lightbulb_outline_rounded,
                    tooltip: 'Show Hint',
                    onPressed: () {
                      NeoToast.show(
                        context,
                        'Hint: ${_currentPuzzle.hint}',
                        icon: Icons.lightbulb_rounded,
                        color: const Color(0xFFFACC15),
                        duration: const Duration(seconds: 4),
                      );
                    },
                    colors: colors,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeoModeTab(String label, ChessGameMode targetMode, ColorScheme colors) {
    final isSelected = _mode == targetMode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = targetMode;
          if (_mode == ChessGameMode.dailyPuzzle) {
            _startDailyPuzzle();
          } else if (_mode == ChessGameMode.vsAI) {
            _startVsAIGame();
          } else {
            _startPassAndPlayGame();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? Border.all(color: Colors.black, width: 1.5) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildNeoActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ColorScheme colors,
  }) {
    return PressableScale(
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2.2),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.black, size: 22),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
