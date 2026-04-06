import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/bundle_emoticon_catalog.dart';
import 'package:gggom_tarot/config/korea_major_card_catalog.dart';
import 'package:gggom_tarot/config/shop_random_prices.dart';

void main() {
  test('gggomDailyStarPrice: UTC 날짜가 다르면 같은 키도 보통 다른 가격', () {
    final vals = <int>{};
    for (var day = 1; day <= 15; day++) {
      vals.add(
        gggomDailyStarPrice(
          'fixed-item',
          DateTime.utc(2028, 3, day),
        ),
      );
    }
    expect(vals.length, greaterThan(3));
    for (final v in vals) {
      expect(v, inInclusiveRange(1, 10));
    }
  });

  test('이모·한국전통·일자 인자 시 고정 날짜로 재현 가능', () {
    final day = DateTime.utc(2026, 4, 4);
    expect(
      bundleEmoticonShopPriceFromId('emo_asset_01', day),
      gggomDailyStarPrice('emo_asset_01', day),
    );
    expect(
      koreaMajorPieceShopStarPrice(0, day),
      gggomDailyStarPrice('korea-major-00', day),
    );
  });

  test('gggomDailyStarPrice: 같은 UTC일·같은 키는 항상 동일', () {
    final day = DateTime.utc(2031, 1, 15);
    expect(
      gggomDailyStarPrice('stable-key', day),
      gggomDailyStarPrice('stable-key', day),
    );
  });

  test('gggomDailyStarPrice: ⭐1·⭐2는 무작위 품목 기준으로 드물게', () {
    final day = DateTime.utc(2027, 6, 1);
    var star1 = 0;
    var star2 = 0;
    const n = 4000;
    for (var i = 0; i < n; i++) {
      final p = gggomDailyStarPrice('sample-key-$i', day);
      if (p == 1) {
        star1++;
      } else if (p == 2) {
        star2++;
      }
    }
    // 이전 설계(⭐1+⭐2 합 ~5%)보다 낮게 유지: ~3% 부근 기대
    expect(star1 + star2, lessThan(n * 8 ~/ 100));
    expect(star1, lessThan(n ~/ 50));
  });
}
