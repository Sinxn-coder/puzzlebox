import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/game_catalog.dart';
import '../core/providers/settings_provider.dart';
import '../core/routing/game_router.dart';
import '../core/services/engagement_service.dart';
import '../core/services/practice_service.dart';
import '../core/services/stats_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/neo.dart';
import '../core/widgets/app_scaffold.dart';

/// Detailed progress for a single game: solve-time trend, difficulty split
/// and (for guessing games) the guess distribution.
class GameStatsScreen extends ConsumerWidget {
  final String gameId;
  const GameStatsScreen({super.key, required this.gameId});

  static Future<void> open(BuildContext context, String gameId) =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameStatsScreen(gameId: gameId)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = GameCatalog.byId(gameId)!;
    final palette = ref.watch(settingsProvider.select((s) => s.palette));
    ref.watch(engagementRevisionProvider);
    final engagement = ref.read(engagementServiceProvider).load();
    final stats = ref.read(statsServiceProvider).loadStats(gameId);
    final unlimited = ref.read(practiceServiceProvider).getSolvedCount(gameId);
    final color = AppTheme.getAccentColor(game.color, palette);

    final wins = engagement.history.where((h) => h['game'] == gameId).toList();
    final timed = [
      for (final h in wins)
        if ((h['seconds'] as int? ?? 0) > 0) h['seconds'] as int,
    ];
    final recent = timed.length > 20 ? timed.sublist(timed.length - 20) : timed;
    final best = timed.isEmpty ? null : timed.reduce(math.min);
    final average = timed.isEmpty
        ? null
        : (timed.reduce((a, b) => a + b) / timed.length).round();
    final byDifficulty = {
      for (final level in const ['Easy', 'Medium', 'Hard'])
        level: wins.where((h) => h['difficulty'] == level).length,
    };

    final hasAnything = wins.isNotEmpty || stats.gamesPlayed > 0 || unlimited > 0;

    return AppScaffold(
      title: '${game.name} Stats',
      showBackButton: true,
      showInfoAction: false,
      body: !hasAnything
          ? _EmptyGameStats(game: game, color: color)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Row(
                  children: [
                    GameBadge(game: game, color: color, size: 46, hero: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.6,
                            ),
                          ),
                          Text(
                            game.tagline,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Rows (not a fixed-ratio grid) so tiles grow with large text.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _Metric('Wins', '${wins.length}', Icons.emoji_events_rounded)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric('Best time', best == null ? '—' : formatClock(best), Icons.bolt_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _Metric('Average', average == null ? '—' : formatClock(average), Icons.timer_rounded),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric(
                          'Daily win rate',
                          stats.gamesPlayed == 0 ? '—' : '${stats.winPercentage.round()}%',
                          Icons.calendar_today_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _Heading('SOLVE TIME', 'Last 20 timed wins, oldest to newest'),
                const SizedBox(height: 10),
                _Card(
                  child: recent.length < 2
                      ? const _ChartPlaceholder(
                          'Solve two puzzles to see your time trend.',
                        )
                      : Semantics(
                          label:
                              'Solve time chart. Latest ${formatClock(recent.last)}, best ${formatClock(best!)}',
                          excludeSemantics: true,
                          child: SizedBox(
                            height: 160,
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: _TrendPainter(
                                values: recent,
                                line: Theme.of(context).colorScheme.onSurface,
                                fill: color,
                                grid: Theme.of(context).colorScheme.onSurface.withValues(alpha: .12),
                                labelStyle: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                if (game.tracksGuesses) ...[
                  const SizedBox(height: 24),
                  const _Heading('GUESS DISTRIBUTION', 'Daily wins by number of guesses'),
                  const SizedBox(height: 10),
                  _Card(
                    child: stats.distribution.isEmpty
                        ? const _ChartPlaceholder('Win a daily puzzle to fill this in.')
                        : _Bars(
                            rows: [
                              for (var i = 1; i <= 6; i++)
                                ('$i', stats.distribution[i] ?? 0),
                            ],
                            color: color,
                          ),
                  ),
                ],
                const SizedBox(height: 24),
                const _Heading('BY DIFFICULTY', 'Wins at each level'),
                const SizedBox(height: 10),
                _Card(
                  child: _Bars(
                    rows: [
                      for (final e in byDifficulty.entries) (e.key, e.value),
                    ],
                    color: color,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Daily played ${stats.gamesPlayed} · Unlimited solved $unlimited · Daily best streak ${stats.maxStreak}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyGameStats extends StatelessWidget {
  final GameInfo game;
  final Color color;
  const _EmptyGameStats({required this.game, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameBadge(game: game, color: color, size: 72, hero: false),
            const SizedBox(height: 18),
            Text(
              'No ${game.name} wins yet',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Solve your first puzzle and your times, streaks and charts will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                final screen = GameRouter.getScreenForGameId(game.id);
                if (screen == null) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => screen),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Play ${game.name}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Heading(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Neo.border(2.5),
        boxShadow: Neo.shadow(3),
      ),
      child: child,
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Metric(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Card(
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final String text;
  const _ChartPlaceholder(this.text);

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 90,
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

/// Horizontal bar chart; the largest row fills the width.
class _Bars extends StatelessWidget {
  final List<(String, int)> rows;
  final Color color;
  const _Bars({required this.rows, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxValue = rows.fold<int>(0, (m, r) => math.max(m, r.$2));
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final (label, value) in rows)
          Semantics(
            label: '$label: $value',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final fraction = maxValue == 0 ? 0.0 : value / maxValue;
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: fraction),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (_, f, _) => Container(
                              height: 22,
                              width: math.max(28, c.maxWidth * f),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: value == 0 ? colors.surfaceContainerHigh : color,
                                borderRadius: BorderRadius.circular(6),
                                border: Neo.border(1.5),
                              ),
                              child: Text(
                                '$value',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: value == 0 ? colors.onSurface : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Line + area chart of solve times. Lower is better, so the axis is labelled
/// with the fastest and slowest times.
class _TrendPainter extends CustomPainter {
  final List<int> values;
  final Color line;
  final Color fill;
  final Color grid;
  final TextStyle labelStyle;

  _TrendPainter({
    required this.values,
    required this.line,
    required this.fill,
    required this.grid,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0;
    const top = 8.0;
    const bottom = 8.0;
    final w = size.width - left;
    final h = size.height - top - bottom;
    final minV = values.reduce(math.min).toDouble();
    final maxV = values.reduce(math.max).toDouble();
    final span = math.max(1.0, maxV - minV);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = top + h * i / 2;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
    }

    void label(String text, double y) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: left - 4);
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    label(formatClock(maxV.round()), top);
    label(formatClock(minV.round()), top + h);

    Offset point(int i) => Offset(
      left + (values.length == 1 ? w / 2 : w * i / (values.length - 1)),
      top + h * (1 - (values[i] - minV) / span),
    );

    final path = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(point(i).dx, point(i).dy);
    }
    final area = Path.from(path)
      ..lineTo(point(values.length - 1).dx, top + h)
      ..lineTo(point(0).dx, top + h)
      ..close();
    canvas.drawPath(area, Paint()..color = fill.withValues(alpha: .35));
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = fill;
    final ring = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(point(i), 4, dot);
      canvas.drawCircle(point(i), 4, ring);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.line != line || old.fill != fill;
}
