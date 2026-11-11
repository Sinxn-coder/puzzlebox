import 'package:flutter_test/flutter_test.dart';
import 'package:puzzlebox/core/services/hint_budget.dart';
import 'package:puzzlebox/core/services/puzzle_content.dart';

void main() {
  test('every Strands theme fills the 6x8 board exactly', () {
    expect(strandsThemes.length, greaterThanOrEqualTo(25));
    final spangrams = <String>{};
    for (final theme in strandsThemes) {
      final spangram = theme[1];
      final words = theme.skip(1).toList();
      expect(words.fold<int>(0, (n, w) => n + w.length), 48, reason: theme[0]);
      expect(spangram.length, greaterThanOrEqualTo(6), reason: theme[0]);
      expect(words.toSet().length, words.length, reason: theme[0]);
      expect(spangrams.add(spangram), isTrue, reason: 'duplicate ${theme[0]}');
      for (final w in words) {
        expect(RegExp(r'^[A-Z]+$').hasMatch(w), isTrue, reason: w);
      }
    }
  });

  test('Connections groups have tiers and enough distinct words', () {
    expect(categoryBank.length, greaterThanOrEqualTo(70));
    for (final MapEntry(:key, :value) in categoryBank.entries) {
      expect(categoryLevels[key], inInclusiveRange(1, 4), reason: key);
      expect(value.toSet().length, value.length, reason: key);
      expect(value.length, greaterThanOrEqualTo(4), reason: key);
    }
    for (final level in [1, 2, 3, 4]) {
      expect(
        categoryLevels.values.where((l) => l == level).length,
        greaterThanOrEqualTo(8),
        reason: 'level $level',
      );
    }
  });

  test('Spelling Bee bases have exactly seven distinct letters', () {
    expect(beePangrams.length, greaterThanOrEqualTo(90));
    expect(beePangrams.toSet().length, beePangrams.length);
    for (final w in beePangrams) {
      expect(w.split('').toSet().length, 7, reason: w);
    }
  });

  test('hints: three free, then a cooldown between hints', () {
    HintBudget.cooldown = const Duration(seconds: 45);
    final budget = HintBudget();
    expect(budget.badge.value, '3');
    expect(budget.tryUse(), isTrue);
    expect(budget.tryUse(), isTrue);
    expect(budget.badge.value, '1');
    expect(budget.tryUse(), isTrue);
    // Fourth hint has to wait.
    expect(budget.tryUse(), isFalse);
    expect(budget.waitLeft, isNotNull);
    expect(budget.badge.value, matches(RegExp(r'^0:4[0-5]$')));
    // A resumed puzzle keeps its spent hints.
    budget.reset(used: 3);
    expect(budget.tryUse(), isFalse);
    budget.reset();
    expect(budget.tryUse(), isTrue);
    budget.dispose();
  });
}
