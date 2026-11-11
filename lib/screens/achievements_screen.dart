import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/settings_provider.dart';
import '../core/services/achievements.dart';
import '../core/services/engagement_service.dart';
import '../core/theme/neo.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/neo_toast.dart';

/// All achievements with progress bars, unlocked ones first.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AchievementsScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(engagementRevisionProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final data = Achievements.dataFrom(prefs, ref.read(engagementServiceProvider).load());
    final list = [...Achievements.all]
      ..sort((a, b) {
        final ua = a.unlocked(data), ub = b.unlocked(data);
        if (ua != ub) return ua ? -1 : 1;
        return (b.current(data) / b.target).compareTo(a.current(data) / a.target);
      });
    final done = list.where((a) => a.unlocked(data)).length;
    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Achievements',
      showBackButton: true,
      showInfoAction: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            '$done of ${list.length} unlocked',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -.5),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: done / list.length,
              minHeight: 10,
              backgroundColor: colors.surfaceContainerHigh,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 18),
          for (final a in list) _AchievementTile(achievement: a, data: data),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final AchievementData data;
  const _AchievementTile({required this.achievement, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final unlocked = achievement.unlocked(data);
    final current = achievement.current(data);
    return Semantics(
      label: '${achievement.title}. ${achievement.description}. '
          '${unlocked ? 'Unlocked' : '$current of ${achievement.target}'}',
      excludeSemantics: true,
      child: Opacity(
        opacity: unlocked ? 1 : .75,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Neo.border(2.2),
            boxShadow: unlocked ? Neo.shadow(3) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: unlocked ? achievement.color : colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Neo.border(1.8),
                ),
                child: Icon(
                  unlocked ? achievement.icon : Icons.lock_outline_rounded,
                  color: unlocked ? Colors.black : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(achievement.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    Text(
                      achievement.description,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.onSurfaceVariant),
                    ),
                    if (!unlocked && achievement.target > 1) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: current / achievement.target,
                                minHeight: 7,
                                backgroundColor: colors.surfaceContainerHigh,
                                color: achievement.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$current/${achievement.target}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (unlocked) const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Announces newly unlocked achievements after a win.
void announceAchievements(BuildContext context, WidgetRef ref) {
  final unlocked = Achievements.newlyUnlocked(
    ref.read(sharedPreferencesProvider),
    ref.read(engagementServiceProvider).load(),
  );
  if (unlocked.isEmpty || !context.mounted) return;
  final more = unlocked.length > 1 ? ' (+${unlocked.length - 1} more)' : '';
  Future.delayed(const Duration(milliseconds: 2300), () {
    if (!context.mounted) return;
    NeoToast.show(
      context,
      '🏆 Achievement unlocked: ${unlocked.first.title}$more',
      icon: unlocked.first.icon,
      color: unlocked.first.color,
      duration: const Duration(seconds: 3),
    );
  });
}
