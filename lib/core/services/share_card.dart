import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Draws a neo-brutalist result card as a PNG and opens the share sheet.
abstract final class ShareCard {
  static const _w = 1080.0;

  static Future<void> share({
    required String gameName,
    required Color accent,
    required String headline,
    required List<String> lines,
    List<List<Color>>? grid,
  }) async {
    final rows = grid ?? const <List<Color>>[];
    final gridHeight = rows.isEmpty ? 0.0 : rows.length * 112.0 + 40;
    final h = 560.0 + lines.length * 70 + gridHeight;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _w, h));

    // Background and card with a hard offset shadow.
    canvas.drawRect(Rect.fromLTWH(0, 0, _w, h), Paint()..color = const Color(0xFFF8FAFC));
    final card = RRect.fromRectAndRadius(Rect.fromLTWH(60, 60, _w - 140, h - 140), const Radius.circular(48));
    canvas.drawRRect(card.shift(const Offset(18, 18)), Paint()..color = Colors.black);
    canvas.drawRRect(card, Paint()..color = Colors.white);
    canvas.drawRRect(
      card,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    final band = RRect.fromRectAndCorners(
      Rect.fromLTWH(60, 60, _w - 140, 200),
      topLeft: const Radius.circular(48),
      topRight: const Radius.circular(48),
    );
    canvas.drawRRect(band, Paint()..color = accent);
    canvas.drawLine(const Offset(60, 260), Offset(_w - 80, 260), Paint()
      ..color = Colors.black
      ..strokeWidth = 8);

    double y = 105;
    y += _text(canvas, 'PUZZLEBOX', 110, y, 34, FontWeight.w900, Colors.black87, spacing: 4);
    _text(canvas, gameName, 110, y + 4, 64, FontWeight.w900, Colors.black);

    y = 310;
    y += _text(canvas, headline, 110, y, 60, FontWeight.w900, Colors.black) + 24;

    if (rows.isNotEmpty) {
      const cell = 96.0, gap = 16.0;
      final cols = rows.first.length;
      final left = (_w - 20 - (cols * cell + (cols - 1) * gap)) / 2;
      for (final (r, row) in rows.indexed) {
        for (final (c, color) in row.indexed) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(left + c * (cell + gap), y + r * (cell + gap), cell, cell),
            const Radius.circular(18),
          );
          canvas.drawRRect(rect, Paint()..color = color);
          canvas.drawRRect(
            rect,
            Paint()
              ..color = Colors.black
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6,
          );
        }
      }
      y += rows.length * (cell + gap) + 24;
    }
    for (final line in lines) {
      y += _text(canvas, line, 110, y, 44, FontWeight.w800, const Color(0xFF334155)) + 20;
    }

    final image = await recorder.endRecording().toImage(_w.toInt(), h.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/puzzlebox_result_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: '$headline in $gameName on Puzzlebox!',
    );
  }

  static double _text(
    Canvas canvas,
    String text,
    double x,
    double y,
    double size,
    FontWeight weight,
    Color color, {
    double spacing = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'PuzzleSans',
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: _w - 260);
    tp.paint(canvas, Offset(x, y));
    return tp.height;
  }
}
