import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/game_catalog.dart';
import '../core/providers/settings_provider.dart';
import '../core/routing/game_router.dart';
import '../core/services/date_service.dart';
import '../core/services/engagement_service.dart';
import '../core/services/practice_service.dart';
import '../core/services/session_resume.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/neo.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/pressable_scale.dart';
import 'streak_screen.dart';

const _categoryIcons = {
  'Words': Icons.spellcheck_rounded,
  'Logic': Icons.psychology_rounded,
  'Patterns': Icons.auto_awesome_mosaic_rounded,
};

/// Home: Today's picks, then unfinished puzzles, then every game by category.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openGame(GameInfo game) async {
    final screen = GameRouter.getScreenForGameId(game.id);
    if (screen == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final primaryAccent = AppTheme.getAccentColor(
      const Color(0xFFFACC15),
      settings.palette,
    );

    ref.watch(engagementRevisionProvider);
    final engagement = ref.read(engagementServiceProvider).load();
    final practice = ref.read(practiceServiceProvider);
    final today = DateService.todayKey();
    final playedToday = {
      for (final item in engagement.history)
        if ((item['at'] as String? ?? '').startsWith(today)) item['game'],
    };
    final picks = GameCatalog.todaysPicks(DateTime.now());
    final resumable = SessionResume.all(
      prefs,
      GameCatalog.all.map((g) => g.id),
    );
    final resumeIds = {for (final r in resumable) r.gameId};

    final searching = _query.trim().isNotEmpty;
    final results = GameCatalog.all
        .where(
          (g) => '${g.name} ${g.tagline} ${g.category}'.toLowerCase().contains(
            _query.trim().toLowerCase(),
          ),
        )
        .toList();

    Widget grid(List<GameInfo> games) => SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          mainAxisSpacing: 22,
          crossAxisSpacing: 14,
          mainAxisExtent: 155,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final game = games[index];
          return _FolderCard(
            game: game,
            solvedCount: practice.getSolvedCount(game.id),
            inProgress: resumeIds.contains(game.id),
            onTap: () => _openGame(game),
          );
        }, childCount: games.length),
      ),
    );

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: CustomScrollView(
          slivers: [
            // Header bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    _NeoSquareIconButton(
                      icon: Icons.tune_rounded,
                      tooltip: 'Display settings',
                      onPressed: _openSettings,
                      backgroundColor: primaryAccent,
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: '${engagement.currentStreak} day streak. Open streak details',
                      excludeSemantics: true,
                      child: PressableScale(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => StreakScreen.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: primaryAccent,
                              borderRadius: BorderRadius.circular(12),
                              border: Neo.border(2.5),
                              boxShadow: Neo.shadow(3),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 18,
                                  color: engagement.currentStreak > 0
                                      ? const Color(0xFFF97316)
                                      : Colors.black87,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${engagement.currentStreak}d Streak',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Headline
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Semantics(
                  header: true,
                  child: Text(
                    _greeting(),
                    style: TextStyle(
                      fontFamily: 'PuzzleSans',
                      fontSize: 30,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),

            // "Next up": only when there is something important to say.
            if (_nextUp(engagement, today, picks, playedToday, resumable)
                case final nextUp?)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _NextUpCard(
                    data: nextUp,
                    onTap: () => _openGame(nextUp.game),
                  ),
                ),
              ),

            // Today hero
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _TodayCard(
                  picks: picks,
                  done: {
                    for (final g in picks)
                      if (playedToday.contains(g.id)) g.id,
                  },
                  accent: primaryAccent,
                  palette: settings.palette,
                  onOpen: _openGame,
                ),
              ),
            ),

            // Continue playing
            if (resumable.isNotEmpty) ...[
              const _SectionHeader(
                title: 'Continue Playing',
                icon: Icons.play_circle_outline_rounded,
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  // Grow with the text size so the two text lines never clip.
                  height: 70 + MediaQuery.textScalerOf(context).scale(26),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                    itemCount: resumable.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final info = resumable[i];
                      final game = GameCatalog.byId(info.gameId)!;
                      return _ContinueCard(
                        game: game,
                        info: info,
                        color: AppTheme.getAccentColor(
                          game.color,
                          settings.palette,
                        ),
                        onTap: () => _openGame(game),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
            ],

            // Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Neo.border(2.5),
                    boxShadow: Neo.shadow(3),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      hintText: 'Search puzzles...',
                      hintStyle: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white : Colors.black,
                        size: 22,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear search',
                              icon: Icon(
                                Icons.close_rounded,
                                color: isDark ? Colors.white : Colors.black,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My Puzzles',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                        ),
                      ),
                    ),
                    Text(
                      searching
                          ? '${results.length} found'
                          : '${GameCatalog.all.length} games',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (searching && results.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 44,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No games match "$_query"',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              )
            else if (searching)
              grid(results)
            else
              for (final category in GameCatalog.categories) ...[
                _SectionHeader(
                  title: category,
                  icon: _categoryIcons[category]!,
                  trailing:
                      '${GameCatalog.all.where((g) => g.category == category).length}',
                ),
                grid(
                  GameCatalog.all
                      .where((g) => g.category == category)
                      .toList(),
                ),
              ],
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Late-night\npuzzling?';
    if (hour < 12) return 'Good morning.\nReady to solve?';
    if (hour < 18) return 'Good afternoon.\nTime for a puzzle?';
    return 'Good evening.\nOne more puzzle?';
  }
}

typedef _NextUp = ({GameInfo game, String title, String subtitle, IconData icon});

/// Picks the single most useful prompt: protect a streak, or help a brand-new
/// player start. Returns null otherwise so Home stays uncluttered.
_NextUp? _nextUp(
  EngagementSnapshot engagement,
  String today,
  List<GameInfo> picks,
  Set<Object?> playedToday,
  List<ResumeInfo> resumable,
) {
  GameInfo bestGame() {
    if (resumable.isNotEmpty) return GameCatalog.byId(resumable.first.gameId)!;
    return picks.firstWhere(
      (g) => !playedToday.contains(g.id),
      orElse: () => picks.first,
    );
  }

  if (engagement.currentStreak > 0 && !engagement.playDays.contains(today)) {
    final game = bestGame();
    return (
      game: game,
      title: 'Keep your ${engagement.currentStreak}-day streak',
      subtitle: 'Solve one puzzle today. Try ${game.name}.',
      icon: Icons.local_fire_department_rounded,
    );
  }
  if (engagement.totalCompleted == 0 && engagement.history.isEmpty) {
    final game = GameCatalog.byId('daily_five')!;
    return (
      game: game,
      title: 'New here? Start with ${game.name}',
      subtitle: 'A quick word game to warm up.',
      icon: Icons.waving_hand_rounded,
    );
  }
  return null;
}

class _NextUpCard extends StatelessWidget {
  final _NextUp data;
  final VoidCallback onTap;
  const _NextUpCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : Colors.black;
    return Semantics(
      button: true,
      label: '${data.title}. ${data.subtitle}',
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Neo.border(2.5),
                boxShadow: Neo.shadow(3),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB923C),
                      borderRadius: BorderRadius.circular(12),
                      border: Neo.border(2),
                    ),
                    child: Icon(data.icon, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: ink),
                        ),
                        Text(
                          data.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.play_arrow_rounded, color: ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? trailing;

  const _SectionHeader({required this.title, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Semantics(
          header: true,
          child: Row(
            children: [
              Icon(icon, size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: colors.onSurface,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's featured trio with a progress ring.
class _TodayCard extends StatelessWidget {
  final List<GameInfo> picks;
  final Set<String> done;
  final Color accent;
  final int palette;
  final ValueChanged<GameInfo> onOpen;

  const _TodayCard({
    required this.picks,
    required this.done,
    required this.accent,
    required this.palette,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = picks.isEmpty ? 0.0 : done.length / picks.length;
    final allDone = done.length == picks.length;
    final weekday = const [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ][DateTime.now().weekday - 1];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(22),
        border: Neo.border(2.5),
        boxShadow: Neo.shadow(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY · ${weekday.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allDone ? 'All three done. Nice!' : "Today's Trio",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      allDone
                          ? 'Come back tomorrow for a new set.'
                          : 'One word, one logic, one pattern puzzle.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: '${done.length} of ${picks.length} done today',
                excludeSemantics: true,
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, _) => CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.black.withValues(alpha: .12),
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        '${done.length}/${picks.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (i, game) in picks.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _TodayTile(
                    game: game,
                    done: done.contains(game.id),
                    color: AppTheme.getAccentColor(game.color, palette),
                    isDark: isDark,
                    onTap: () => onOpen(game),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayTile extends StatelessWidget {
  final GameInfo game;
  final bool done;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _TodayTile({
    required this.game,
    required this.done,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${game.name}, ${game.category}${done ? ', done today' : ''}',
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Neo.border(2),
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GameBadge(game: game, color: color, size: 34, hero: false),
                      if (done)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                              border: Neo.border(1.5),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 11,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    game.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    game.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF525252),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final GameInfo game;
  final ResumeInfo info;
  final Color color;
  final VoidCallback onTap;

  const _ContinueCard({
    required this.game,
    required this.info,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final details = [
      if (game.id == 'chess') info.difficulty else if (info.isDaily) 'Daily' else 'Unlimited',
      if (game.id != 'chess') info.difficulty,
      if (info.elapsedSeconds > 0) formatClock(info.elapsedSeconds),
    ].join(' · ');
    return Semantics(
      button: true,
      label: 'Continue ${game.name}, $details',
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 210,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Neo.border(2.5),
                boxShadow: Neo.shadow(3),
              ),
              child: Row(
                children: [
                  GameBadge(game: game, color: color, size: 40, hero: false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF525252),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_arrow_rounded,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Neo-Brutalist square action button with hard border and offset shadow.
class _NeoSquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const _NeoSquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.primary,
        borderRadius: BorderRadius.circular(14),
        border: Neo.border(2.5),
        boxShadow: Neo.shadow(3),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.black, size: 22),
        onPressed: onPressed,
      ),
    );
  }
}

/// Folder-tab game card. Its icon flies into the game screen's title bar.
class _FolderCard extends ConsumerWidget {
  final GameInfo game;
  final int solvedCount;
  final bool inProgress;
  final VoidCallback onTap;

  const _FolderCard({
    required this.game,
    required this.solvedCount,
    required this.inProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = ref.watch(settingsProvider.select((s) => s.palette));
    final accentColor = AppTheme.getAccentColor(game.color, palette);

    return Semantics(
      button: true,
      label: [
        game.name,
        game.tagline,
        if (inProgress) 'in progress, tap to continue',
        if (solvedCount > 0) '$solvedCount solved',
      ].join(', '),
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('${game.id}_folder'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Folder body
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Neo.border(2.5),
                    boxShadow: Neo.shadow(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GameBadge(game: game, color: accentColor),
                          const Spacer(),
                          if (inProgress)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8),
                                borderRadius: BorderRadius.circular(6),
                                border: Neo.border(1.5),
                              ),
                              child: const Text(
                                'CONTINUE',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            )
                          else if (solvedCount > 0)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                                border: Neo.border(1.5),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Colors.black,
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: -.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            game.tagline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF525252),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Folder tab
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      border: Neo.border(2.5),
                    ),
                    child: Text(
                      game.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
