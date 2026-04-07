import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/bundle_emoticon_catalog.dart'
    show bundleEmoticonPriceForUser, kBundleEmoticonIds, kBundleEmoticonRows;
import '../config/shop_random_prices.dart';
import '../config/starter_gifts.dart' show starterEmoticonIdsForUser;
import '../models/emoticon_models.dart';
import '../standalone/data_sources.dart';
import '../standalone/star_one_purchase_daily.dart';

class EmoticonRepository implements EmoticonDataSource {
  EmoticonRepository(this._client);

  final SupabaseClient _client;

  bool _sessionOwnsUser(String userId) {
    final u = _client.auth.currentUser;
    return u != null && u.id == userId;
  }

  @override
  Future<List<EmoticonPackRow>> fetchPacks() async {
    final res = await _client
        .from('emoticon_packs')
        .select('*, emoticons(*)')
        .eq('is_active', true)
        .order('sort_order')
        .order('created_at');
    final list = res as List<dynamic>;
    return list.map((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      final emoRaw = (m['emoticons'] as List<dynamic>?) ?? [];
      final emoticons = emoRaw
          .map((e) => EmoticonRow.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.isActive)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return EmoticonPackRow.fromJson(m, emoticons);
    }).toList();
  }

  @override
  Future<List<EmoticonRow>> fetchAllEmoticons() async {
    return List<EmoticonRow>.from(kBundleEmoticonRows);
  }

  @override
  Future<List<String>> fetchOwned(String userId) async {
    final out = {...starterEmoticonIdsForUser(userId)};
    final res = await _client.from('user_emoticons').select('emoticon_id').eq('user_id', userId);
    final list = res as List<dynamic>;
    out.addAll(
      list
          .map((e) => (e as Map)['emoticon_id'] as String?)
          .whereType<String>(),
    );
    return out.toList()..sort();
  }

  @override
  Future<bool> buyEmoticon({
    required String userId,
    required String emoticonId,
    required int price,
    required List<String> ownedIds,
  }) async {
    if (!_sessionOwnsUser(userId)) {
      return false;
    }
    if (starterEmoticonIdsForUser(userId).contains(emoticonId)) {
      return false;
    }
    if (kBundleEmoticonIds.contains(emoticonId) &&
        bundleEmoticonPriceForUser(emoticonId, userId) != price) {
      return false;
    }
    final prof = await _client.from('user_profiles').select('star_fragments').eq('id', userId).single();
    final stars = (prof['star_fragments'] as num?)?.toInt() ?? 0;
    if (stars < price) {
      return false;
    }
    if (ownedIds.contains(emoticonId)) {
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
    final u = await _client
        .from('user_profiles')
        .update({'star_fragments': stars - price})
        .eq('id', userId)
        .select()
        .maybeSingle();
    if (u == null) {
      return false;
    }
    try {
      await _client.from('user_emoticons').insert({
        'user_id': userId,
        'emoticon_id': emoticonId,
        'source': 'purchase',
      });
    } catch (_) {
      await _client.from('user_profiles').update({'star_fragments': stars}).eq('id', userId);
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

  /// RPC `buy_emoticon_pack` — 성공 시 보유 목록은 호출 측에서 다시 불러옵니다.
  @override
  Future<({bool ok, String? error})> buyPack({
    required String userId,
    required String packId,
  }) async {
    if (!_sessionOwnsUser(userId)) {
      return (ok: false, error: '세션 불일치');
    }
    final res = await _client.rpc(
      'buy_emoticon_pack',
      params: {'p_user_id': userId, 'p_pack_id': packId},
    );
    if (res is Map) {
      final map = Map<String, dynamic>.from(res);
      final success = map['success'] == true;
      final err = map['error'] as String?;
      return (ok: success, error: success ? null : err);
    }
    return (ok: false, error: '알 수 없는 응답');
  }
}
