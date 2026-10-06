import 'dart:io';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'engagement_service.dart';

class PdfExportService {
  static Future<void> generateAndShareStats({
    required EngagementSnapshot engagement,
    required Color accentColor,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromInt(accentColor.toARGB32());
    final bgColor = const PdfColor.fromInt(0xFFF8FAFC);
    
    // Load SVG logo
    String svgLogo;
    try {
      svgLogo = await rootBundle.loadString('assets/puzzlebox-logo.svg');
    } catch (_) {
      svgLogo = '';
    }

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: bgColor),
          ),
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 72,
                      height: 72,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                        border: pw.Border.all(color: PdfColors.black, width: 3),
                      ),
                      alignment: pw.Alignment.center,
                      child: svgLogo.isNotEmpty 
                        ? pw.SvgImage(svg: svgLogo, width: 44, height: 44)
                        : pw.Text('P', style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ),
                    pw.SizedBox(width: 24),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Puzzlebox', style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${engagement.currentStreak} Day Streak - Best ${engagement.bestStreak}',
                          style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 50),

                // Metrics
                pw.Text('OVERVIEW', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, letterSpacing: 2, color: PdfColors.black)),
                pw.SizedBox(height: 16),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildMetricCard('Solved', '${engagement.totalCompleted}', primaryColor)),
                    pw.SizedBox(width: 16),
                    pw.Expanded(child: _buildMetricCard('Hard Wins', '${engagement.hardWins}', primaryColor)),
                    pw.SizedBox(width: 16),
                    pw.Expanded(child: _buildMetricCard('Time', _time(engagement.totalSeconds), primaryColor)),
                  ],
                ),
                pw.SizedBox(height: 50),

                // Recent Wins
                pw.Text('RECENT WINS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, letterSpacing: 2, color: PdfColors.black)),
                pw.SizedBox(height: 16),
                if (engagement.history.isEmpty)
                  pw.Text('No recent wins.', style: pw.TextStyle(color: PdfColors.grey700, fontSize: 14))
                else
                  ...engagement.history.reversed.take(6).map((item) {
                    final game = item['game'] as String;
                    final diff = item['difficulty'] as String;
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 14),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                        border: pw.Border.all(color: PdfColors.black, width: 2.5),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(game.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.black)),
                          pw.Text(diff, style: pw.TextStyle(color: PdfColors.grey700, fontSize: 14)),
                        ],
                      ),
                    );
                  }),
                
                pw.Spacer(),
                // Footer
                pw.Center(
                  child: pw.Text('Generated by Puzzlebox', style: pw.TextStyle(color: PdfColors.grey500, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );

    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/puzzlebox_stats_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Check out my Puzzlebox statistics!',
    );
  }

  static pw.Widget _buildMetricCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
        border: pw.Border.all(color: PdfColors.black, width: 3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
          pw.SizedBox(height: 6),
          pw.Text(title, style: pw.TextStyle(fontSize: 14, color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static String _time(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    return minutes < 60 ? '${minutes}m' : '${minutes ~/ 60}h ${minutes % 60}m';
  }
}
