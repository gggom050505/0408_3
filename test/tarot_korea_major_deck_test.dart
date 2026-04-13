import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/data/card_themes.dart';
import 'package:gggom_tarot/data/tarot_cards.dart';

void main() {
  test('tarotMajorArcanaOnly는 22장이며 id 0~21 유일', () {
    expect(tarotMajorArcanaOnly.length, 22);
    expect(tarotMajorArcanaOnly.first.id, 0);
    expect(tarotMajorArcanaOnly.last.id, 21);
    expect(tarotMajorArcanaOnly.map((c) => c.id).toSet().length, 22);
  });

  test('한국전통 메이저 테마 앞면 에셋은 0~21만', () {
    for (var i = 0; i <= 21; i++) {
      expect(
        getBundledSiteCardAssetPath(
          themeId: koreaTraditionalMajorThemeId,
          cardId: i,
        ),
        'assets/koreacard/korean majors($i).png',
      );
    }
    expect(
      getBundledSiteCardAssetPath(
        themeId: koreaTraditionalMajorThemeId,
        cardId: 22,
      ),
      isNull,
    );
  });

  test('shuffleDeck(메이저만) 결과는 여전히 0~21 id만', () {
    final s = shuffleDeck(List<TarotCard>.from(tarotMajorArcanaOnly));
    expect(s.length, 22);
    expect(s.every((c) => c.id >= 0 && c.id <= 21), isTrue);
  });
}
