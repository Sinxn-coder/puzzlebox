import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'chess_vectors.dart';

/// Renders a crisp 2D vector Staunton chess piece with consistent styling for both colors.
class ChessPieceWidget extends StatelessWidget {
  final chess_lib.Piece? piece;
  final double size;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    this.size = 34,
  });

  /// Factory helper for creating a piece from type and color
  factory ChessPieceWidget.fromType({
    Key? key,
    required chess_lib.PieceType type,
    required bool isWhite,
    double size = 34,
  }) {
    return ChessPieceWidget(
      key: key,
      piece: chess_lib.Piece(type, isWhite ? chess_lib.Color.WHITE : chess_lib.Color.BLACK),
      size: size,
    );
  }

  static String getPieceKey(chess_lib.Piece? piece) {
    if (piece == null) return '';
    final prefix = piece.color == chess_lib.Color.WHITE ? 'w' : 'b';
    final typeStr = switch (piece.type) {
      chess_lib.PieceType.PAWN => 'P',
      chess_lib.PieceType.KNIGHT => 'N',
      chess_lib.PieceType.BISHOP => 'B',
      chess_lib.PieceType.ROOK => 'R',
      chess_lib.PieceType.QUEEN => 'Q',
      chess_lib.PieceType.KING => 'K',
      _ => 'P',
    };
    return '$prefix$typeStr';
  }

  @override
  Widget build(BuildContext context) {
    if (piece == null) return const SizedBox.shrink();
    final key = getPieceKey(piece);
    final svgString = chessPieceVectors[key];
    if (svgString == null) return const SizedBox.shrink();

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
