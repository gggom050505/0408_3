import 'dart:convert';
import 'dart:math';

import '../models/peer_shop_models.dart';
import '../models/shop_models.dart';
import 'data_sources.dart';
import 'local_json_store.dart';
import 'local_user_data_wipe.dart' show safeStandaloneUserFileId;

const _boardFile = 'local_peer_shop_listings_v1.json';

class _LocalUserShopFile {
  _LocalUserShopFile({
    required this.profile,
    required this.owned,
    required this.rawMap,
  });

  UserProfileRow profile;
  final List<UserItemRow> owned;
  final Map<String, dynamic> rawMap;
}

/// 같은 기기의 로컬 계정끼리 `local_peer_shop_listings_v1.json`으로 진열을 공유합니다.
/// 웹·단일 기기 베타용 로컬 개인 상점.
class LocalPeerShopRepository implements PeerShopDataSource {
  LocalPeerShopRepository._();
  static final LocalPeerShopRepository instance = LocalPeerShopRepository._();

  String _userStatePath(String userId) =>
      'local_shop_user_state_v1_${safeStandaloneUserFileId(userId)}.json';

  Future<Map<String, dynamic>> _loadBoard() async {
    final raw = await loadLocalJsonFile(_boardFile);
    if (raw == null || raw.isEmpty) {
      return {'version': 1, 'listings': <dynamic>[]};
    }
    try {
      final dec = jsonDecode(raw);
      if (dec is Map<String, dynamic>) {
        final list = dec['listings'];
        if (list is List) {
          return Map<String, dynamic>.from(dec);
        }
      }
    } catch (_) {}
    return {'version': 1, 'listings': <dynamic>[]};
  }

  Future<void> _saveBoard(Map<String, dynamic> board) async {
    await saveLocalJsonFile(_boardFile, jsonEncode(board));
  }

