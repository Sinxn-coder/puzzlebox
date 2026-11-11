import 'package:flutter/material.dart';
import 'package:puzzlebox/core/theme/neo.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'chess_piece_widget.dart';

class ChessBoardWidget extends StatelessWidget {
  final chess_lib.Chess game;
  final String? selectedSquare; // e.g. 'e4'
  final List<String> validMoves; // e.g. ['e5', 'e6']
  final Map<String, String>? lastMove; // {'from': 'e2', 'to': 'e4'}
  final bool isFlipped; // true if Black perspective
  final ValueChanged<String> onSquareTap;

  const ChessBoardWidget({
    super.key,
    required this.game,
    required this.selectedSquare,
    required this.validMoves,
    required this.lastMove,
    required this.isFlipped,
    required this.onSquareTap,
  });


  /// Finds king square if in check
  String? _getCheckedKingSquare() {
    if (!game.in_check) return null;
    final kingColor = game.turn;
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

    for (int rank = 1; rank <= 8; rank++) {
      for (final file in files) {
        final squareId = '$file$rank';
        final p = game.get(squareId);
        if (p != null && p.type == chess_lib.PieceType.KING && p.color == kingColor) {
          return squareId;
        }
      }
    }
    return null;
  }

  /// Display position (column, row) of a square for the current orientation.
  (int, int) _cell(String square) {
    final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(square.substring(1));
    return isFlipped ? (7 - file, rank - 1) : (file, 8 - rank);
  }

  Widget _flyingPiece(double cell, double t, String to) {
    final (fx, fy) = _cell(lastMove!['from']!);
    final (tx, ty) = _cell(to);
    return Positioned(
      left: (fx + (tx - fx) * t) * cell,
      top: (fy + (ty - fy) * t) * cell,
      width: cell,
      height: cell,
      child: IgnorePointer(
        child: Center(child: ChessPieceWidget(piece: game.get(to)!, size: 36)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final checkedKing = _getCheckedKingSquare();

    final lightSquareColor = const Color(0xFFF0D9B5);
    final darkSquareColor = const Color(0xFFB58863);
    final selectedColor = const Color(0xFFBAC64B);
    final lastMoveColor = const Color(0x80CDD26A);
    final checkColor = const Color(0xFFE63946);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Neo.border(2.5),
          boxShadow: Neo.shadow(4),
        ),
        clipBehavior: Clip.antiAlias,
        child: TweenAnimationBuilder<double>(
          // Each new move glides its piece from the old square to the new one.
          key: ValueKey('${game.fen}|${lastMove?['from']}${lastMove?['to']}'),
          tween: Tween(begin: lastMove == null || reduceMotion ? 1.0 : 0.0, end: 1.0),
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            final String? hidden = (t < 1 && lastMove != null) ? lastMove!['to'] : null;
            return LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  Column(
          children: List.generate(8, (rankIndex) {
            final actualRank = isFlipped ? rankIndex + 1 : 8 - rankIndex;

            return Expanded(
              child: Row(
                children: List.generate(8, (fileIndex) {
                  final actualFileIndex = isFlipped ? 7 - fileIndex : fileIndex;
                  final fileChar = String.fromCharCode('a'.codeUnitAt(0) + actualFileIndex);
                  final squareId = '$fileChar$actualRank';

                  final isLight = (actualRank + actualFileIndex) % 2 != 0;
                  final piece = squareId == hidden ? null : game.get(squareId);
                  final isSelected = selectedSquare == squareId;
                  final isValidDestination = validMoves.contains(squareId);
                  final isLastMove = lastMove != null &&
                      (lastMove!['from'] == squareId || lastMove!['to'] == squareId);
                  final isKingInCheck = checkedKing == squareId;

                  Color squareColor = isLight ? lightSquareColor : darkSquareColor;
                  if (isSelected) {
                    squareColor = selectedColor;
                  } else if (isLastMove) {
                    squareColor = Color.alphaBlend(lastMoveColor, squareColor);
                  }

                  return Expanded(
                    child: GestureDetector(
                      key: ValueKey('chess_square_$squareId'),
                      onTap: () => onSquareTap(squareId),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isKingInCheck ? checkColor : squareColor,
                            ),
                            child: Center(
                              child: piece != null
                                  ? ChessPieceWidget(
                                      piece: piece,
                                      size: 36,
                                    )
                                  : null,
                            ),
                          ),
                          // Coordinate labels
                          if (fileIndex == 0)
                            Positioned(
                              top: 2,
                              left: 3,
                              child: Text(
                                '$actualRank',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isLight ? darkSquareColor : lightSquareColor,
                                ),
                              ),
                            ),
                          if (rankIndex == 7)
                            Positioned(
                              bottom: 2,
                              right: 3,
                              child: Text(
                                fileChar,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isLight ? darkSquareColor : lightSquareColor,
                                ),
                              ),
                            ),
                          // Legal move destination dot indicator
                          if (isValidDestination)
                            Center(
                              child: Container(
                                width: piece != null ? 36 : 14,
                                height: piece != null ? 36 : 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: piece != null
                                      ? colors.error.withValues(alpha: 0.4)
                                      : Colors.black.withValues(alpha: 0.25),
                                  border: piece != null
                                      ? Border.all(color: colors.error, width: 2.5)
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
                  if (hidden != null && game.get(hidden) != null)
                    _flyingPiece(box.maxWidth / 8, t, hidden),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
