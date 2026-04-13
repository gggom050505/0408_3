import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/korea_major_card_catalog.dart';
import 'package:gggom_tarot/config/starter_gifts.dart';

void main() {
  test('한국전통 메이저 상점 ID ↔ 인덱스', () {
    expect(koreaMajorCardShopItemId(0), 'korea-major-00');
    expect(koreaMajorCardShopItemId(21), 'korea-major-21');
    expect(koreaMajorCardIndexFromShopItemId('korea-major-05'), 5);
    expect(koreaMajorCardIndexFromShopItemId('oracle-card-01'), isNull);
  });

  test('한국전통 조각 별조각: 전 품목 7~9 고정가', () {
    for (var i = 0; i <= 21; i++) {
      expect(koreaMajorPieceShopStarPrice(i), inInclusiveRange(7, 9));
    }
  });

  test('유저마다 다른 무작위 한국전통 선물 1장', () {
    final a = starterKoreaMajorItemIdForUser('user-a');
    final b = starterKoreaMajorItemIdForUser('user-b');
    expect(a.startsWith('korea-major-'), isTrue);
    expect(b.startsWith('korea-major-'), isTrue);
    expect(
      koreaMajorCardIndexFromShopItemId(a),
      isNotNull,
    );
  });
}
