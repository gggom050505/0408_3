import 'shop_models.dart';

/// [ShopDataSource.claimSurpriseGift] 결과.
enum ClaimSurpriseGiftResult {
  /// 보유에 새로 추가함.
  granted,

  /// 이미 동일 품목을 가방에 보유 — 중복 지급 없이 대기만 해제·다음 주기 예약.
  alreadyOwned,

  /// pending 불일치·카탈로그·DB 오류 등.
  failed,
}

/// 깜짝 선물(2~7일 간격) 상태 — 로컬 user JSON / 별도 파일에 저장.
class SurpriseGiftState {
  SurpriseGiftState({
    this.nextEligibleAfterUtc,
    this.pendingItemId,
    this.pendingItemType,
  });

  /// 이 시각(UTC) 이후에 새 깜짝 선물 후보를 뽑을 수 있음. null이면 첫 동기화에서 설정.
  DateTime? nextEligibleAfterUtc;

  String? pendingItemId;
  String? pendingItemType;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (nextEligibleAfterUtc != null)
          'next_eligible_after': nextEligibleAfterUtc!.toUtc().toIso8601String(),
        if (pendingItemId != null) 'pending_item_id': pendingItemId,
        if (pendingItemType != null) 'pending_item_type': pendingItemType,
      };

  factory SurpriseGiftState.fromJson(Map<String, dynamic>? m) {
    if (m == null || m.isEmpty) {
      return SurpriseGiftState();
    }
    DateTime? next;
    final raw = m['next_eligible_after'];
    if (raw is String && raw.isNotEmpty) {
      next = DateTime.tryParse(raw)?.toUtc();
    }
    return SurpriseGiftState(
      nextEligibleAfterUtc: next,
      pendingItemId: m['pending_item_id'] as String?,
      pendingItemType: m['pending_item_type'] as String?,
    );
  }
}

/// 상점에 표시할 깜짝 선물 한 건.
class SurpriseGiftOffer {
  const SurpriseGiftOffer({
    required this.itemId,
    required this.itemType,
    required this.name,
    this.thumbnailUrl,
  });

  final String itemId;
  final String itemType;
  final String name;
  final String? thumbnailUrl;
}

/// [ShopItemRow] → [SurpriseGiftOffer].
SurpriseGiftOffer surpriseOfferFromShopRow(ShopItemRow row) => SurpriseGiftOffer(
      itemId: row.id,
      itemType: row.type,
      name: row.name,
      thumbnailUrl: row.thumbnailUrl,
    );
