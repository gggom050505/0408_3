// 개인 상점(유저 간 별조각 거래) — 진열·구매 결과.

/// Supabase `peer_shop_listings.status` / 로컬 보드의 유효 진열.
abstract class PeerShopListingStatus {
  static const active = 'active';
  static const cancelled = 'cancelled';
  static const sold = 'sold';
}

class PeerShopListing {
  const PeerShopListing({
    required this.id,
    required this.sellerId,
    this.sellerDisplayName,
    required this.itemId,
    required this.itemType,
    required this.priceStars,
    required this.createdAtIso,
    this.status = PeerShopListingStatus.active,
  });

  final String id;
  final String sellerId;
  final String? sellerDisplayName;
  final String itemId;
  final String itemType;
  final int priceStars;
  final String createdAtIso;
  final String status;

  factory PeerShopListing.fromJson(Map<String, dynamic> j) {
    return PeerShopListing(
      id: j['id'] as String,
      sellerId: j['seller_id'] as String? ?? '',
      sellerDisplayName: j['seller_display_name'] as String?,
      itemId: j['item_id'] as String,
      itemType: j['item_type'] as String? ?? '',
      priceStars: (j['price_stars'] as num?)?.toInt() ?? 0,
      createdAtIso: j['created_at'] as String? ?? '',
      status: j['status'] as String? ?? PeerShopListingStatus.active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_id': sellerId,
        if (sellerDisplayName != null) 'seller_display_name': sellerDisplayName,
        'item_id': itemId,
        'item_type': itemType,
        'price_stars': priceStars,
        'created_at': createdAtIso,
        'status': status,
      };
}

enum PeerShopPurchaseOutcome {
  success,
  /// 진열이 없거나 이미 팔림
  listingGone,
  insufficientStars,
  alreadyOwns,
  cannotBuyOwnListing,
  sellerNoLongerHasItem,
  notFound,
  serverNotConfigured,
  error,
}
