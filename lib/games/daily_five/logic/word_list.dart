import 'dart:math';
import 'package:flutter/services.dart';

/// Loads and exposes the bundled word lists.
class WordList {
  WordList._();

  static List<String>? _answers;
  static List<String>? _dailyFive;
  static List<String>? _dailyOrder;
  static Map<String, int> _traps = {};
  static Set<String>? _validGuesses;
  static Set<String> dictionary = {};

  /// Fixed seed for the shared daily order, so every player gets the same
  /// word on the same day.
  static const _dailyOrderSeed = 0x5F1FE;

  /// Letters that make a word noticeably harder to find.
  static const _rareLetters = {'J', 'K', 'Q', 'V', 'X', 'Z'};

  /// Load all word lists from assets. Call once at app start.
  static Future<void> init() async {
    if (_answers != null) return;
    final english = await rootBundle.loadString('assets/words/english.txt');
    dictionary = english
        .split('\n')
        .map((w) => w.trim().toUpperCase())
        .where((w) => w.length >= 3)
        .toSet();
    final answersRaw = await rootBundle.loadString(
      'assets/words/daily_five_answers.txt',
    );
    final dailyFiveRaw = await rootBundle.loadString(
      'assets/words/daily_five_answers_v2.txt',
    );
    final validRaw = await rootBundle.loadString(
      'assets/words/daily_five_valid.txt',
    );

    List<String> fiveLetter(String raw) => raw
        .split('\n')
        .map((w) => w.trim().toUpperCase())
        .where((w) => w.length == 5)
        .toList();

    // Legacy list: other games build their dictionaries from it, so it stays
    // unchanged to keep their puzzles (and saved progress) identical.
    _answers = fiveLetter(answersRaw);

    // Daily Five answers: a larger curated list of common, well-known words
    // (no plurals or plain past tenses), in a fixed shuffled order.
    _dailyFive = (fiveLetter(dailyFiveRaw).toSet().toList()..sort());
    _dailyOrder = List<String>.from(_dailyFive!)
      ..shuffle(Random(_dailyOrderSeed));
    _traps = _trapCounts(_dailyFive!);

    final validSet = fiveLetter(validRaw).toSet()
      ..addAll(_answers!)
      ..addAll(_dailyFive!);
    _validGuesses = {...validSet, ...dictionary.where((w) => w.length == 5)};
  }

  static List<String> get answers {
    assert(_answers != null, 'WordList.init() must be called before use');
    return _answers!;
  }

  /// Curated Daily Five answer pool.
  static List<String> get dailyFiveAnswers {
    assert(_dailyFive != null, 'WordList.init() must be called before use');
    return _dailyFive!;
  }

  static bool isValidGuess(String word) {
    assert(_validGuesses != null, 'WordList.init() must be called before use');
    return _validGuesses!.contains(word.toUpperCase());
  }

  /// Today's answer: walks a fixed shuffled order, so no word repeats until
  /// the whole list has been used.
  static String answerForPuzzle(int puzzleNumber) {
    final order = _dailyOrder!;
    final n = puzzleNumber < 0 ? 0 : puzzleNumber;
    return order[n % order.length];
  }

  /// Answer pool for an Unlimited difficulty.
  ///
  /// * Easy: five different letters, no rare letters, few look-alike words.
  /// * Medium: everything except the trickiest words.
  /// * Hard: repeated letters, rare letters, or "trap" words with many
  ///   one-letter-off look-alikes (e.g. _IGHT, _OUND).
  static List<String> poolFor(String difficulty) {
    final words = dailyFiveAnswers;
    return switch (difficulty) {
      'Easy' => words.where(_isEasy).toList(),
      'Hard' => words.where(_isHard).toList(),
      _ => words.where((w) => !_isHard(w)).toList(),
    };
  }

  /// Unlimited answer number [index] for one player's deck.
  ///
  /// The pool is shuffled once per cycle with [deckSeed], so a word only comes
  /// back after every other word in the pool has been played. [avoid] (today's
  /// daily word) is skipped.
  static String practiceAnswer({
    required int deckSeed,
    required int index,
    required String difficulty,
    String? avoid,
  }) {
    final pool = poolFor(difficulty)..sort();
    if (pool.isEmpty) return answerForPuzzle(0);
    String at(int i) {
      final cycle = i ~/ pool.length;
      final deck = List<String>.from(pool)
        ..shuffle(Random(deckSeed ^ (cycle * 0x9E3779B1)));
      return deck[i % pool.length];
    }

    final word = at(index);
    return word == avoid && pool.length > 1 ? at(index + 1) : word;
  }

  static bool _isEasy(String w) =>
      w.split('').toSet().length == 5 &&
      !w.split('').any(_rareLetters.contains) &&
      (_traps[w] ?? 0) <= 2;

  static bool _isHard(String w) =>
      w.split('').toSet().length < 5 ||
      w.split('').any(_rareLetters.contains) ||
      (_traps[w] ?? 0) >= 4;

  /// How many other answers differ from each word by exactly one letter in
  /// the same position.
  static Map<String, int> _trapCounts(List<String> words) {
    final buckets = <String, int>{};
    for (final w in words) {
      for (var i = 0; i < 5; i++) {
        final key = '${w.substring(0, i)}_${w.substring(i + 1)}';
        buckets[key] = (buckets[key] ?? 0) + 1;
      }
    }
    return {
      for (final w in words)
        w: [
          for (var i = 0; i < 5; i++)
            buckets['${w.substring(0, i)}_${w.substring(i + 1)}']! - 1,
        ].fold(0, (a, b) => a + b),
    };
  }
}
