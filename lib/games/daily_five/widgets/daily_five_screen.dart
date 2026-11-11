import '../../../core/services/engagement_service.dart';
import '../../../core/theme/feedback_colors.dart';
import '../../../core/services/share_card.dart';
import '../../../screens/achievements_screen.dart';
import 'dart:async';
import '../../../core/providers/settings_provider.dart';
import '../models/letter_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/date_service.dart';
import '../../../core/services/practice_service.dart';
import '../../../core/services/session_resume.dart';
import '../../../core/services/hint_budget.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../models/daily_five_state.dart';
import '../providers/daily_five_provider.dart';
import 'game_board.dart';
import 'keyboard_widget.dart';
import 'result_modal.dart';

import '../../../core/widgets/game_mode_toggle.dart';
import '../../../core/widgets/neo_toast.dart';
import '../../../core/widgets/fixed_slot_widgets.dart';
import '../../../core/widgets/daily_done_banner.dart';
import '../../../core/services/app_feedback_service.dart';
import '../../../core/widgets/streak_earned_dialog.dart';
import '../../../core/widgets/celebration_burst.dart';

/// Main screen for the Daily Five word-guessing game.
class DailyFiveScreen extends ConsumerStatefulWidget {
  const DailyFiveScreen({super.key});

  @override
  ConsumerState<DailyFiveScreen> createState() => _DailyFiveScreenState();
}

