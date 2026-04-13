import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/data/today_tarot_deck.dart';

void main() {
  test('오늘의 타로 풀 106장', () {
    final d = buildTodayTarotDeckEntries();
    expect(d.length, 106);
    final sumPoints = d.fold<int>(0, (a, e) => a + e.points);
    expect(sumPoints > 0, isTrue);
  });
}
