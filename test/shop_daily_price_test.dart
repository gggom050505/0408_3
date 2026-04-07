import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/bundle_emoticon_catalog.dart'
    show bundleEmoticonShopPriceFromId, kBundleEmoticonCount;
import 'package:gggom_tarot/config/korea_major_card_catalog.dart';
import 'package:gggom_tarot/config/shop_random_prices.dart';
import 'package:gggom_tarot/data/card_back_shop_assets.dart';
import 'package:gggom_tarot/data/oracle_assets.dart';
import 'package:gggom_tarot/data/slot_shop_assets.dart'
    show kBundledSlotShopAssetTuples, kDefaultEquippedSlotId;

void main() {
  test('gggomFixedStarPrice: 같은 키는 날짜와 관계없이 동일', () {
    expect(
      gggomFixedStarPrice('korea-major-00', min: 6, max: 8),
      gggomFixedStarPrice('korea-major-00', min: 6, max: 8),
    );
    final dayA = DateTime.utc(2026, 1, 1);
    final dayB = DateTime.utc(2030, 12, 31);
    expect(
      bundleEmoticonShopPriceFromId('emo_asset_01', dayA),
      bundleEmoticonShopPriceFromId('emo_asset_01', dayB),
    );
  });

  test('품목 유형별 별조각 구간', () {
    for (var i = 1; i <= kBundleEmoticonCount; i++) {
      final id = 'emo_asset_${i.toString().padLeft(2, '0')}';
      expect(bundleEmoticonShopPriceFromId(id), inInclusiveRange(1, 3));
    }
    for (final t in kBundledSlotShopAssetTuples) {
      if (t.$1 == kDefaultEquippedSlotId) {
        continue;
      }
      expect(
        gggomFixedStarPrice(t.$1, min: 3, max: 5),
        inInclusiveRange(3, 5),
      );
    }
    for (final row in bundledCardBackShopRows()) {
      expect(row.price, inInclusiveRange(4, 6));
    }
    for (var n = 1; n <= kBundledOracleCardCount; n++) {
      expect(oracleCardShopStarPrice(n), inInclusiveRange(5, 7));
    }
    for (var i = 0; i <= 21; i++) {
      expect(koreaMajorPieceShopStarPrice(i), inInclusiveRange(6, 8));
    }
  });

  test('gggomDailyStarPrice: 레거시 함수 — 일자에 따라 변할 수 있음(내장 상점 미사용)', () {
    final a = gggomDailyStarPrice('x', DateTime.utc(2026, 1, 1));
    final b = gggomDailyStarPrice('x', DateTime.utc(2026, 6, 1));
    expect(a, inInclusiveRange(1, 10));
    expect(b, inInclusiveRange(1, 10));
  });
}
