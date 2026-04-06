import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../config/bundle_emoticon_catalog.dart';
import '../config/gggom_site_public_catalog.dart';
import '../config/starter_gifts.dart' show starterEmoticonIdsForUser;
import '../models/emoticon_models.dart';
import 'data_sources.dart';
import 'local_shop_repository.dart';

/// 오프라인·베타 번들 이모티콘.
///
/// 채팅 피커는 [kBundleEmoticonRows](`assets/emoticon/emoticon(1~61).png`)만 사용합니다.
/// 보유: 서비스 선물 5개 + [LocalShopRepository] 에 저장된 구매분 (+ 선택적 원격).
class LocalEmoticonRepository implements EmoticonDataSource {
  static const _extraCatalogUrl =
      String.fromEnvironment('EMOTICON_CATALOG_URL', defaultValue: '');
  static const _extraCatalogAnon =
      String.fromEnvironment('EMOTICON_CATALOG_ANON_KEY', defaultValue: '');

  LocalEmoticonRepository({LocalShopRepository? wallet}) : _wallet = wallet;

  final LocalShopRepository? _wallet;

  List<EmoticonRow>? _catalogCache;

  String _apiBase() {
    final u = _extraCatalogUrl.trim();
    if (u.isNotEmpty) {
      return u.replaceAll(RegExp(r'/$'), '');
    }
    final main = AppConfig.supabaseUrl.trim();
    if (main.isNotEmpty) {
      return main.replaceAll(RegExp(r'/$'), '');
    }
    return GggomSitePublicCatalog.supabaseRestBase.replaceAll(RegExp(r'/$'), '');
  }

  String _anonKey() {
    final k = _extraCatalogAnon.trim();
    if (k.isNotEmpty) {
      return k;
    }
    final main = AppConfig.supabaseAnonKey.trim();
    if (main.isNotEmpty) {
      return main;
    }
    return GggomSitePublicCatalog.anonKey;
  }

  Future<List<String>?> _tryFetchRemoteOwned(String userId) async {
    final base = _apiBase();
    final key = _anonKey();
    if (base.isEmpty || key.isEmpty) {
      return null;
    }
    final uid = Uri.encodeComponent(userId);
    final uri = Uri.parse(
      '$base/rest/v1/user_emoticons?user_id=eq.$uid&select=emoticon_id',
    );
    try {
      final res = await http
          .get(
            uri,
            headers: {
              'apikey': key,
              'Authorization': 'Bearer $key',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        return null;
      }
      final data = jsonDecode(res.body);
      if (data is! List) {
        return null;
      }
      return data
          .map((e) => (e as Map)['emoticon_id'] as String?)
          .whereType<String>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<EmoticonPackRow>> fetchPacks() async => [];

  @override
  Future<List<EmoticonRow>> fetchAllEmoticons() async {
    _catalogCache ??= List<EmoticonRow>.from(kBundleEmoticonRows);
    return List<EmoticonRow>.from(_catalogCache!);
  }

  @override
  Future<List<String>> fetchOwned(String userId) async {
    final out = <String>{...starterEmoticonIdsForUser(userId)};
    final wallet = _wallet;
    if (wallet != null) {
      await wallet.ensureUserEconomyReady();
      out.addAll(await wallet.getOwnedEmoticonIds());
    }
    if (_apiBase().isNotEmpty && _anonKey().isNotEmpty) {
      final remote = await _tryFetchRemoteOwned(userId);
      if (remote != null) {
        out.addAll(remote);
      }
    }
    return out.toList()..sort();
  }

  @override
  Future<bool> buyEmoticon({
    required String userId,
    required String emoticonId,
    required int price,
    required List<String> ownedIds,
  }) async {
    final wallet = _wallet;
    if (wallet == null) {
      return false;
    }
    await wallet.ensureUserEconomyReady();
    return wallet.purchaseEmoticon(emoticonId: emoticonId, price: price);
  }

  @override
  Future<({bool ok, String? error})> buyPack({
    required String userId,
    required String packId,
  }) async =>
      (ok: false, error: '오프라인·베타 번들에서는 이모티콘 팩 구매가 제공되지 않아요.');
}
