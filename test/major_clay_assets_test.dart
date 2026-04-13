import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/data/major_clay_assets.dart';

void main() {
  test('클레이 메이저 일러스트 경로 24개 (0~21 + 82·83)', () {
    for (var i = 0; i <= 21; i++) {
      expect(majorClayAssetPathForTarotCardId(i), isNotNull);
    }
    expect(majorClayAssetPathForTarotCardId(82), isNotNull);
    expect(majorClayAssetPathForTarotCardId(83), isNotNull);
    expect(majorClayAssetPathForTarotCardId(22), isNull);
    expect(kMajorClayTarotCardIds.length, 24);
  });
}
