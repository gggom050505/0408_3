import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/data/card_themes.dart';
import 'package:gggom_tarot/data/oracle_assets.dart';
import 'package:gggom_tarot/models/shop_models.dart';

void main() {
  test('bundledOracleShopCatalogRows: 80장·oracle-card 타입', () {
    final rows = bundledOracleShopCatalogRows();
    expect(rows.length, kBundledOracleCardCount);
    expect(rows.every((e) => e.type == 'oracle_card'), isTrue);
    expect(rows.first.id, 'oracle-card-01');
    expect(rows.first.name, '01. 성운');
    expect(rows.first.thumbnailUrl, 'oracle_cards/oracle(1).png');
    expect(rows[11].name, '12. 블랙홀');
    expect(rows.last.id, 'oracle-card-80');
    expect(oracleItemIdToCardNumber(rows[11].id), 12);
  });

  test('shop_items 병합 시뮬: DB에 오라클이 없으면 번들 80장 보강', () {
    final dbLike = <ShopItemRow>[
      ShopItemRow(
        id: 'default',
        name: '기본 카드',
        type: 'card',
        price: 0,
        thumbnailUrl: null,
        isActive: true,
      ),
    ];
    final items = <ShopItemRow>[...dbLike];
    for (final row in bundledOracleShopCatalogRows()) {
      if (!items.any((e) => e.id == row.id)) {
        items.add(row);
      }
    }
    expect(items.where((e) => e.type == 'oracle_card').length, 80);
  });

  test('oracle_cards/ 논리 썸네일 경로는 번들 assets/oracle PNG로 해석', () {
    expect(
      resolvePublicAssetUrl('oracle_cards/oracle(40).png', ''),
      'assets/oracle/oracle(40).png',
    );
    expect(
      resolveGggomBundledSitePath('/oracle_cards/oracle(1).png'),
      'assets/oracle/oracle(1).png',
    );
  });
}
