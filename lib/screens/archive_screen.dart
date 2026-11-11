import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/game_catalog.dart';
import '../core/providers/settings_provider.dart';
import '../core/routing/game_router.dart';
import '../core/services/date_service.dart';
import '../core/services/special_puzzles.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/neo.dart';
import '../core/widgets/app_scaffold.dart';

/// Replay any daily puzzle from the last [SpecialPuzzles.archiveDays] days.
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ArchiveScreen()),
  );

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  String _game = SpecialPuzzles.games.first;

  Future<void> _play(DateTime day) async {
    final key = DateService.dateKey(day);
    PuzzleLaunch.pending = PuzzleLaunch.archive(_game, key);
    final screen = GameRouter.getScreenForGameId(_game);
    if (screen == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    PuzzleLaunch.pending = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.read(sharedPreferencesProvider);
    final palette = ref.watch(settingsProvider.select((s) => s.palette));
    final done = SpecialPuzzles.archiveDone(prefs, _game);
    final today = DateService.today();
    final days = [
      for (var i = 0; i < SpecialPuzzles.archiveDays; i++)
        DateTime(today.year, today.month, today.day - i),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final game = GameCatalog.byId(_game)!;
    final accent = AppTheme.getAccentColor(game.color, palette);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return AppScaffold(
      title: 'Puzzle Archive',
      showBackButton: true,
      showInfoAction: false,
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              children: [
                for (final id in SpecialPuzzles.games)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(GameCatalog.byId(id)!.name),
                      selected: id == _game,
                      onSelected: (_) => setState(() => _game = id),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                GameBadge(game: game, color: accent, size: 32, hero: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${done.where((d) => days.any((x) => DateService.dateKey(x) == d)).length} of ${days.length} days solved',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 110,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: days.length,
              itemBuilder: (context, i) {
                final d = days[i];
                final key = DateService.dateKey(d);
                final solved = done.contains(key);
                final isToday = i == 0;
                return Semantics(
                  button: true,
                  label: '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}${solved ? ', solved' : ''}',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _play(d),
                    child: Container(
                      decoration: BoxDecoration(
                        color: solved ? accent : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Neo.border(isToday ? 3 : 2),
                        boxShadow: Neo.shadow(2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday ? 'TODAY' : weekdays[d.weekday - 1].toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: solved ? Colors.black87 : colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: solved ? Colors.black : colors.onSurface,
                            ),
                          ),
                          Text(
                            months[d.month - 1],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: solved ? Colors.black87 : colors.onSurfaceVariant,
                            ),
                          ),
                          if (solved)
                            const Icon(Icons.check_circle_rounded, size: 16, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
