import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'chess_piece_widget.dart';

class PawnPromotionDialog extends StatelessWidget {
  final bool isWhite;

  const PawnPromotionDialog({super.key, required this.isWhite});

  static Future<String?> show(BuildContext context, bool isWhite) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PawnPromotionDialog(isWhite: isWhite),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = [
      ('q', 'Queen', chess_lib.PieceType.QUEEN),
      ('r', 'Rook', chess_lib.PieceType.ROOK),
      ('b', 'Bishop', chess_lib.PieceType.BISHOP),
      ('n', 'Knight', chess_lib.PieceType.KNIGHT),
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Promote Pawn',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: options.map((opt) {
          return InkWell(
            onTap: () => Navigator.of(context).pop(opt.$1),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChessPieceWidget.fromType(
                    type: opt.$3,
                    isWhite: isWhite,
                    size: 38,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
