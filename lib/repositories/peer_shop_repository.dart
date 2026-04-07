import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/peer_shop_models.dart';
import '../standalone/data_sources.dart';

/// Supabase 개인 상점 — 테이블·RPC는 [docs/supabase_peer_shop_listings.sql] 참고.
class PeerShopRepository implements PeerShopDataSource {
  PeerShopRepository(this._client);

  final SupabaseClient _client;

  static bool _isMissingPeerShopSchema(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('peer_shop_listings') &&
        (msg.contains('does not exist') ||
            msg.contains('schema cache') ||
            msg.contains('not found'));
  }

  Map<String, dynamic> _row(Map<String, dynamic> row) {
    final id = row['id'];
    return {
      'id': id is String ? id : id?.toString() ?? '',
      'seller_id': row['seller_id'] as String? ?? '',
      'seller_display_name': row['seller_display_name'] as String?,
      'item_id': row['item_id'] as String? ?? '',
      'item_type': row['item_type'] as String? ?? '',
      'price_stars': (row['price_stars'] as num?)?.toInt() ?? 0,
      'created_at': row['created_at'] as String? ?? '',
      'status': row['status'] as String? ?? PeerShopListingStatus.active,
    };
  }

  @override
  Future<List<PeerShopListing>> fetchMarketplace(String _) async {
    try {
      final res = await _client
          .from('peer_shop_listings')
          .select()
          .eq('status', PeerShopListingStatus.active)
          .order('created_at', ascending: false);
      final list = res as List<dynamic>;
      return list
          .map(
            (e) => PeerShopListing.fromJson(
              _row(Map<String, dynamic>.from(e as Map)),
            ),
          )
          .toList();
    } catch (e) {
      if (_isMissingPeerShopSchema(e)) {
        return [];
      }
      rethrow;
    }
  }

  @override
  Future<List<PeerShopListing>> fetchMyListings(String sellerId) async {
    try {
      final res = await _client
          .from('peer_shop_listings')
          .select()
          .eq('seller_id', sellerId)
          .eq('status', PeerShopListingStatus.active)
          .order('created_at', ascending: false);
      final list = res as List<dynamic>;
      return list
          .map(
            (e) => PeerShopListing.fromJson(
              _row(Map<String, dynamic>.from(e as Map)),
            ),
          )
          .toList();
    } catch (e) {
      if (_isMissingPeerShopSchema(e)) {
        return [];
      }
      rethrow;
    }
  }

  @override
  Future<PeerShopListing?> createListing({
    required String sellerId,
    required String sellerDisplayName,
    required String itemId,
    required String itemType,
    required int priceStars,
  }) async {
    if (priceStars < 1 || priceStars > 999999) {
      return null;
    }
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid != sellerId) {
      return null;
    }
    try {
      final row = await _client
          .from('peer_shop_listings')
          .insert({
            'seller_id': sellerId,
            'seller_display_name': sellerDisplayName,
            'item_id': itemId,
            'item_type': itemType,
            'price_stars': priceStars,
          })
          .select()
          .single();
      return PeerShopListing.fromJson(_row(Map<String, dynamic>.from(row)));
    } catch (e) {
      if (_isMissingPeerShopSchema(e)) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<bool> cancelListing({
    required String listingId,
    required String sellerId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid != sellerId) {
      return false;
    }
    try {
      final res = await _client
          .from('peer_shop_listings')
          .update({'status': PeerShopListingStatus.cancelled})
          .eq('id', listingId)
          .eq('seller_id', sellerId)
          .eq('status', PeerShopListingStatus.active)
          .select('id');
      final list = res as List<dynamic>;
      return list.isNotEmpty;
    } catch (e) {
      if (_isMissingPeerShopSchema(e)) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<PeerShopPurchaseOutcome> purchaseListing({
    required String buyerId,
    required String listingId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid != buyerId) {
      return PeerShopPurchaseOutcome.error;
    }
    try {
      final raw = await _client.rpc(
        'purchase_peer_shop_listing',
        params: {'p_listing_id': listingId},
      );
      if (raw is! Map) {
        return PeerShopPurchaseOutcome.error;
      }
      final map = Map<String, dynamic>.from(raw);
      if (map['ok'] == true) {
        return PeerShopPurchaseOutcome.success;
      }
      return _mapServerError(map['error'] as String?);
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('function') &&
          (msg.contains('does not exist') || msg.contains('unknown'))) {
        return PeerShopPurchaseOutcome.serverNotConfigured;
      }
      if (_isMissingPeerShopSchema(e)) {
        return PeerShopPurchaseOutcome.serverNotConfigured;
      }
      return PeerShopPurchaseOutcome.error;
    } catch (e) {
      if (e.toString().toLowerCase().contains('function') &&
          e.toString().toLowerCase().contains('exist')) {
        return PeerShopPurchaseOutcome.serverNotConfigured;
      }
      return PeerShopPurchaseOutcome.error;
    }
  }

  PeerShopPurchaseOutcome _mapServerError(String? code) {
    return switch (code) {
      'gone' => PeerShopPurchaseOutcome.listingGone,
      'not_found' => PeerShopPurchaseOutcome.notFound,
      'stars' => PeerShopPurchaseOutcome.insufficientStars,
      'duplicate' => PeerShopPurchaseOutcome.alreadyOwns,
      'own' => PeerShopPurchaseOutcome.cannotBuyOwnListing,
      'seller_item' => PeerShopPurchaseOutcome.sellerNoLongerHasItem,
      _ => PeerShopPurchaseOutcome.error,
    };
  }
}