class _DailyFiveScreenState extends ConsumerState<DailyFiveScreen> {
  bool _modalShown = false;
  final HintBudget _hints = HintBudget();
  String? _hintAnswer;
  GameMode _mode = GameMode.practice;
  Timer? _nextTimer;
  String _difficulty = 'Medium';
  int _practiceSolvedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPracticeCount();
    _difficulty =
        ref
            .read(sharedPreferencesProvider)
            .getString('difficulty_daily_five') ??
        'Medium';
    // Reopen today's daily word if that is the one left unfinished.
    final resume = SessionResume.read(
      ref.read(sharedPreferencesProvider),
      'daily_five',
    );
    if (resume != null && resume.isDaily) _mode = GameMode.daily;
  }

  Future<void> _loadPracticeCount() async {
    final service = ref.read(practiceServiceProvider);
    setState(() {
      _practiceSolvedCount = service.getSolvedCount('daily_five');
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(dailyFiveProvider(_mode));
    // A new word gets a fresh hint budget.
    if (_hintAnswer != game.answer) {
      _hintAnswer = game.answer;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hints.reset();
      });
    }

    if (game.isComplete && !game.isAnimating && !_modalShown) {
      _modalShown = true;
      if (_mode == GameMode.practice && game.phase == GamePhase.won) {
        _practiceSolvedCount++;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (game.phase == GamePhase.won) {
          AppFeedbackService.victory(ref);
          showCelebrationBurst(context);
          announceAchievements(context, ref);
          if (game.streakEarnedToday) {
            StreakEarnedDialog.show(context, streak: game.earnedStreak);
          }
        } else {
          AppFeedbackService.error(ref);
        }
        final daily = _mode == GameMode.daily;
        NeoToast.show(
          context,
          game.phase == GamePhase.won
              ? (daily
                    ? "Today's word solved! A new one arrives tomorrow."
                    : 'Solved! A fresh word is next.')
              : (daily
                    ? 'The word was ${game.answer}. A new one arrives tomorrow.'
                    : 'The word was ${game.answer}. Try the next one.'),
          icon: game.phase == GamePhase.won ? Icons.check_circle_rounded : Icons.info_rounded,
          color: game.phase == GamePhase.won ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8),
        );
        _nextTimer?.cancel();
        // Daily stays on the finished board with a "done today" banner.
        if (daily) return;
        _nextTimer = Timer(
          Duration(seconds: game.phase == GamePhase.won ? 2 : 4),
          () {
            if (mounted) _next();
          },
        );
      });
    }

    final dateKey = DateService.todayKey();

    return AppScaffold(
      title: _mode == GameMode.daily
          ? 'Daily Five #${game.puzzleNumber}'
          : 'Daily Five — Unlimited',
      showBackButton: true,
            gameId: 'daily_five',
      hintBadge: _hints.badge,
      hintGate: () {
        if (game.isComplete) return false;
        if (_hints.tryUse()) return true;
        NeoToast.show(
          context,
          'Next hint in ${HintBudget.format(_hints.waitLeft!)}. Give it a try first!',
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFFFACC15),
        );
        return false;
      },
      onHint: () => _showHints(context, dateKey),
      menuItems: [
        (
          ref.watch(settingsProvider).hardModeEnabled
              ? Icons.toggle_on_rounded
              : Icons.toggle_off_outlined,
          'Hard Mode: ${ref.watch(settingsProvider).hardModeEnabled ? 'On' : 'Off'}',
          () {
            final on = !ref.read(settingsProvider).hardModeEnabled;
            ref.read(settingsProvider.notifier).setHardModeEnabled(on);
            NeoToast.show(
              context,
              on
                  ? 'Hard Mode on: revealed hints must be used in later guesses.'
                  : 'Hard Mode off.',
              icon: Icons.psychology_rounded,
            );
          },
        ),
      ],
      actions: [
        AppBarIconButton(
          icon: Icons.bar_chart_rounded,
          tooltip: 'Stats',
          onTap: () => _showResultModal(context),
        ),
      ],
      // Physical keyboards (tablets, Chromebooks, Bluetooth) type too.
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) => _onKey(event, game),
        child: Column(
        children: [
          GameControlBar(
            mode: _mode,
            practiceSolvedCount: _practiceSolvedCount,
            onModeChanged: (m) => _onModeChanged(m),
            difficulty: _difficulty,
            onDifficultyChanged: (d) async {
              if (d == _difficulty) return;
              await ref
                  .read(sharedPreferencesProvider)
                  .setString('difficulty_daily_five', d);
              if (!mounted) return;
              setState(() => _difficulty = d);
              _next();
            },
            onNext: () async {
              final started = game.currentRow > 0 && !game.isComplete;
              if (started && !await confirmSkipPuzzle(context)) return;
              if (mounted) _next();
            },
          ),
          if (_mode == GameMode.daily && game.isComplete && !game.isAnimating)
            DailyDoneBanner(
              onPlayUnlimited: () => _onModeChanged(GameMode.practice),
              onShare: () => _shareDaily(game),
            ),
          _ToastBar(mode: _mode),
          SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SmoothBoardTransition(
                  keyId: 'd5_${_mode}_${_difficulty}_${game.puzzleNumber}',
                  child: GameBoard(mode: _mode),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          KeyboardWidget(mode: _mode),
          SizedBox(height: 16),
        ],
      ),
      ),
    );
  }

  /// Result card with the colour grid (no letters, so no spoilers).
  Future<void> _shareDaily(DailyFiveState game) async {
    final rows = [
      for (final row in game.board.take(game.currentRow))
        [
          for (final tile in row)
            switch (tile.state) {
              LetterState.correct => FeedbackColors.correct,
              LetterState.present => FeedbackColors.present,
              _ => const Color(0xFF94A3B8),
            },
        ],
    ];
    final won = game.phase == GamePhase.won;
    final streak = ref.read(engagementServiceProvider).load().currentStreak;
    try {
      await ShareCard.share(
        gameName: 'Daily Five #${game.puzzleNumber}',
        accent: const Color(0xFF4ADE80),
        headline: won ? 'Solved in ${game.currentRow}/6' : 'X/6 today',
        grid: rows,
        lines: [
          if (_hints.used == 0) '⭐ No hints used' else 'Hints used: ${_hints.used}',
          if (streak > 0) '🔥 $streak-day streak',
        ],
      );
    } catch (_) {
      if (mounted) {
        NeoToast.show(context, 'Sharing is not available right now.');
      }
    }
  }

  KeyEventResult _onKey(KeyEvent event, DailyFiveState game) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (game.isComplete || game.isAnimating) return KeyEventResult.ignored;
    final notifier = ref.read(dailyFiveProvider(_mode).notifier);
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) notifier.submitGuess();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      notifier.deleteLetter();
      return KeyEventResult.handled;
    }
    final char = event.character;
    if (event is KeyDownEvent &&
        char != null &&
        char.length == 1 &&
        RegExp(r'[a-zA-Z]').hasMatch(char)) {
      notifier.addLetter(char.toUpperCase());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onModeChanged(GameMode newMode) {
    _nextTimer?.cancel();
    setState(() {
      _mode = newMode;
      _modalShown = false;
    });
    if (newMode == GameMode.practice) {
      _loadPracticeCount();
    }
  }

  void _showResultModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ResultModal(mode: _mode),
        ),
      ),
    );
  }

  Future<void> _next() async {
    _nextTimer?.cancel();
    await ref.read(dailyFiveProvider(GameMode.practice).notifier).nextPuzzle();
    if (!mounted) return;
    setState(() {
      _mode = GameMode.practice;
      _modalShown = false;
    });
    _loadPracticeCount();
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    _hints.dispose();
    super.dispose();
  }

  void _showHints(BuildContext context, String dateKey) {
    final game = ref.read(dailyFiveProvider(_mode));
    var position = 0;
    for (var i = 0; i < 5; i++) {
      if (!game.board
          .take(game.currentRow)
          .any((r) => r[i].state == LetterState.correct)) {
        position = i;
        break;
      }
    }
    NeoToast.show(
      context,
      'Letter ${position + 1} is ${game.answer[position]}. Use it in your next guess.',
      icon: Icons.lightbulb_rounded,
      color: const Color(0xFFFACC15),
    );
  }

}

/// Transient error/warning handler for Daily Five.
class _ToastBar extends ConsumerStatefulWidget {
  final GameMode mode;

  const _ToastBar({required this.mode});

  @override
  ConsumerState<_ToastBar> createState() => _ToastBarState();
}

class _ToastBarState extends ConsumerState<_ToastBar> {
  int _lastShake = 0;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(dailyFiveProvider(widget.mode));

    if (game.shakeCount > _lastShake) {
      _lastShake = game.shakeCount;
      final message = game.currentInput.length < DailyFiveState.wordLength
          ? 'Not enough letters'
          : 'Check the word and any hard-mode clues';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppFeedbackService.error(ref);
        NeoToast.show(
          context,
          message,
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF43F5E),
          duration: const Duration(seconds: 2),
        );
      });
    }

    return const SizedBox.shrink();
  }
}
