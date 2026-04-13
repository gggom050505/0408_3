import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/widgets/today_tarot_screen.dart';

void main() {
  test('키워드: 날짜 시드 기반 난수 — 같은 로컬 날짜는 같은 단어', () {
    expect(kTodayTarotKeywordsOrdered.length, 21);
    final a = todayTarotKeywordForDate(DateTime(2026, 1, 15));
    final b = todayTarotKeywordForDate(DateTime(2026, 1, 15, 23, 59));
    expect(a, b);
    expect(kTodayTarotKeywordsOrdered.contains(a), isTrue);
  });

  test('키워드: 여러 날짜 모두 후보 목록 안', () {
    for (var i = 0; i < 500; i++) {
      final d = DateTime(2024, 1, 1).add(Duration(days: i));
      final w = todayTarotKeywordForDate(d);
      expect(kTodayTarotKeywordsOrdered.contains(w), isTrue, reason: '$d → $w');
    }
  });
}
