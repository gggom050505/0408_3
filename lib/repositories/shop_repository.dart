import 'dart:convert';
import 'dart:math' show Random;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/korea_major_card_catalog.dart';
import '../config/mat_shop_catalog.dart';
import '../config/shop_random_prices.dart';
import '../config/starter_gifts.dart'
    show pickFirstSetupEmoticonIds, pickFirstSetupOracleIds, starterKoreaMajorItemIdForUser;
import '../data/card_themes.dart' show defaultThemeId, koreaTraditionalMajorThemeId;
import '../data/card_back_shop_assets.dart' show bundledCardBackShopRows;
import '../data/oracle_assets.dart' show bundledOracleShopCatalogRows;
import '../data/slot_shop_assets.dart'
    show bundledSlotShopRows, kDefaultEquippedSlotId;
import '../models/attendance_lucky_models.dart';
import '../models/shop_models.dart';
import '../models/surprise_gift_models.dart';
import '../standalone/attendance_lucky_sync.dart';
import '../standalone/data_sources.dart';
import '../standalone/local_json_store.dart';
import '../standalone/star_one_purchase_daily.dart';
import '../standalone/surprise_gift_sync.dart';

const _retiredKoreanClayDeckId = 'korean-clay';

class ShopRepository implements ShopDataSource {
  ShopRepository(this._client);

  final SupabaseClient _client;

  /// 변조 방지: 로그인 세션과 요청 `userId`가 같을 때만 원격 별조각·보유를 수정합니다.
  bool _sessionOwnsUser(String userId) {
    final u = _client.auth.currentUser;
    return u != null && u.id == userId;
  }

  String _safeUserId(String id) => id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  String _surpriseGiftFile(String userId) =>
      'local_surprise_gift_v1_${_safeUserId(userId)}.json';

