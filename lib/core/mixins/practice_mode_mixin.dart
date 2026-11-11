import '../widgets/app_scaffold.dart';
import '../services/share_card.dart';
import '../game_catalog.dart';
import '../../screens/achievements_screen.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/game_mode_toggle.dart';
import '../widgets/neo_toast.dart';
import '../widgets/daily_done_banner.dart';
import '../services/app_feedback_service.dart';
import '../services/practice_service.dart';
import '../services/puzzle_progression.dart';
import '../services/date_service.dart';
import '../services/session_resume.dart';
import '../services/hint_budget.dart';
import '../services/special_puzzles.dart';
import '../theme/neo.dart';
import '../providers/settings_provider.dart';
import '../services/engagement_service.dart';
import '../services/stats_service.dart';
import '../widgets/celebration_burst.dart';
import '../widgets/streak_earned_dialog.dart';

mixin PracticeModeMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  String get gameType;
  GameMode _mode = GameMode.practice;
  String _dayKey = DateService.todayKey();

  /// Set when playing an archive day or the weekly challenge.
  PuzzleLaunch? _special;
  bool get isArchive => _special != null && !_special!.isWeekly;
  bool get isWeekly => _special?.isWeekly ?? false;
  String get dailyDateKey => _dayKey;
  GameMode get mode => _mode;
  int _practiceSolvedCount = 0;
  int get practiceSolvedCount => _practiceSolvedCount;
  String difficulty = 'Medium';
  int _generation = 0;
  bool _finishing = false;
  bool _transitioning = false;
  bool _advanceReserved = false;
  bool _isDisposing = false;
  Timer? _advanceTimer;
  Timer? _saveTimer;
  final Stopwatch _sessionWatch = Stopwatch();

  /// Pauses the puzzle timer and play-time counter while the app is in the
  /// background, so a puzzle left open does not inflate solve times.
  AppLifecycleListener? _lifecycle;
  bool _appActive = true;
  SharedPreferences? _prefs;
  String? _sessionKey;
  String? _sessionId;
  String? _sessionMode;
  /// Seconds spent on the current puzzle; survives leaving and resuming.
  final ValueNotifier<int> puzzleElapsed = ValueNotifier<int>(0);
  String? _baseline;
  bool _touched = false;

  /// True once the player has changed the current puzzle.
  bool get hasPuzzleProgress => _touched;

  /// Paced hints for the current puzzle (see [HintBudget]).
  final HintBudget hintBudget = HintBudget();

  /// Bumped on a wrong move (board shakes) and on a win (board lights up).
  final ValueNotifier<int> wrongPulse = ValueNotifier<int>(0);
  final ValueNotifier<int> winPulse = ValueNotifier<int>(0);

  /// Call when the player makes a wrong move: shake + error buzz.
  void signalWrong() {
    wrongPulse.value++;
    AppFeedbackService.error(ref);
  }

  /// Gate for the top-bar hint button. Returns false (and says when the next
  /// hint is ready) while the cooldown is running.
  bool useHint() {
    if (_finishing) return false;
    if (hintBudget.tryUse()) {
      if (hintBudget.used == HintBudget.freeHints) {
        Future.microtask(() {
          if (mounted) {
            showPuzzleHint('That was your last free hint. More unlock every ${HintBudget.cooldown.inSeconds}s.');
          }
        });
      }
      return true;
    }
    NeoToast.show(
      context,
      'Next hint in ${HintBudget.format(hintBudget.waitLeft!)}. Give it a try first!',
      icon: Icons.hourglass_top_rounded,
      color: const Color(0xFFFACC15),
    );
    return false;
  }
  Map<String, dynamic> captureProgress() => {};
  void restoreProgress(Map<String, dynamic> data) {}
  void startSession() {
    _lifecycle ??= AppLifecycleListener(
      onStateChange: (state) {
        final active = state == AppLifecycleState.resumed;
        if (active == _appActive) return;
        if (!active) _saveSession();
        _appActive = active;
        if (active) {
          _sessionWatch
            ..reset()
            ..start();
        } else {
          _sessionWatch.stop();
        }
      },
    );
    _sessionWatch.reset();
    if (_appActive) _sessionWatch.start();
    _saveTimer?.cancel();
    _prefs = ref.read(sharedPreferencesProvider);
    _sessionKey = 'session_v2_${gameType}_${mode.name}_$difficulty'
        '${_special != null ? '_$_dayKey' : ''}';
    _sessionId = puzzleRequest.id;
    _sessionMode = mode.name;
    _baseline = null;
    _touched = false;
    puzzleElapsed.value = 0;
    hintBudget.reset();
    try {
      final raw =
          _prefs!.getString(_sessionKey!) ??
          _prefs!.getString('session_v1_$gameType');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['id'] == puzzleRequest.id && data['mode'] == mode.name) {
          restoreProgress(Map<String, dynamic>.from(data['progress']));
          puzzleElapsed.value = data['elapsed'] as int? ?? 0;
          hintBudget.reset(used: data['hints'] as int? ?? 0);
          _touched = data['touched'] as bool? ?? true;
        }
      }
    } catch (_) {
      /* An invalid older save must not prevent play. */
    }
    _prefs!.remove('session_v1_$gameType');
    _saveTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_appActive && !_finishing && !_transitioning) puzzleElapsed.value++;
        _saveSession();
      },
    );
  }

  void _saveSession() {
    if (!mounted) return;
    if (_sessionWatch.isRunning) {
      final elapsed = _sessionWatch.elapsed.inSeconds;
      if (elapsed > 0) {
        if (!_isDisposing) {
          try {
            ref.read(engagementServiceProvider).addPlayTime(elapsed);
            ref.read(engagementRevisionProvider.notifier).state++;
          } catch (_) {}
        }

        _sessionWatch.reset();
        if (_appActive) _sessionWatch.start();
      }
    }
    if (_prefs == null || _sessionKey == null || _finishing) return;
    final data = captureProgress();
    if (data.isEmpty) return;
    // A game's own ticking clock is not progress; only real moves count.
    final encoded = jsonEncode(Map.of(data)..remove('seconds'));
    _baseline ??= encoded;
    if (encoded != _baseline) _touched = true;
    _prefs!.setString(
      _sessionKey!,
      jsonEncode({
        'id': _sessionId,
        'mode': _sessionMode,
        'progress': data,
        'elapsed': puzzleElapsed.value,
        'touched': _touched,
        'hints': hintBudget.used,
      }),
    );
    if (_touched && _special == null) {
      SessionResume.write(
        _prefs!,
        gameId: gameType,
        mode: _sessionMode ?? mode.name,
        difficulty: difficulty,
        elapsedSeconds: puzzleElapsed.value,
      );
    } else {
      final resume = SessionResume.read(_prefs!, gameType);
      if (resume != null &&
          resume.mode == _sessionMode &&
          resume.difficulty == difficulty) {
        SessionResume.clear(_prefs!, gameType);
      }
    }
  }

  String get _progressionKey => '$gameType:$difficulty';

  /// Picks an item from a content pool of [poolSize] without repeats: in
  /// Unlimited each player walks their own shuffled deck, and nothing comes
  /// back until the whole pool has been played. Daily walks a shared order
  /// by date, so consecutive days never repeat either.
  int uniqueIndex(int poolSize) {
    if (poolSize <= 1) return 0;
    final progression = ref.read(puzzleProgressionProvider);
    final daily = mode == GameMode.daily;
    final n = daily
        ? SpecialPuzzles.puzzleNumberFor(_dayKey)
        : progression.index(_progressionKey);
    final deckSeed = daily
        ? stableSeed('$gameType:daily-deck:$difficulty')
        : progression.seed('${gameType}_deck', progressionKey: '${gameType}_deck');
    final cycle = n ~/ poolSize;
    final order = List<int>.generate(poolSize, (i) => i)
      ..shuffle(Random(deckSeed ^ (cycle * 0x9E3779B1)));
    return order[n % poolSize];
  }

  /// Deck order for picking several items per puzzle (e.g. Connections
  /// groups): puzzle n starts at slot n * [perPuzzle] of the player's deck,
  /// so items are not reused until the deck has been worked through.
  List<int> uniqueDeck(int poolSize, int perPuzzle) {
    final progression = ref.read(puzzleProgressionProvider);
    final daily = mode == GameMode.daily;
    final n = daily
        ? SpecialPuzzles.puzzleNumberFor(_dayKey)
        : progression.index(_progressionKey);
    final deckSeed = daily
        ? stableSeed('$gameType:daily-deck:$difficulty')
        : progression.seed('${gameType}_deck', progressionKey: '${gameType}_deck');
    List<int> cycleOrder(int cycle) => List<int>.generate(poolSize, (i) => i)
      ..shuffle(Random(deckSeed ^ (cycle * 0x9E3779B1)));
    final start = n * perPuzzle;
    final first = cycleOrder(start ~/ poolSize);
    final next = cycleOrder(start ~/ poolSize + 1);
    final offset = start % poolSize;
    // Current cycle from the offset, then the following cycle as overflow.
    return [...first.sublist(offset), ...next];
  }

  int puzzleSeed() => mode == GameMode.daily
      ? stableSeed('$gameType:$_dayKey:$difficulty')
      : stableSeed(
          '${ref.read(puzzleProgressionProvider).seed(gameType, progressionKey: _progressionKey)}:$difficulty',
        );
  /// Bump when a game's generator changes so saves made for the old
  /// puzzles are not restored onto new boards.
  int get puzzleVersion => 1;
  PuzzleRequest get puzzleRequest => PuzzleRequest(
    gameType,
    puzzleSeed(),
    PuzzleDifficulty.values.byName(difficulty.toLowerCase()),
    version: puzzleVersion,
  );
  void onPracticeModeChanged(GameMode mode) {}
  void loadDailyPuzzle() {}
  void loadPracticePuzzle() {}
  Future<void> initPracticeMode() async {
    _practiceSolvedCount = ref
        .read(practiceServiceProvider)
        .getSolvedCount(gameType);
    difficulty =
        ref.read(sharedPreferencesProvider).getString('difficulty_$gameType') ??
        ref.read(settingsProvider).defaultDifficulty;
    if (!['Easy', 'Medium', 'Hard'].contains(difficulty)) difficulty = 'Medium';
    final prefs = ref.read(sharedPreferencesProvider);
    // Reopen whichever puzzle the player left unfinished.
    final launch = PuzzleLaunch.take(gameType);
    final resume = launch == null ? SessionResume.read(prefs, gameType) : null;
    if (launch != null) {
      _mode = GameMode.daily;
      if (launch.isWeekly) {
        _special = launch;
        difficulty = 'Hard';
        _dayKey = SpecialPuzzles.weekKey();
      } else if (launch.day != DateService.todayKey()) {
        _special = launch;
        _dayKey = launch.day!;
      }
    }
    if (resume != null) {
      _mode = resume.isDaily ? GameMode.daily : GameMode.practice;
      if (['Easy', 'Medium', 'Hard'].contains(resume.difficulty)) {
        difficulty = resume.difficulty;
      }
    }
    for (final level in ['Easy', 'Medium', 'Hard']) {
      final key = 'progress_v1_$gameType:$level';
      if (!prefs.containsKey(key)) {
        prefs.setInt(key, ref.read(puzzleProgressionProvider).index(gameType));
      }
    }
  }

  Future<void> recordPracticeWin() async => finishPuzzle();
  void recordPracticeLoss() => finishPuzzle(won: false);
  Future<void> finishPuzzle({bool won = true, String? explanation}) async {
    if (_finishing || _transitioning || !mounted) return;
    _finishing = true;
    _saveTimer?.cancel();
    if (_sessionKey != null) _prefs?.remove(_sessionKey!);
    if (_prefs != null) SessionResume.clear(_prefs!, gameType);
    final solveSeconds = puzzleElapsed.value;
    final generation = _generation;

    try {
      if (mode == GameMode.practice && won) {
        final count = await ref
            .read(practiceServiceProvider)
            .recordSolved(gameType, puzzleRequest.id);
        if (!mounted || generation != _generation) return;
        setState(() => _practiceSolvedCount = count);
      }
      if (won) {
        final engagement = await ref
            .read(engagementServiceProvider)
            .recordCompletion(
              game: gameType,
              difficulty: difficulty,
              seconds: solveSeconds,
              hints: hintBudget.used,
            );
        await ref
            .read(statsServiceProvider)
            .recordResult(
              gameType: gameType,
              todayKey: DateService.todayKey(),
              won: true,
              // Archive and weekly wins do not count as today's daily.
              isPractice: mode == GameMode.practice || _special != null,
            );
        if (!mounted || generation != _generation) return;
        ref.read(engagementRevisionProvider.notifier).state++;
        winPulse.value++;
        showCelebrationBurst(context);
        announceAchievements(context, ref);
        if (engagement.streakEarnedToday) {
          StreakEarnedDialog.show(context, streak: engagement.currentStreak);
        }
      }
      if (!mounted || generation != _generation) return;
      await ref.read(puzzleProgressionProvider).advance(_progressionKey);
      _advanceReserved = true;
      if (!mounted || generation != _generation) return;
      final dailyWin = won && mode == GameMode.daily;
      if (dailyWin) _markDailyDone();
      if (explanation != null) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(won ? 'Nicely solved!' : 'Here are the connections'),
            content: SingleChildScrollView(child: Text(explanation)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(dailyWin ? 'Done' : 'Next puzzle'),
              ),
            ],
          ),
        );
        if (!mounted || generation != _generation) return;
        if (dailyWin) {
          setState(() => _finishing = false);
          return;
        }
        await nextPuzzle();
        return;
      }
      if (won) {
        AppFeedbackService.victory(ref);
      } else {
        AppFeedbackService.heartbeat(ref);
      }
      if (dailyWin) {
        NeoToast.show(
          context,
          hintBudget.used == 0
              ? "⭐ Today's puzzle, no hints! A new one arrives tomorrow."
              : "Today's puzzle solved! A new one arrives tomorrow.",
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF4ADE80),
          duration: const Duration(milliseconds: 2400),
        );
        setState(() => _finishing = false);
        return;
      }
      NeoToast.show(
        context,
        won
            ? (hintBudget.used == 0
                  ? '⭐ Solved with no hints! Next puzzle coming up.'
                  : 'Nicely solved. Next puzzle coming up!')
            : 'Fresh puzzle coming up.',
        icon: won ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
        color: won ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8),
        duration: const Duration(milliseconds: 2000),
      );
      _advanceTimer?.cancel();
      _advanceTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && generation == _generation) nextPuzzle();
      });
    } catch (_) {
      _finishing = false;
      if (mounted) {
        showPuzzleHint('Your save could not be written. Use Next to retry.');
      }
    }
  }

  Future<void> nextPuzzle() async {
    if (_transitioning || (_finishing && !_advanceReserved)) return;
    _transitioning = true;
    _advanceTimer?.cancel();
    _saveTimer?.cancel();
    final generation = ++_generation;
    try {
      if (!_advanceReserved) {
        await ref.read(puzzleProgressionProvider).advance(_progressionKey);
      }
      _advanceReserved = false;
      if (!mounted || generation != _generation) return;
      setState(() {
        _mode = GameMode.practice;
        _finishing = false;
        onPracticeModeChanged(_mode);
      });
    } catch (_) {
      if (mounted) {
        showPuzzleHint('Unable to save. Your current puzzle is still here.');
      }
    } finally {
      _transitioning = false;
    }
  }

  bool shouldShowNextButton(bool isSolved) => isSolved;
  void showPuzzleHint(String message) {
    NeoToast.show(
      context,
      message,
      icon: Icons.lightbulb_rounded,
      color: const Color(0xFFFACC15),
    );
  }

  void _switchMode(GameMode value) {
    if (value == mode || _transitioning) return;
    _saveSession();
    _saveTimer?.cancel();
    _advanceTimer?.cancel();
    _generation++;
    _advanceReserved = false;
    setState(() {
      _dayKey = DateService.todayKey();
      _special = null;
      _mode = value;
      _finishing = false;
      onPracticeModeChanged(value);
    });
  }

  void _switchDifficulty(String value) {
    if (value == difficulty || _transitioning || _finishing) return;
    // The weekly challenge is always played on Hard.
    if (isWeekly) {
      showPuzzleHint('The weekly challenge is always Hard. Switch to Unlimited to pick a level.');
      return;
    }
    _saveSession();
    _saveTimer?.cancel();
    _advanceTimer?.cancel();
    _generation++;
    _advanceReserved = false;
    ref.read(sharedPreferencesProvider).setString('difficulty_$gameType', value);
    setState(() {
      difficulty = value;
      _finishing = false;
      onPracticeModeChanged(mode);
    });
  }

  /// Next button: asks first when the player has made progress.
  Future<void> _onNextTapped() async {
    if (_transitioning) return;
    if (hasPuzzleProgress && !_finishing) {
      final skip = await confirmSkipPuzzle(context);
      if (!skip || !mounted) return;
    }
    await nextPuzzle();
  }

  static const _dailyDonePrefix = 'daily_done_v1_';

  /// Whether today's daily puzzle at [level] is already solved.
  bool isDailyDone([String? level]) {
    final prefs = ref.read(sharedPreferencesProvider);
    if (isWeekly) return SpecialPuzzles.weeklyDone(prefs);
    if (isArchive) return SpecialPuzzles.archiveDone(prefs, gameType).contains(_dayKey);
    final raw = ref.read(sharedPreferencesProvider).getString('$_dailyDonePrefix$gameType');
    if (raw == null) return false;
    final parts = raw.split('|');
    return parts.first == DateService.todayKey() &&
        parts.skip(1).contains(level ?? difficulty);
  }

  String get _resultKey => 'daily_result_v1_$gameType';

  /// Shares the result card for the daily/archive/weekly puzzle just solved.
  Future<void> _shareResult() async {
    final game = GameCatalog.byId(gameType);
    if (game == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final parts = (prefs.getString(_resultKey) ?? '').split('|');
    final matches = parts.length == 4 && parts[0] == _dayKey && parts[1] == difficulty;
    final seconds = matches ? int.tryParse(parts[2]) ?? 0 : 0;
    final hints = matches ? int.tryParse(parts[3]) : null;
    final streak = ref.read(engagementServiceProvider).load().currentStreak;
    try {
      await ShareCard.share(
        gameName: game.name,
        accent: game.color,
        headline: isWeekly ? 'Weekly Challenge solved!' : 'Solved ${_specialLabel().replaceAll(RegExp(r'^[^A-Za-z]+'), '')}',
        lines: [
          '$difficulty difficulty',
          if (seconds > 0) 'Time: ${formatClock(seconds)}',
          if (hints != null) hints == 0 ? '⭐ No hints used' : 'Hints used: $hints',
          if (streak > 0) '🔥 $streak-day streak',
        ],
      );
    } catch (_) {
      if (mounted) showPuzzleHint('Sharing is not available right now.');
    }
  }

  void _markDailyDone() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_resultKey, '$_dayKey|$difficulty|${puzzleElapsed.value}|${hintBudget.used}');
    if (isWeekly) {
      SpecialPuzzles.markWeeklyDone(prefs);
      return;
    }
    SpecialPuzzles.markArchiveDone(prefs, gameType, _dayKey);
    if (isArchive) return;
    final today = DateService.todayKey();
    final raw = prefs.getString('$_dailyDonePrefix$gameType');
    final parts = raw?.split('|') ?? const <String>[];
    final levels = parts.isNotEmpty && parts.first == today
        ? {...parts.skip(1), difficulty}
        : {difficulty};
    prefs.setString('$_dailyDonePrefix$gameType', [today, ...levels].join('|'));
  }

  String _specialLabel() {
    if (isWeekly) return '🏆 Weekly Challenge · Hard';
    if (_special == null) return "Today's Daily";
    final d = DateTime.tryParse(_dayKey);
    if (d == null) return 'Archive';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '📅 Archive · ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget buildPracticeModeToggle() => Column(
    children: [
      GameControlBar(
        mode: mode,
        practiceSolvedCount: practiceSolvedCount,
        onModeChanged: _switchMode,
        difficulty: difficulty,
        onDifficultyChanged: _switchDifficulty,
        onNext: _onNextTapped,
      ),
      if (_special != null) _SpecialBadge(label: _specialLabel()),
      if (mode == GameMode.daily && isDailyDone())
        DailyDoneBanner(
          label: isWeekly
              ? 'Weekly challenge done ✓'
              : isArchive
              ? 'Archive puzzle done ✓'
              : null,
          onPlayUnlimited: () => _switchMode(GameMode.practice),
          onShare: _shareResult,
        ),
    ],
  );
  @override
  void dispose() {
    _isDisposing = true;
    _saveSession();
    _saveTimer?.cancel();
    _advanceTimer?.cancel();
    _lifecycle?.dispose();
    hintBudget.dispose();
    wrongPulse.dispose();
    winPulse.dispose();
    puzzleElapsed.dispose();
    super.dispose();
  }
}

class _SpecialBadge extends StatelessWidget {
  final String label;
  const _SpecialBadge({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFC084FC),
        borderRadius: BorderRadius.circular(12),
        border: Neo.border(2),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black),
      ),
    ),
  );
}
