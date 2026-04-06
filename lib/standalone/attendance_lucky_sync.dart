import 'dart:math' show Random;

import '../models/attendance_lucky_models.dart';
import '../models/shop_models.dart';

class AttendanceLuckySyncResult {
  const AttendanceLuckySyncResult({
    this.grantedItem,
    this.applyNextEligibleAfterUtc,
  });

  /// 지급할 상점 행. 성공 시에만 [applyNextEligibleAfterUtc]를 상태에 반영하세요.
  final ShopItemRow? grantedItem;

  /// 행운 주기를 이 시각(UTC) 이후로 미룸. 후보 없음·지급 성공 시 적용.
  final DateTime? applyNextEligibleAfterUtc;
}

/// 출석 시 1~3일 주기로, 상점 유료·미보유 품목 1개(깜짝 선물과 동일 타입군).
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

  static int _cooldownDays(Random rng) => 1 + rng.nextInt(3);

  static bool _isOwned(List<UserItemRow> owned, String itemId, String itemType) =>
      owned.any((e) => e.itemId == itemId && e.itemType == itemType);

  /// [state]는 읽기만 합니다. 반환값을 호출 측에서 확정 후 저장하세요.
  /// [doNotGrantKeys]: [gggomShopOwnedKey](itemId, itemType) 문자열 집합.
  /// 깜짝 선물로 이미 예약된 품목 등, 보유 외 사유로 출석 행운 후보에서 제외합니다.
  static AttendanceLuckySyncResult evaluate({
    required AttendanceLuckyState state,
    required List<ShopItemRow> catalog,
    required List<UserItemRow> owned,
    required Random rng,
    required DateTime nowUtc,
    Set<String>? doNotGrantKeys,
  }) {
    final eligible = state.nextEligibleAfterUtc == null ||
        !nowUtc.isBefore(state.nextEligibleAfterUtc!);

    if (!eligible) {
      return const AttendanceLuckySyncResult();
    }

    final nextGap =
        nowUtc.add(Duration(days: _cooldownDays(rng)));

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
      return AttendanceLuckySyncResult(applyNextEligibleAfterUtc: nextGap);
    }

    candidates.shuffle(rng);
    final pick = candidates.first;
    return AttendanceLuckySyncResult(
      grantedItem: pick,
      applyNextEligibleAfterUtc: nextGap,
    );
  }
}
