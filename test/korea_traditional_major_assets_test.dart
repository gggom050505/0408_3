import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/data/deck_card_catalog.dart';
import 'package:gggom_tarot/data/korea_traditional_major_assets.dart';

void main() {
  test('한국전통 메이저 경로 22개 (0~21)', () {
    expect(
      kKoreaTraditionalMajorIllustrationCount,
      kCatalogKoreaTraditionalMajorCount,
    );
    expect(kKoreaTraditionalMajorTarotCardIds.length, 22);
    for (var i = 0; i <= 21; i++) {
      final p = koreaTraditionalMajorAssetPath(i);
      expect(p, isNotNull);
      expect(p!, startsWith('assets/koreacard/korean majors('));
      expect(p, endsWith(').png'));
    }
    expect(koreaTraditionalMajorAssetPath(-1), isNull);
    expect(koreaTraditionalMajorAssetPath(22), isNull);
  });
}
