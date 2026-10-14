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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.black, width: 2.5),
      ),
      title: const Text(
        'Promote Pawn',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Row(
          children: options.map((opt) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(opt.$1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 2.0),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChessPieceWidget.fromType(
                            type: opt.$3,
                            isWhite: isWhite,
                            size: 36,
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              opt.$2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
