import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzlebox/core/services/date_service.dart';
import 'package:puzzlebox/core/services/session_resume.dart';

void main() {
  test('resume entries round-trip and sort newest first', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SessionResume.write(prefs, gameId: 'sudoku', mode: 'practice', difficulty: 'Hard', elapsedSeconds: 75);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await SessionResume.write(prefs, gameId: 'binary', mode: 'daily', difficulty: 'Easy', elapsedSeconds: 12);

    final sudoku = SessionResume.read(prefs, 'sudoku')!;
    expect(sudoku.difficulty, 'Hard');
    expect(sudoku.elapsedSeconds, 75);
    expect(sudoku.isDaily, isFalse);

    final all = SessionResume.all(prefs, ['sudoku', 'binary', 'chess']);
    expect(all.map((r) => r.gameId), ['binary', 'sudoku']);

    await SessionResume.clear(prefs, 'sudoku');
    expect(SessionResume.read(prefs, 'sudoku'), isNull);
  });

  test("yesterday's daily puzzle is no longer offered, practice is", () async {
    SharedPreferences.setMockInitialValues({
      SessionResume.key('binary'): jsonEncode({
        'mode': 'daily',
        'difficulty': 'Easy',
        'day': '2000-01-01',
        'savedAt': DateTime(2000).toIso8601String(),
      }),
      SessionResume.key('nonogram'): jsonEncode({
        'mode': 'practice',
        'difficulty': 'Medium',
        'day': '2000-01-01',
        'savedAt': DateTime(2000).toIso8601String(),
      }),
      SessionResume.key('cages'): 'not json',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(DateService.todayKey(), isNot('2000-01-01'));
    expect(SessionResume.read(prefs, 'binary'), isNull);
    expect(SessionResume.read(prefs, 'nonogram'), isNotNull);
    expect(SessionResume.read(prefs, 'cages'), isNull);
  });
}