  Future<SurpriseGiftState> _loadSurpriseGiftState(String userId) async {
    final raw = await loadLocalJsonFile(_surpriseGiftFile(userId));
    if (raw == null || raw.isEmpty) {
      return SurpriseGiftState();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SurpriseGiftState.fromJson(decoded);
      }
    } catch (_) {}
    return SurpriseGiftState();
  }

  Future<void> _saveSurpriseGiftState(String userId, SurpriseGiftState state) async {
    await saveLocalJsonFile(
      _surpriseGiftFile(userId),
      jsonEncode(state.toJson()),
    );
  }

  String _attendanceLuckyFile(String userId) =>
      'local_attendance_lucky_v1_${_safeUserId(userId)}.json';

  Future<AttendanceLuckyState> _loadAttendanceLuckyState(String userId) async {
    final raw = await loadLocalJsonFile(_attendanceLuckyFile(userId));
    if (raw == null || raw.isEmpty) {
      return AttendanceLuckyState();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AttendanceLuckyState.fromJson(decoded);
      }
    } catch (_) {}
    return AttendanceLuckyState();
  }

  Future<void> _saveAttendanceLuckyState(String userId, AttendanceLuckyState state) async {
    await saveLocalJsonFile(
      _attendanceLuckyFile(userId),
      jsonEncode(state.toJson()),
    );
  }

  @override
  Future<List<ShopItemRow>> fetchShopItems() async {
    final res = await _client
        .from('shop_items')
        .select()
        .eq('is_active', true)
        .order('created_at');
    final list = res as List<dynamic>;
    var items =
        list.map((e) => ShopItemRow.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    items.removeWhere(
      (e) => e.id == koreaTraditionalMajorThemeId && e.type == 'card',
    );
    for (final row in koreaMajorCardShopCatalogRows()) {
      if (!items.any((e) => e.id == row.id)) {
        items.add(row);
      }
    }
    for (final row in bundledOracleShopCatalogRows()) {
      if (!items.any((e) => e.id == row.id)) {
        items.add(row);
      }
    }
    for (final row in bundledSlotShopRows()) {
      if (!items.any((e) => e.id == row.id)) {
        items.add(row);
      }
    }
    for (final row in bundledCardBackShopRows()) {
      if (!items.any((e) => e.id == row.id)) {
        items.add(row);
      }
    }
    for (final row in bundledMatShopRows()) {
      if (!items.any((e) => e.id == row.id)) {
        items.add(row);
      }
    }
    return items;
  }

  @override
  Future<UserProfileRow?> fetchProfile(String userId) async {
    final res = await _client.from('user_profiles').select().eq('id', userId).maybeSingle();
    UserProfileRow profile;
    if (res != null) {
      profile = UserProfileRow.fromJson(Map<String, dynamic>.from(res));
    } else {
      final inserted = await _client
          .from('user_profiles')
          .insert({'id': userId, 'star_fragments': kInitialStarFragments})
          .select()
          .single();
      profile = UserProfileRow.fromJson(Map<String, dynamic>.from(inserted));
    }
    if (profile.equippedCard == _retiredKoreanClayDeckId) {
      await _client
          .from('user_profiles')
          .update({'equipped_card': defaultThemeId})
          .eq('id', userId);
      profile = UserProfileRow(
        id: profile.id,
        starFragments: profile.starFragments,
        equippedCard: defaultThemeId,
        equippedMat: profile.equippedMat,
        equippedCardBack: profile.equippedCardBack,
        equippedSlot: profile.equippedSlot,
      );
    }
    return profile;
  }

  @override
  Future<List<UserItemRow>> fetchOwnedItems(String userId) async {
    final res = await _client
        .from('user_items')
        .select('item_id, item_type, purchased_at')
        .eq('user_id', userId);
    final list = res as List<dynamic>;
    final rows =
        list.map((e) => UserItemRow.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final filtered = rows
        .where((e) => !(e.itemId == _retiredKoreanClayDeckId && e.itemType == 'card'))
        .toList();
    return gggomDedupeOwnedItems(filtered);
  }

  /// 웹 `(main)/page`와 동일한 기본 지급.
  @override
  Future<void> ensureDefaultUserItems(String userId) async {
    if (!_sessionOwnsUser(userId)) {
      return;
    }
    var owned = await fetchOwnedItems(userId);

    if (owned.any(
      (e) => e.itemType == 'card' && e.itemId == koreaTraditionalMajorThemeId,
    )) {
      await _client
          .from('user_items')
          .delete()
          .eq('user_id', userId)
          .eq('item_id', koreaTraditionalMajorThemeId)
          .eq('item_type', 'card');
      for (var i = 0; i < 22; i++) {
        final pid = koreaMajorCardShopItemId(i);
        try {
          await _client.from('user_items').insert({
            'user_id': userId,
            'item_id': pid,
            'item_type': 'korea_major_card',
          });
        } catch (_) {}
      }
      owned = await fetchOwnedItems(userId);
    }

    final profKorea = await fetchProfile(userId);
    if (profKorea != null &&
        profKorea.equippedCard == koreaTraditionalMajorThemeId &&
        !owned.any((e) => e.itemType == 'korea_major_card')) {
      await _client
          .from('user_profiles')
          .update({'equipped_card': defaultThemeId})
          .eq('id', userId);
    }

    const defaults = [
      ('default', 'card'),
      ('default-card-back', 'card_back'),
      ('default-mint', 'mat'),
      (kDefaultEquippedSlotId, 'slot'),
    ];
    for (final e in defaults) {
      if (!owned.any((o) => o.itemId == e.$1 && o.itemType == e.$2)) {
        try {
          await _client.from('user_items').insert({
            'user_id': userId,
            'item_id': e.$1,
            'item_type': e.$2,
          });
        } catch (_) {}
      }
    }
    owned = await fetchOwnedItems(userId);
    final koreaGift = starterKoreaMajorItemIdForUser(userId);
    if (!owned.any((e) => e.itemType == 'korea_major_card' && e.itemId == koreaGift)) {
      try {
        await _client.from('user_items').insert({
          'user_id': userId,
          'item_id': koreaGift,
          'item_type': 'korea_major_card',
        });
      } catch (_) {}
    }
  }

  @override
  Future<bool> buyItem({
    required String userId,
    required String itemId,
    required int price,
    required String type,
    required UserProfileRow profile,
    required List<UserItemRow> owned,
  }) async {
    if (!_sessionOwnsUser(userId)) {
      return false;
    }
    if (profile.starFragments < price) {
      return false;
    }
    if (owned.any((i) => i.itemId == itemId && i.itemType == type)) {
      return false;
    }
    if (price == 1) {
      final last = await loadStarOneDailyPurchaseYmd(userId);
      if (!gggomCanPurchaseStarOnePricedItemToday(last)) {
        return false;
      }
    }
    if (price == 2) {
      final s = await loadStarTwoDailyState(userId);
      if (!gggomCanPurchaseStarTwoPricedItemToday(storedYmd: s.ymd, storedCount: s.count)) {
        return false;
      }
    }
    final nextStars = profile.starFragments - price;
    final u = await _client
        .from('user_profiles')
        .update({'star_fragments': nextStars})
        .eq('id', userId)
        .select()
        .maybeSingle();
    if (u == null) {
      return false;
    }
    try {
      await _client.from('user_items').insert({
        'user_id': userId,
        'item_id': itemId,
        'item_type': type,
      });
    } catch (_) {
      await _client
          .from('user_profiles')
          .update({'star_fragments': profile.starFragments})
          .eq('id', userId);
      return false;
    }
    if (price == 1) {
      await recordStarOneDailyPurchaseYmd(userId);
    }
    if (price == 2) {
      final s = await loadStarTwoDailyState(userId);
      final next = gggomNextStarTwoPurchaseState(storedYmd: s.ymd, storedCount: s.count);
      await saveStarTwoDailyState(userId, next.ymd, next.count);
    }
    return true;
  }

  @override
  Future<UserProfileRow?> equipItem({
    required String userId,
    required String itemId,
    required String type,
  }) async {
    if (!_sessionOwnsUser(userId)) {
      return null;
    }
    if (type == 'oracle_card' || type == 'korea_major_card') {
      final res =
          await _client.from('user_profiles').select().eq('id', userId).single();
      return UserProfileRow.fromJson(Map<String, dynamic>.from(res));
    }
    final field = switch (type) {
      'card' => 'equipped_card',
      'card_back' => 'equipped_card_back',
      'slot' => 'equipped_slot',
      _ => 'equipped_mat',
    };
    final res = await _client
        .from('user_profiles')
        .update({field: itemId})
        .eq('id', userId)
        .select()
        .single();
    return UserProfileRow.fromJson(Map<String, dynamic>.from(res));
  }

  @override
  Future<AttendanceDailyRewardResult?> grantAttendanceDailyReward(String userId) async {
    if (!_sessionOwnsUser(userId)) {
      return null;
    }
    final profile = await fetchProfile(userId);
    if (profile == null) {
      return null;
    }

    await _client.from('user_profiles').update({
      'star_fragments': profile.starFragments + 1,
    }).eq('id', userId);

    final items = await fetchShopItems();
    final owned = await fetchOwnedItems(userId);
    final luckyState = await _loadAttendanceLuckyState(userId);
    final surpriseState = await _loadSurpriseGiftState(userId);
    final blockSurprise = <String>{};
    final pid = surpriseState.pendingItemId;
    final ptype = surpriseState.pendingItemType;
    if (pid != null && ptype != null) {
      blockSurprise.add(gggomShopOwnedKey(pid, ptype));
    }
    final lucky = AttendanceLuckySync.evaluate(
      state: luckyState,
      catalog: items,
      owned: owned,
      rng: Random(),
      nowUtc: DateTime.now().toUtc(),
      doNotGrantKeys: blockSurprise.isEmpty ? null : blockSurprise,
    );

    String? luckyName;
    var luckyGranted = false;
    final row = lucky.grantedItem;

    if (row != null) {
      final ownedNow = await fetchOwnedItems(userId);
      if (!ownedNow.any((e) => e.itemId == row.id && e.itemType == row.type)) {
        try {
          await _client.from('user_items').insert({
            'user_id': userId,
            'item_id': row.id,
            'item_type': row.type,
          });
          luckyName = row.name;
          luckyGranted = true;
        } catch (_) {}
      }
    }

    luckyState.nextEligibleAfterUtc = lucky.applyNextEligibleAfterUtc;
    await _saveAttendanceLuckyState(userId, luckyState);

    return AttendanceDailyRewardResult(
      starFragmentsAdded: 1,
      luckyShopItemName: luckyName,
      luckyShopItemGranted: luckyGranted,
    );
  }

  @override
  Future<bool> completeFirstSetupWizard(String userId) async {
    if (!_sessionOwnsUser(userId)) {
      return false;
    }
    try {
      await equipItem(
        userId: userId,
        itemId: 'default-card-back',
        type: 'card_back',
      );
      await equipItem(
        userId: userId,
        itemId: kDefaultEquippedSlotId,
        type: 'slot',
      );
      var owned = await fetchOwnedItems(userId);
      final oracleHave = owned
          .where((e) => e.itemType == 'oracle_card')
          .map((e) => e.itemId)
          .toSet();
      for (final id in pickFirstSetupOracleIds(userId, oracleHave)) {
        try {
          await _client.from('user_items').insert({
            'user_id': userId,
            'item_id': id,
            'item_type': 'oracle_card',
          });
          oracleHave.add(id);
        } catch (_) {}
      }
      final emoRes =
          await _client.from('user_emoticons').select('emoticon_id').eq('user_id', userId);
      final emoHave = (emoRes as List<dynamic>)
          .map((e) => (e as Map)['emoticon_id'] as String?)
          .whereType<String>()
          .toSet();
      for (final id in pickFirstSetupEmoticonIds(userId, emoHave)) {
        try {
          await _client.from('user_emoticons').insert({
            'user_id': userId,
            'emoticon_id': id,
            'source': 'gift',
          });
          emoHave.add(id);
        } catch (_) {}
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<UserProfileRow?> grantAdRewardStars(String userId, {int amount = 3}) async {
    if (!_sessionOwnsUser(userId)) {
      return null;
    }
    final profile = await fetchProfile(userId);
    if (profile == null) {
      return null;
    }
    final next = profile.starFragments + amount;
    await _client.from('user_profiles').update({'star_fragments': next}).eq('id', userId);
    return UserProfileRow(
      id: profile.id,
      starFragments: next,
      equippedCard: profile.equippedCard,
      equippedMat: profile.equippedMat,
      equippedCardBack: profile.equippedCardBack,
      equippedSlot: profile.equippedSlot,
    );
  }

  @override
  Future<SurpriseGiftOffer?> syncSurpriseGift(
    String userId,
    List<ShopItemRow> activeCatalog,
  ) async {
    await ensureDefaultUserItems(userId);
    final state = await _loadSurpriseGiftState(userId);
    final owned = await fetchOwnedItems(userId);
    final r = SurpriseGiftSync.run(
      state: state,
      catalog: activeCatalog,
      owned: owned,
      rng: Random(),
      nowUtc: DateTime.now().toUtc(),
    );
    if (r.stateChanged) {
      await _saveSurpriseGiftState(userId, state);
    }
    return r.offer;
  }

  @override
  Future<ClaimSurpriseGiftResult> claimSurpriseGift(
    String userId,
    SurpriseGiftOffer offer,
  ) async {
    if (!_sessionOwnsUser(userId)) {
      return ClaimSurpriseGiftResult.failed;
    }
    final state = await _loadSurpriseGiftState(userId);
    if (state.pendingItemId != offer.itemId || state.pendingItemType != offer.itemType) {
      return ClaimSurpriseGiftResult.failed;
    }
    final owned = await fetchOwnedItems(userId);
    if (owned.any((e) => e.itemId == offer.itemId && e.itemType == offer.itemType)) {
      SurpriseGiftSync.clearPendingAndScheduleNext(
        state: state,
        nowUtc: DateTime.now().toUtc(),
        rng: Random(),
      );
      await _saveSurpriseGiftState(userId, state);
      return ClaimSurpriseGiftResult.alreadyOwned;
    }
    try {
      await _client.from('user_items').insert({
        'user_id': userId,
        'item_id': offer.itemId,
        'item_type': offer.itemType,
      });
    } catch (_) {
      return ClaimSurpriseGiftResult.failed;
    }
    SurpriseGiftSync.clearPendingAndScheduleNext(
      state: state,
      nowUtc: DateTime.now().toUtc(),
      rng: Random(),
    );
    await _saveSurpriseGiftState(userId, state);
    return ClaimSurpriseGiftResult.granted;
  }
}
