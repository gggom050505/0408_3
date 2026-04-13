import 'dart:math' show Random;

import '../models/attendance_lucky_models.dart';
import '../models/shop_models.dart';

class AttendanceLuckySyncResult {
  const AttendanceLuckySyncResult({
    this.grantedItem,
    this.applyNextEligibleAfterUtc,
  });

  /// 지급할 상점 행(후보가 있을 때만).
  final ShopItemRow? grantedItem;

  /// 레거시 필드 — 현재 출석 선물은 매일 무작위이므로 항상 null.
  final DateTime? applyNextEligibleAfterUtc;
}

/// 매일 출석 시 상점 **유료·미보유** 품목 중 무작위 1개.
/// 별조각 +1은 [grantAttendanceDailyReward]에서 별도 지급.
class AttendanceLuckySync {
  AttendanceLuckySync._();

  static const _giftableTypes = <String>{
    'card',
    'card_back',
    'mat',
    'slot',
    'oracle_card',
    'korea_major_card',
  };

  static bool _isOwned(List<UserItemRow> owned, String itemId, String itemType) =>
      owned.any((e) => e.itemId == itemId && e.itemType == itemType);

  /// [doNotGrantKeys]: [gggomShopOwnedKey](itemId, itemType) — 후보에서 제외할 품목(선택).
  static AttendanceLuckySyncResult evaluate({
    required AttendanceLuckyState state,
    required List<ShopItemRow> catalog,
    required List<UserItemRow> owned,
    required Random rng,
    required DateTime nowUtc,
    Set<String>? doNotGrantKeys,
  }) {
    // [state]·[nowUtc] 는 시그니처 호환용. 쿨다운 없이 매 출석마다 후보 추첨.
    final blocked = doNotGrantKeys ?? const <String>{};
    final candidates = catalog
        .where(
          (e) =>
              e.isActive &&
              e.price > 0 &&
              _giftableTypes.contains(e.type) &&
              !_isOwned(owned, e.id, e.type) &&
              !blocked.contains(gggomShopOwnedKey(e.id, e.type)),
        )
        .toList();

    if (candidates.isEmpty) {
      return const AttendanceLuckySyncResult();
    }

    candidates.shuffle(rng);
    final pick = candidates.first;
    return AttendanceLuckySyncResult(grantedItem: pick);
  }
}
