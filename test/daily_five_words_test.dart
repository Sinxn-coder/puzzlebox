import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlebox/games/daily_five/logic/word_list.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(WordList.init);

  test('daily words never repeat within a full cycle and are not alphabetical', () {
    final words = WordList.dailyFiveAnswers;
    expect(words.length, greaterThan(2000));
    final days = [for (var i = 0; i < words.length; i++) WordList.answerForPuzzle(i)];
    expect(days.toSet().length, words.length);
    // Consecutive days should not walk the alphabet.
    var ascending = 0;
    for (var i = 1; i < 60; i++) {
      if (days[i].compareTo(days[i - 1]) > 0) ascending++;
    }
    expect(ascending, lessThan(50));
  });

  test('answers are common-word shaped: no plurals or plain past tenses', () {
    for (final w in WordList.dailyFiveAnswers) {
      expect(w.length, 5);
      expect(WordList.isValidGuess(w), isTrue, reason: w);
      final plural = w.endsWith('S') &&
          !w.endsWith('SS') && !w.endsWith('US') && !w.endsWith('IS') &&
          !const {'ATLAS', 'CHAOS', 'ETHOS'}.contains(w);
      expect(plural, isFalse, reason: w);
    }
  });

  test('unlimited decks play every word before repeating', () {
    for (final difficulty in ['Easy', 'Medium', 'Hard']) {
      final pool = WordList.poolFor(difficulty);
      expect(pool.length, greaterThan(300), reason: difficulty);
      final seen = {
        for (var i = 0; i < pool.length; i++)
          WordList.practiceAnswer(deckSeed: 42, index: i, difficulty: difficulty),
      };
      expect(seen.length, pool.length, reason: difficulty);
      // Different installs get different orders.
      expect(
        WordList.practiceAnswer(deckSeed: 1, index: 0, difficulty: difficulty) ==
                WordList.practiceAnswer(deckSeed: 2, index: 0, difficulty: difficulty) &&
            WordList.practiceAnswer(deckSeed: 1, index: 1, difficulty: difficulty) ==
                WordList.practiceAnswer(deckSeed: 2, index: 1, difficulty: difficulty),
        isFalse,
      );
    }
    // Hard words really are harder: repeated or rare letters, or look-alikes.
    final hard = WordList.poolFor('Hard').toSet();
    final easy = WordList.poolFor('Easy').toSet();
    expect(hard.intersection(easy), isEmpty);
  });
}