  List<PeerShopListing> _parseListings(Map<String, dynamic> board) {
    final raw = board['listings'];
    if (raw is! List) {
      return [];
    }
    final out = <PeerShopListing>[];
    for (final e in raw) {
      if (e is! Map) {
        continue;
      }
      try {
        out.add(PeerShopListing.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    return out;
  }

  Future<_LocalUserShopFile?> _loadUserFile(String userId) async {
    final raw = await loadLocalJsonFile(_userStatePath(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final dec = jsonDecode(raw);
      if (dec is! Map<String, dynamic>) {
        return null;
      }
      final profMap = dec['profile'];
      if (profMap is! Map) {
        return null;
      }
      final profile = UserProfileRow.fromJson(
        Map<String, dynamic>.from(profMap),
      );
      final ownRaw = dec['owned'];
      final owned = <UserItemRow>[];
      if (ownRaw is List) {
        for (final o in ownRaw) {
          if (o is Map) {
            owned.add(UserItemRow.fromJson(Map<String, dynamic>.from(o)));
          }
        }
      }
      return _LocalUserShopFile(
        profile: profile,
        owned: gggomDedupeOwnedItems(owned),
        rawMap: dec,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveUserFile(_LocalUserShopFile snap) async {
    snap.rawMap['profile'] = {
      'id': snap.profile.id,
      'star_fragments': snap.profile.starFragments,
      'equipped_card': snap.profile.equippedCard,
      'equipped_mat': snap.profile.equippedMat,
      'equipped_card_back': snap.profile.equippedCardBack,
      'equipped_slot': snap.profile.equippedSlot,
    };
    snap.rawMap['owned'] = snap.owned.map((e) => e.toJson()).toList();
    await saveLocalJsonFile(
      _userStatePath(snap.profile.id),
      jsonEncode(snap.rawMap),
    );
  }

  List<String> _emoticonsOf(_LocalUserShopFile snap) {
    final raw = snap.rawMap['emoticons'];
    if (raw is! List) {
      return <String>[];
    }
    final out = <String>[];
    for (final e in raw) {
      if (e is String && e.isNotEmpty) {
        out.add(e);
      }
    }
    return out;
  }

  bool _ownsItem(_LocalUserShopFile snap, String itemId, String itemType) {
    if (itemType == 'emoticon') {
      return _emoticonsOf(snap).contains(itemId);
    }
    return snap.owned.any((o) => o.itemId == itemId && o.itemType == itemType);
  }

  void _addOwnedItem(
    _LocalUserShopFile snap, {
    required String itemId,
    required String itemType,
  }) {
    if (itemType == 'emoticon') {
      final list = _emoticonsOf(snap);
      if (!list.contains(itemId)) {
        list.add(itemId);
      }
      snap.rawMap['emoticons'] = list;
      return;
    }
    snap.owned.add(
      UserItemRow(
        itemId: itemId,
        itemType: itemType,
        purchasedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }

  @override
  Future<List<PeerShopListing>> fetchMarketplace(String _) async {
    final board = await _loadBoard();
    return _parseListings(
        board,
      ).where((e) => e.status == PeerShopListingStatus.active).toList()
      ..sort((a, b) => b.createdAtIso.compareTo(a.createdAtIso));
  }

  @override
  Future<List<PeerShopListing>> fetchMyListings(String sellerId) async {
    final board = await _loadBoard();
    return _parseListings(board)
        .where(
          (e) =>
              e.status == PeerShopListingStatus.active &&
              e.sellerId == sellerId,
        )
        .toList()
      ..sort((a, b) => b.createdAtIso.compareTo(a.createdAtIso));
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
    final snap = await _loadUserFile(sellerId);
    if (snap == null) {
      return null;
    }
    final board = await _loadBoard();
    final existing = _parseListings(board);
    if (existing.any(
      (e) =>
          e.status == PeerShopListingStatus.active &&
          e.sellerId == sellerId &&
          e.itemId == itemId &&
          e.itemType == itemType,
    )) {
      return null;
    }
    final id =
        'local_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 20)}';
    final created = DateTime.now().toUtc().toIso8601String();
    final listing = PeerShopListing(
      id: id,
      sellerId: sellerId,
      sellerDisplayName: sellerDisplayName,
      itemId: itemId,
      itemType: itemType,
      priceStars: priceStars,
      createdAtIso: created,
    );
    final list = List<dynamic>.from(board['listings'] as List? ?? []);
    list.add(listing.toJson());
    board['listings'] = list;
    await _saveBoard(board);
    return listing;
  }

  @override
  Future<bool> cancelListing({
    required String listingId,
    required String sellerId,
  }) async {
    final board = await _loadBoard();
    final raw = board['listings'];
    if (raw is! List) {
      return false;
    }
    var changed = false;
    final next = <dynamic>[];
    for (final e in raw) {
      if (e is! Map) {
        next.add(e);
        continue;
      }
      final m = Map<String, dynamic>.from(e);
      final id = m['id'] as String?;
      final sid = m['seller_id'] as String?;
      final st = m['status'] as String? ?? PeerShopListingStatus.active;
      if (id == listingId &&
          sid == sellerId &&
          st == PeerShopListingStatus.active) {
        changed = true;
        continue;
      }
      next.add(e);
    }
    if (!changed) {
      return false;
    }
    board['listings'] = next;
    await _saveBoard(board);
    return true;
  }

  @override
  Future<PeerShopPurchaseOutcome> purchaseListing({
    required String buyerId,
    required String listingId,
  }) async {
    final board = await _loadBoard();
    final listings = _parseListings(board);
    PeerShopListing? listing;
    for (final e in listings) {
      if (e.id == listingId && e.status == PeerShopListingStatus.active) {
        listing = e;
        break;
      }
    }
    if (listing == null) {
      return PeerShopPurchaseOutcome.listingGone;
    }
    final itemId = listing.itemId;
    final itemType = listing.itemType;
    final priceStars = listing.priceStars;
    final sellerId = listing.sellerId;
    if (sellerId == buyerId) {
      return PeerShopPurchaseOutcome.cannotBuyOwnListing;
    }
    final buyer = await _loadUserFile(buyerId);
    final seller = await _loadUserFile(sellerId);
    if (buyer == null || seller == null) {
      return PeerShopPurchaseOutcome.error;
    }
    if (buyer.profile.starFragments < priceStars) {
      return PeerShopPurchaseOutcome.insufficientStars;
    }
    if (_ownsItem(buyer, itemId, itemType)) {
      return PeerShopPurchaseOutcome.alreadyOwns;
    }
    seller.profile = UserProfileRow(
      id: seller.profile.id,
      starFragments: seller.profile.starFragments + priceStars,
      equippedCard: seller.profile.equippedCard,
      equippedMat: seller.profile.equippedMat,
      equippedCardBack: seller.profile.equippedCardBack,
      equippedSlot: seller.profile.equippedSlot,
    );

    buyer.profile = UserProfileRow(
      id: buyer.profile.id,
      starFragments: buyer.profile.starFragments - priceStars,
      equippedCard: buyer.profile.equippedCard,
      equippedMat: buyer.profile.equippedMat,
      equippedCardBack: buyer.profile.equippedCardBack,
      equippedSlot: buyer.profile.equippedSlot,
    );
    _addOwnedItem(buyer, itemId: itemId, itemType: itemType);

    await _saveUserFile(seller);
    await _saveUserFile(buyer);

    final raw = board['listings'];
    if (raw is List) {
      final next = <dynamic>[];
      for (final e in raw) {
        if (e is! Map) {
          next.add(e);
          continue;
        }
        final m = Map<String, dynamic>.from(e);
        if ((m['id'] as String?) == listingId) {
          continue;
        }
        next.add(e);
      }
      board['listings'] = next;
      await _saveBoard(board);
    }

    return PeerShopPurchaseOutcome.success;
  }

  /// 탈퇴·삭제 시 해당 판매자의 진열 제거.
  Future<void> removeListingsForSeller(String sellerId) async {
    final board = await _loadBoard();
    final raw = board['listings'];
    if (raw is! List) {
      return;
    }
    final next = <dynamic>[];
    for (final e in raw) {
      if (e is! Map) {
        next.add(e);
        continue;
      }
      final m = Map<String, dynamic>.from(e);
      if ((m['seller_id'] as String?) == sellerId) {
        continue;
      }
      next.add(e);
    }
    board['listings'] = next;
    await _saveBoard(board);
  }
}
