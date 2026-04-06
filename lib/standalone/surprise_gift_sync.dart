import 'dart:math' show Random;

import '../models/shop_models.dart';
import '../models/surprise_gift_models.dart';

class SurpriseGiftSyncResult {
  const SurpriseGiftSyncResult({this.offer, required this.stateChanged});

  final SurpriseGiftOffer? offer;
  final bool stateChanged;
}

/// 상점 `shop_items` 카탈로그에서만 깜짝 선물(유료·미보유 품목 1개).
class SurpriseGiftSync {
  SurpriseGiftSync._();

  static const _giftableTypes = <String>{
    'card',
    'card_back',
    'mat',
    'slot',
    'oracle_card',
    'korea_major_card',
  };

  static int _randomIntervalDays(Random rng) => 2 + rng.nextInt(6);

  static bool _isOwned(List<UserItemRow> owned, String itemId, String itemType) =>
      owned.any((e) => e.itemId == itemId && e.itemType == itemType);

  static ShopItemRow? _findRow(List<ShopItemRow> catalog, String id, String type) {
    for (final e in catalog) {
      if (e.id == id && e.type == type) {
        return e;
      }
    }
    return null;
  }

  /// [state]를 갱신하고, 상점에 보여줄 [offer]가 있으면 반환합니다.
  static SurpriseGiftSyncResult run({
    required SurpriseGiftState state,
    required List<ShopItemRow> catalog,
    required List<UserItemRow> owned,
    required Random rng,
    required DateTime nowUtc,
  }) {
    var changed = false;

    bool clearPendingScheduleNext() {
      state.pendingItemId = null;
      state.pendingItemType = null;
      state.nextEligibleAfterUtc =
          nowUtc.add(Duration(days: _randomIntervalDays(rng)));
      changed = true;
      return changed;
    }

    // 대기 중인 선물이 이미 다른 경로로 보유된 경우
    final pid = state.pendingItemId;
    final ptype = state.pendingItemType;
    if (pid != null && ptype != null && _isOwned(owned, pid, ptype)) {
      clearPendingScheduleNext();
      return SurpriseGiftSyncResult(offer: null, stateChanged: changed);
    }

    // 대기 중 선물 표시
    if (state.pendingItemId != null && state.pendingItemType != null) {
      final row = _findRow(catalog, state.pendingItemId!, state.pendingItemType!);
      if (row == null || !row.isActive) {
        clearPendingScheduleNext();
        return SurpriseGiftSyncResult(offer: null, stateChanged: changed);
      }
      if (!_isOwned(owned, row.id, row.type)) {
        return SurpriseGiftSyncResult(
          offer: surpriseOfferFromShopRow(row),
          stateChanged: changed,
        );
      }
      clearPendingScheduleNext();
      return SurpriseGiftSyncResult(offer: null, stateChanged: changed);
    }

    // 첫 실행: 다음 자격 시각만 잡고 종료
    if (state.nextEligibleAfterUtc == null) {
      state.nextEligibleAfterUtc =
          nowUtc.add(Duration(days: _randomIntervalDays(rng)));
      return SurpriseGiftSyncResult(offer: null, stateChanged: true);
    }

    if (nowUtc.isBefore(state.nextEligibleAfterUtc!)) {
      return SurpriseGiftSyncResult(offer: null, stateChanged: changed);
    }

    final candidates = catalog
        .where(
          (e) =>
              e.isActive &&
              e.price > 0 &&
              _giftableTypes.contains(e.type) &&
              !_isOwned(owned, e.id, e.type),
        )
        .toList();

    if (candidates.isEmpty) {
      state.nextEligibleAfterUtc =
          nowUtc.add(Duration(days: _randomIntervalDays(rng)));
      return SurpriseGiftSyncResult(offer: null, stateChanged: true);
    }

    candidates.shuffle(rng);
    final pick = candidates.first;
    state.pendingItemId = pick.id;
    state.pendingItemType = pick.type;
    return SurpriseGiftSyncResult(
      offer: surpriseOfferFromShopRow(pick),
      stateChanged: true,
    );
  }

  /// 무료 수령·정리 후 다음 2~7일 주기로 [state.nextEligibleAfterUtc] 설정.
  static void clearPendingAndScheduleNext({
    required SurpriseGiftState state,
    required DateTime nowUtc,
    required Random rng,
  }) {
    state.pendingItemId = null;
    state.pendingItemType = null;
    state.nextEligibleAfterUtc =
        nowUtc.add(Duration(days: _randomIntervalDays(rng)));
  }
}
