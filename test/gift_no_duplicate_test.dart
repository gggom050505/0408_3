import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gggom_tarot/models/attendance_lucky_models.dart';
import 'package:gggom_tarot/models/shop_models.dart';
import 'package:gggom_tarot/standalone/attendance_lucky_sync.dart';

void main() {
  test('gggomDedupeOwnedItems — (id·타입) 중복 행 제거', () {
    final rows = [
      UserItemRow(itemId: 'a', itemType: 'oracle_card', purchasedAt: '1'),
      UserItemRow(itemId: 'a', itemType: 'oracle_card', purchasedAt: '2'),
      UserItemRow(itemId: 'a', itemType: 'mat', purchasedAt: '3'),
    ];
    final d = gggomDedupeOwnedItems(rows);
    expect(d.length, 2);
    expect(d.any((e) => e.itemType == 'oracle_card' && e.itemId == 'a'), true);
    expect(d.any((e) => e.itemType == 'mat' && e.itemId == 'a'), true);
  });

  test('출석 행운 — doNotGrantKeys에 있는 품목은 후보에서 제외', () {
    final catalog = [
      ShopItemRow(
        id: 'gift-only',
        name: '테스트',
        type: 'mat',
        price: 5,
        isActive: true,
      ),
    ];
    final owned = <UserItemRow>[];
    final state = AttendanceLuckyState(nextEligibleAfterUtc: null);
    final blocked = {gggomShopOwnedKey('gift-only', 'mat')};
    final r = AttendanceLuckySync.evaluate(
      state: state,
      catalog: catalog,
      owned: owned,
      rng: Random(0),
      nowUtc: DateTime.utc(2026, 4, 5),
      doNotGrantKeys: blocked,
    );
    expect(r.grantedItem, isNull);
    expect(r.applyNextEligibleAfterUtc, isNotNull);
  });
}
