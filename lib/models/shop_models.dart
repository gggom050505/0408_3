/// 신규 프로필(로컬 첫 생성) 시점 별조각.
/// 환영 ⭐20개는 첫 설정 마법사를 끝낼 때 [completeFirstSetupWizard]에서 올립니다.
const int kInitialStarFragments = 0;

class ShopItemRow {
  ShopItemRow({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.thumbnailUrl,
    required this.isActive,
  });

  final String id;
  final String name;
  final String type;
  final int price;
  final String? thumbnailUrl;
  final bool isActive;

  factory ShopItemRow.fromJson(Map<String, dynamic> j) {
    final idRaw = j['id'];
    final id = idRaw == null
        ? ''
        : idRaw is String
        ? idRaw
        : idRaw.toString();
    return ShopItemRow(
      id: id,
      name: j['name'] as String? ?? '',
      type: j['type'] as String? ?? 'card',
      price: (j['price'] as num?)?.toInt() ?? 0,
      thumbnailUrl: j['thumbnail_url'] as String?,
      isActive: j['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'price': price,
        'thumbnail_url': thumbnailUrl,
        'is_active': isActive,
      };
}

class UserProfileRow {
  UserProfileRow({
    required this.id,
    required this.starFragments,
    required this.equippedCard,
    required this.equippedMat,
    required this.equippedCardBack,
    this.equippedSlot = 'slot-decor-1',
  });

  final String id;
  final int starFragments;
  final String equippedCard;
  final String equippedMat;
  /// 상점 `type: card_back` — 장착 ID (기본 `default-card-back`)
  final String equippedCardBack;
  /// 상점 `type: slot` — 빈 슬롯 프레임 (기본 `slot-decor-1`)
  final String equippedSlot;

  factory UserProfileRow.fromJson(Map<String, dynamic> j) {
    return UserProfileRow(
      id: j['id'] as String,
      starFragments: (j['star_fragments'] as num?)?.toInt() ?? 0,
      equippedCard: j['equipped_card'] as String? ?? 'default',
      equippedMat: j['equipped_mat'] as String? ?? 'default-mint',
      equippedCardBack: j['equipped_card_back'] as String? ?? 'default-card-back',
      equippedSlot: j['equipped_slot'] as String? ?? 'slot-decor-1',
    );
  }
}

class UserItemRow {
  UserItemRow({
    required this.itemId,
    required this.itemType,
    required this.purchasedAt,
  });

  final String itemId;
  final String itemType;
  final String purchasedAt;

  factory UserItemRow.fromJson(Map<String, dynamic> j) {
    return UserItemRow(
      itemId: j['item_id'] as String,
      itemType: j['item_type'] as String? ?? '',
      purchasedAt: j['purchased_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'item_type': itemType,
        'purchased_at': purchasedAt,
      };
}

/// 상점·가방에서 동일 품목을 구분하는 키 — 선물·구매 중복 방지에 사용.
String gggomShopOwnedKey(String itemId, String itemType) =>
    '$itemId\u{1e}$itemType';

/// 저장소·DB에 (id·타입) 중복 행이 있으면 한 건만 남깁니다.
List<UserItemRow> gggomDedupeOwnedItems(Iterable<UserItemRow> rows) {
  final seen = <String>{};
  final out = <UserItemRow>[];
  for (final e in rows) {
    if (seen.add(gggomShopOwnedKey(e.itemId, e.itemType))) {
      out.add(e);
    }
  }
  return out;
}

/// 출석 일일 보상 지급 결과 — ⭐ 별조각 + [starFragmentsAdded], 미보유 유료 품목 추첨 성공 시 [luckyShopItemGranted]·[luckyShopItemName].
class AttendanceDailyRewardResult {
  const AttendanceDailyRewardResult({
    required this.starFragmentsAdded,
    this.luckyShopItemName,
    this.luckyShopItemGranted = false,
  });

  final int starFragmentsAdded;
  final String? luckyShopItemName;
  final bool luckyShopItemGranted;
}
