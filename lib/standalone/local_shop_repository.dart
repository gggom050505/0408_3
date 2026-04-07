import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;

import '../config/bundle_emoticon_catalog.dart';
import '../config/korea_major_card_catalog.dart';
import '../config/shop_random_prices.dart';
import '../config/starter_gifts.dart';
import '../data/card_themes.dart' show koreaTraditionalMajorThemeId;
import '../data/mat_themes.dart';
import '../data/oracle_assets.dart';
import '../data/slot_shop_assets.dart';
import '../models/attendance_lucky_models.dart';
import '../models/shop_models.dart';
import '../models/surprise_gift_models.dart';
import 'data_sources.dart';
import 'attendance_lucky_sync.dart';
import 'local_json_store.dart';
import 'surprise_gift_sync.dart';
import 'shop_catalog_workspace.dart';

/// 오프라인·베타 번들 상점·가방.
/// - 상품 목록: [local_shop_catalog_v1.json] (기기) · 저장 시 JSON 미러 [assets/local_dev_state/]
/// - 별조각·장착(덱/매트/카드 뒷면/슬롯)·보유 목록: `local_shop_user_state_v1_<user>.json` (변경 시 자동 저장)
class LocalShopRepository implements ShopDataSource {
  LocalShopRepository(this._userId) {
    _profile = UserProfileRow(
      id: _userId,
      starFragments: kInitialStarFragments,
      equippedCard: 'default',
      equippedMat: 'default-mint',
      equippedCardBack: 'default-card-back',
      equippedSlot: kDefaultEquippedSlotId,
    );
    _owned
      ..add(UserItemRow(itemId: 'default', itemType: 'card', purchasedAt: _now))
      ..add(UserItemRow(itemId: 'default-mint', itemType: 'mat', purchasedAt: _now))
      ..add(UserItemRow(itemId: 'default-card-back', itemType: 'card_back', purchasedAt: _now))
      ..add(UserItemRow(itemId: kDefaultEquippedSlotId, itemType: 'slot', purchasedAt: _now));
  }

  static const _catalogFile = 'local_shop_catalog_v1.json';
  /// 예전 단일 파일(같은 기기·같은 계정이면 한 번만 이관).
  static const _legacyUserStateFile = 'local_shop_user_state_v1.json';

  final String _userId;

  String _safeUserId(String id) => id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  String _userStateFile() => 'local_shop_user_state_v1_${_safeUserId(_userId)}.json';
  final _now = DateTime.now().toUtc().toIso8601String();

  late UserProfileRow _profile;
  final _owned = <UserItemRow>[];
  /// 상점 구매분·유저별 서비스 선물 이모. [starterEmoticonIdsForUser] 는 항상 포함.
  final Set<String> _emoticonOwned = {};

  List<ShopItemRow> _catalogItems = [];
  var _catalogReady = false;
  var _userStateReady = false;

  var _surpriseGiftState = SurpriseGiftState();
  var _attendanceLuckyState = AttendanceLuckyState();

  /// ⭐1 상품: UTC 날짜 — 같은 날 1건만.
  String? _starOnePurchaseUtcYmd;

  /// ⭐2 상품: 오늘(UTC) 누적 건수 — 날마다 상한 2~3 (gggomDailyStarTwoPurchaseCapForUtcDay).
  String? _starTwoPurchaseUtcYmd;
  var _starTwoPurchaseCount = 0;

  /// `assets/card_back/` 번들 이미지 — 상점에 각각 별도 행. (별조각 5~10)
  static List<ShopItemRow> _bundledCardBackShopRows() => [
        ShopItemRow(
          id: 'card-back-cat',
          name: '카드 뒷면 (고양이)',
          type: 'card_back',
          price: 5,
          thumbnailUrl: 'assets/card_back/back_cat.png',
          isActive: true,
        ),
        ShopItemRow(
          id: 'card-back-dog',
          name: '카드 뒷면 (강아지)',
          type: 'card_back',
          price: 6,
          thumbnailUrl: 'assets/card_back/back_dog.png',
          isActive: true,
        ),
        ShopItemRow(
          id: 'card-back-moon',
          name: '카드 뒷면 (달)',
          type: 'card_back',
          price: 7,
          thumbnailUrl: 'assets/card_back/back_moon.png',
          isActive: true,
        ),
        ShopItemRow(
          id: 'card-back-tiger',
          name: '카드 뒷면 (호랑이)',
          type: 'card_back',
          price: 8,
          thumbnailUrl: 'assets/card_back/back_tiger.png',
          isActive: true,
        ),
        ShopItemRow(
          id: 'card-back-wonyeos',
          name: '카드 뒷면 (워녀스)',
          type: 'card_back',
          price: 9,
          thumbnailUrl: 'assets/card_back/back_wonyeos.png',
          isActive: true,
        ),
        ShopItemRow(
          id: 'card-back-owl',
          name: '카드 뒷면 (부엉이)',
          type: 'card_back',
          price: 10,
          thumbnailUrl: 'assets/card_back/back_owl.png',
          isActive: true,
        ),
      ];

  /// 오라클 80종 — PNG는 `assets/oracle/`, 상점 썸네일은 `oracle_cards/oracle(n).png` 논리 경로.
  static List<ShopItemRow> _bundledOracleShopRows() =>
      bundledOracleShopCatalogRows();

  List<ShopItemRow> _defaultCatalog() {
    final mats = <ShopItemRow>[];
    for (var i = 0; i < matThemes.length; i++) {
      final m = matThemes[i];
      mats.add(
        ShopItemRow(
          id: m.id,
          name: m.name,
          type: 'mat',
          price: m.id == MatThemeData.defaultId ? 0 : 4 + ((i - 1) % 6),
          thumbnailUrl: null,
          isActive: true,
        ),
      );
    }
    return [
      ShopItemRow(
        id: 'default',
        name: '기본 카드 덱',
        type: 'card',
        price: 0,
        thumbnailUrl: null,
        isActive: true,
      ),
      ...koreaMajorCardShopCatalogRows(),
      ShopItemRow(
        id: 'default-card-back',
        name: '기본 카드 뒷면',
        type: 'card_back',
        price: 0,
        thumbnailUrl: 'card_backs/owl_card_back.png',
        isActive: true,
      ),
      ..._bundledCardBackShopRows(),
      ...mats,
      ...bundledSlotShopRows(),
      ..._bundledOracleShopRows(),
    ];
  }

  Future<void> _ensureCatalogLoaded() async {
    if (_catalogReady) {
      return;
    }
    try {
      final raw = await loadLocalJsonFile(_catalogFile);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw);
        if (data is List) {
          _catalogItems = data
              .map((e) => ShopItemRow.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          _afterCatalogItemsLoaded();
          return;
        }
      }
      final ws = await tryReadShopCatalogFromWorkspace();
      if (ws != null && ws.isNotEmpty) {
        final data = jsonDecode(ws);
        if (data is List) {
          _catalogItems = data
              .map((e) => ShopItemRow.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          _afterCatalogItemsLoaded();
          return;
        }
      }
    } catch (_) {}
    _catalogItems = List<ShopItemRow>.from(_defaultCatalog());
    _afterCatalogItemsLoaded();
  }

  void _afterCatalogItemsLoaded() {
    _ensureDefaultCatalogRowsPresent();
    _syncKoreaMajorPieceCatalog();
    _removeRetiredKoreanClayFromCatalog();
    _mergeBundledCardBackShopItemsIfMissing();
    _mergeBundledSlotShopItemsIfMissing();
    _mergeOracleShopItemsIfMissing();
    _syncBundledOracleShopRowsFromCode();
    _normalizeCatalogStarPrices();
    _syncMatShopNamesFromThemes();
    _catalogReady = true;
  }

  /// 디스크 카탈로그가 `[]` 이거나 예전 부분 저장일 때 — [default] 덱·매트·오라클 80종 등 빠진 id만 [_defaultCatalog]로 채움.
  void _ensureDefaultCatalogRowsPresent() {
    var changed = false;
    for (final row in _defaultCatalog()) {
      if (_catalogItems.any((e) => e.id == row.id)) {
        continue;
      }
      _catalogItems.add(row);
      changed = true;
    }
    if (changed) {
      unawaited(_persistCatalog());
    }
  }

  /// 디스크에 남은 옛 매트 이름을 [matThemes] 소품 컨셉명으로 맞춤.
  void _syncMatShopNamesFromThemes() {
    var changed = false;
    for (var i = 0; i < _catalogItems.length; i++) {
      final e = _catalogItems[i];
      if (e.type != 'mat') {
        continue;
      }
      MatThemeData? theme;
      for (final m in matThemes) {
        if (m.id == e.id) {
          theme = m;
          break;
        }
      }
      if (theme == null || theme.name == e.name) {
        continue;
      }
      _catalogItems[i] = ShopItemRow(
        id: e.id,
        name: theme.name,
        type: e.type,
        price: e.price,
        thumbnailUrl: e.thumbnailUrl,
        isActive: e.isActive,
      );
      changed = true;
    }
    if (changed) {
      unawaited(_persistCatalog());
    }
  }

  /// 저장된 카탈로그·예전 고가 정책을 **별 1~10** (기본 품목 0)으로 맞춥니다.
  void _normalizeCatalogStarPrices() {
    var changed = false;
    for (var i = 0; i < _catalogItems.length; i++) {
      final e = _catalogItems[i];
      final next = suggestedStarPriceForShopItem(e);
      if (next != e.price) {
        _catalogItems[i] = ShopItemRow(
          id: e.id,
          name: e.name,
          type: e.type,
          price: next,
          thumbnailUrl: e.thumbnailUrl,
          isActive: e.isActive,
        );
        changed = true;
      }
    }
    if (changed) {
      unawaited(_persistCatalog());
    }
  }

  static const _retiredKoreanClayDeckId = 'korean-clay';

  /// 예전 단일 덱 행 제거 후 `korea-major-NN` 22행을 채웁니다.
  void _syncKoreaMajorPieceCatalog() {
    var changed = false;
    final before = _catalogItems.length;
    _catalogItems.removeWhere(
      (e) => e.id == koreaTraditionalMajorThemeId && e.type == 'card',
    );
    if (_catalogItems.length != before) {
      changed = true;
    }
    for (final row in koreaMajorCardShopCatalogRows()) {
      if (_catalogItems.any((e) => e.id == row.id)) {
        continue;
      }
      _catalogItems.add(row);
      changed = true;
    }
    if (changed) {
      unawaited(_persistCatalog());
    }
  }

  /// 제거된 `korean-clay` 덱을 디스크 카탈로그에서 빼고 저장합니다.
  void _removeRetiredKoreanClayFromCatalog() {
    final before = _catalogItems.length;
    _catalogItems.removeWhere((e) => e.id == _retiredKoreanClayDeckId);
    if (_catalogItems.length != before) {
      unawaited(_persistCatalog());
    }
  }

  /// 예전에 저장된 JSON 카탈로그에도 `assets/card_back/` 뒷면 5종을 한 번씩 넣습니다.
  void _mergeBundledCardBackShopItemsIfMissing() {
    var added = false;
    for (final row in _bundledCardBackShopRows()) {
      if (_catalogItems.any((e) => e.id == row.id)) {
        continue;
      }
      _catalogItems.add(row);
      added = true;
    }
    if (added) {
      unawaited(_persistCatalog());
    }
  }

  void _mergeBundledSlotShopItemsIfMissing() {
    var added = false;
    for (final row in bundledSlotShopRows()) {
      if (_catalogItems.any((e) => e.id == row.id)) {
        continue;
      }
      _catalogItems.add(row);
      added = true;
    }
    if (added) {
      unawaited(_persistCatalog());
    }
  }

  void _mergeOracleShopItemsIfMissing() {
    final bundled = _bundledOracleShopRows();
    final byId = {for (final r in bundled) r.id: r};
    var changed = false;
    for (var i = 0; i < _catalogItems.length; i++) {
      final e = _catalogItems[i];
      final b = byId[e.id];
      if (b == null) {
        continue;
      }
      if (e.type != 'oracle_card') {
        _catalogItems[i] = b;
        changed = true;
      }
    }
    for (final row in bundled) {
      if (_catalogItems.any((e) => e.id == row.id)) {
        continue;
      }
      _catalogItems.add(row);
      changed = true;
    }
    if (changed) {
      unawaited(_persistCatalog());
    }
  }

  /// 디스크에 남은 카탈로그에도 번들 오라클의 **이름·썸네일 경로**를 코드와 맞춤(가격·활성은 유지).
  void _syncBundledOracleShopRowsFromCode() {
    final byId = {for (final r in _bundledOracleShopRows()) r.id: r};
    var changed = false;
    for (var i = 0; i < _catalogItems.length; i++) {
      final e = _catalogItems[i];
      if (e.type != 'oracle_card') {
        continue;
      }
      final b = byId[e.id];
      if (b == null) {
        continue;
      }
      if (e.name == b.name && e.thumbnailUrl == b.thumbnailUrl) {
        continue;
      }
      _catalogItems[i] = ShopItemRow(
        id: e.id,
        name: b.name,
        type: e.type,
        price: e.price,
        thumbnailUrl: b.thumbnailUrl,
        isActive: e.isActive,
      );
      changed = true;
    }
    if (changed) {
      unawaited(_persistCatalog());
    }
  }

  /// 로컬 저장 프로필·보유에서 폐기 덱을 제거하고 장착을 기본으로 돌립니다.
  void _migrateRetiredKoreanClayUserState() {
    var dirty = false;
    if (_owned.any((e) => e.itemId == _retiredKoreanClayDeckId && e.itemType == 'card')) {
      _owned.removeWhere((e) => e.itemId == _retiredKoreanClayDeckId && e.itemType == 'card');
      dirty = true;
    }
    if (_profile.equippedCard == _retiredKoreanClayDeckId) {
      _profile = UserProfileRow(
        id: _profile.id,
        starFragments: _profile.starFragments,
        equippedCard: 'default',
        equippedMat: _profile.equippedMat,
        equippedCardBack: _profile.equippedCardBack,
        equippedSlot: _profile.equippedSlot,
      );
      dirty = true;
    }
    if (dirty) {
      unawaited(_persistUserState());
    }
  }

  Future<void> _persistCatalog() async {
    final jsonStr = jsonEncode(_catalogItems.map((e) => e.toJson()).toList());
    await saveLocalJsonFile(_catalogFile, jsonStr);
  }

  Future<void> _ensureUserStateLoaded() async {
    if (_userStateReady) {
      return;
    }
    try {
      var raw = await loadLocalJsonFile(_userStateFile());
      if (raw == null || raw.isEmpty) {
        final leg = await loadLocalJsonFile(_legacyUserStateFile);
        if (leg != null && leg.isNotEmpty) {
          try {
            final dec = jsonDecode(leg);
            if (dec is Map<String, dynamic>) {
              final profileMap = dec['profile'];
              final legId = profileMap is Map ? profileMap['id'] as String? : null;
              if (legId == null || legId == _userId) {
                raw = leg;
                await saveLocalJsonFile(_userStateFile(), leg);
              }
            }
          } catch (_) {}
        }
      }
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final profileMap = decoded['profile'];
          if (profileMap is Map) {
            final p = Map<String, dynamic>.from(profileMap);
            _profile = UserProfileRow(
              id: _userId,
              starFragments: (p['star_fragments'] as num?)?.toInt() ?? _profile.starFragments,
              equippedCard: p['equipped_card'] as String? ?? _profile.equippedCard,
              equippedMat: p['equipped_mat'] as String? ?? _profile.equippedMat,
              equippedCardBack: p['equipped_card_back'] as String? ?? _profile.equippedCardBack,
              equippedSlot: p['equipped_slot'] as String? ?? _profile.equippedSlot,
            );
          }
          if (decoded.containsKey('owned')) {
            final o = decoded['owned'];
            if (o is List) {
              final next = <UserItemRow>[];
              for (final e in o) {
                if (e is Map) {
                  try {
                    next.add(UserItemRow.fromJson(Map<String, dynamic>.from(e)));
                  } catch (_) {}
                }
              }
              if (next.isNotEmpty) {
                final deduped = gggomDedupeOwnedItems(next);
                _owned
                  ..clear()
                  ..addAll(deduped);
              }
            }
          }
          _emoticonOwned.clear();
          final emoRaw = decoded['emoticons'];
          if (emoRaw is List) {
            for (final e in emoRaw) {
              if (e is String && e.isNotEmpty) {
                _emoticonOwned.add(e);
              }
            }
          }
          final sg = decoded['surprise_gift'];
          if (sg is Map) {
            _surpriseGiftState = SurpriseGiftState.fromJson(
              Map<String, dynamic>.from(sg),
            );
          }
          final al = decoded['attendance_lucky'];
          if (al is Map) {
            _attendanceLuckyState = AttendanceLuckyState.fromJson(
              Map<String, dynamic>.from(al),
            );
          }
          final s1 = decoded['star_one_purchase_utc_ymd'];
          if (s1 is String && s1.isNotEmpty) {
            _starOnePurchaseUtcYmd = s1.trim();
          }
          final today = gggomTodayUtcYmdKey();
          final s2y = decoded['star_two_purchase_utc_ymd'];
          final s2c = (decoded['star_two_purchase_count'] as num?)?.toInt() ?? 0;
          if (s2y is String && s2y.trim().isNotEmpty && s2y.trim() == today) {
            _starTwoPurchaseUtcYmd = s2y.trim();
            _starTwoPurchaseCount = s2c;
          } else {
            _starTwoPurchaseUtcYmd = null;
            _starTwoPurchaseCount = 0;
          }
        }
      }
    } catch (_) {}
    _migrateRetiredKoreanClayUserState();
    _migrateKoreaTraditionalFullDeckToPieces();
    _migrateKoreaEquippedIfNoPieces();
    _ensureDefaultSlotOwned();
    _ensureStarterGifts();
    _userStateReady = true;
  }

  /// 예전 저장본에 슬롯 보유가 없으면 기본 무료 슬롯만 지급합니다.
  void _ensureDefaultSlotOwned() {
    final has = _owned.any((e) => e.itemType == 'slot' && e.itemId == kDefaultEquippedSlotId);
    if (has) {
      return;
    }
    _owned.add(UserItemRow(itemId: kDefaultEquippedSlotId, itemType: 'slot', purchasedAt: _now));
    unawaited(_persistUserState());
  }

  /// 예전 `한국전통 메이저` 덱 전체 보유 → 22장 개별 보유로 치환.
  void _migrateKoreaTraditionalFullDeckToPieces() {
    if (!_owned.any(
      (e) => e.itemType == 'card' && e.itemId == koreaTraditionalMajorThemeId,
    )) {
      return;
    }
    _owned.removeWhere(
      (e) => e.itemType == 'card' && e.itemId == koreaTraditionalMajorThemeId,
    );
    for (var i = 0; i < 22; i++) {
      final id = koreaMajorCardShopItemId(i);
      if (!_owned.any((e) => e.itemType == 'korea_major_card' && e.itemId == id)) {
        _owned.add(UserItemRow(itemId: id, itemType: 'korea_major_card', purchasedAt: _now));
      }
    }
    unawaited(_persistUserState());
  }

  void _migrateKoreaEquippedIfNoPieces() {
    if (_profile.equippedCard != koreaTraditionalMajorThemeId) {
      return;
    }
    final hasPiece =
        _owned.any((e) => e.itemType == 'korea_major_card');
    if (hasPiece) {
      return;
    }
    _profile = UserProfileRow(
      id: _profile.id,
      starFragments: _profile.starFragments,
      equippedCard: 'default',
      equippedMat: _profile.equippedMat,
      equippedCardBack: _profile.equippedCardBack,
      equippedSlot: _profile.equippedSlot,
    );
    unawaited(_persistUserState());
  }

  /// 오라클 5장·이모 5·한국전통 1장 — 유저마다 다른 무작위(시드 고정) 선물. 없으면 추가 후 저장.
  void _ensureStarterGifts() {
    var dirty = false;
    for (final id in starterOracleItemIdsForUser(_userId)) {
      if (!_owned.any((e) => e.itemType == 'oracle_card' && e.itemId == id)) {
        _owned.add(UserItemRow(itemId: id, itemType: 'oracle_card', purchasedAt: _now));
        dirty = true;
      }
    }
    final koreaGift = starterKoreaMajorItemIdForUser(_userId);
    if (!_owned.any((e) => e.itemType == 'korea_major_card' && e.itemId == koreaGift)) {
      _owned.add(UserItemRow(itemId: koreaGift, itemType: 'korea_major_card', purchasedAt: _now));
      dirty = true;
    }
    final emoCountBefore = _emoticonOwned.length;
    _emoticonOwned.addAll(starterEmoticonIdsForUser(_userId));
    if (_emoticonOwned.length != emoCountBefore) {
      dirty = true;
    }
    if (dirty) {
      unawaited(_persistUserState());
    }
  }

  Future<void> ensureUserEconomyReady() async {
    await _ensureCatalogLoaded();
    await _ensureUserStateLoaded();
  }

  Future<List<String>> getOwnedEmoticonIds() async {
    await ensureUserEconomyReady();
    final list = _emoticonOwned.toList()..sort();
    return list;
  }

  /// 번들 이모티콘 단품 구매. 별조각 차감·[user_state] emoticons 반영.
  Future<bool> purchaseEmoticon({
    required String emoticonId,
    required int price,
  }) async {
    await ensureUserEconomyReady();
    if (!kBundleEmoticonIds.contains(emoticonId)) {
      return false;
    }
    if (starterEmoticonIdsForUser(_userId).contains(emoticonId)) {
      return false;
    }
    if (_emoticonOwned.contains(emoticonId)) {
      return false;
    }
    if (_profile.starFragments < price) {
      return false;
    }
    final expectedPrice = bundleEmoticonPriceForUser(emoticonId, _userId);
    if (expectedPrice != price) {
      return false;
    }
    if (price == 1 &&
        !(gggomCanPurchaseStarOnePricedItemToday(_starOnePurchaseUtcYmd))) {
      return false;
    }
    if (price == 2 &&
        !gggomCanPurchaseStarTwoPricedItemToday(
          storedYmd: _starTwoPurchaseUtcYmd,
          storedCount: _starTwoPurchaseCount,
        )) {
      return false;
    }
    _profile = UserProfileRow(
      id: _profile.id,
      starFragments: _profile.starFragments - price,
      equippedCard: _profile.equippedCard,
      equippedMat: _profile.equippedMat,
      equippedCardBack: _profile.equippedCardBack,
      equippedSlot: _profile.equippedSlot,
    );
    _emoticonOwned.add(emoticonId);
    if (price == 1) {
      _starOnePurchaseUtcYmd = gggomTodayUtcYmdKey();
    }
    if (price == 2) {
      final next = gggomNextStarTwoPurchaseState(
        storedYmd: _starTwoPurchaseUtcYmd,
        storedCount: _starTwoPurchaseCount,
      );
      _starTwoPurchaseUtcYmd = next.ymd;
      _starTwoPurchaseCount = next.count;
    }
    await _persistUserState();
    return true;
  }

  Future<void> _persistUserState() async {
    final emoList = _emoticonOwned.toList()..sort();
    final payload = <String, dynamic>{
      'version': 1,
      'profile': {
        'id': _profile.id,
        'star_fragments': _profile.starFragments,
        'equipped_card': _profile.equippedCard,
        'equipped_mat': _profile.equippedMat,
        'equipped_card_back': _profile.equippedCardBack,
        'equipped_slot': _profile.equippedSlot,
      },
      'owned': _owned.map((e) => e.toJson()).toList(),
      'emoticons': emoList,
      'surprise_gift': _surpriseGiftState.toJson(),
      'attendance_lucky': _attendanceLuckyState.toJson(),
      if (_starOnePurchaseUtcYmd != null && _starOnePurchaseUtcYmd!.isNotEmpty)
        'star_one_purchase_utc_ymd': _starOnePurchaseUtcYmd,
      if (_starTwoPurchaseUtcYmd != null && _starTwoPurchaseUtcYmd!.isNotEmpty) ...{
        'star_two_purchase_utc_ymd': _starTwoPurchaseUtcYmd,
        'star_two_purchase_count': _starTwoPurchaseCount,
      },
    };
    await saveLocalJsonFile(_userStateFile(), jsonEncode(payload));
  }

  /// 관리자 화면: 전체 상품(비활성 포함)
  Future<List<ShopItemRow>> loadFullCatalogForAdmin() async {
    await _ensureCatalogLoaded();
    return List<ShopItemRow>.from(_catalogItems);
  }

  /// 관리자 화면에서 저장 ([saveLocalJsonFile] 가 프로젝트 미러까지 처리).
  Future<void> saveCatalogForAdmin(List<ShopItemRow> items) async {
    _catalogItems = List<ShopItemRow>.from(items);
    _catalogReady = true;
    await _persistCatalog();
  }

  /// 전체 JSON 미러·내보내기 직전: 메모리의 프로필·보유품 상태를 디스크에 다시 씁니다.
  Future<void> persistUserStateToDisk() async {
    await _ensureUserStateLoaded();
    await _persistUserState();
  }

  /// 내장 기본 목록으로 되돌리고 파일 삭제에 가깝게 덮어씀
  Future<void> resetCatalogToDefaults() async {
    _catalogItems = List<ShopItemRow>.from(_defaultCatalog());
    _catalogReady = true;
    await _persistCatalog();
  }

  @override
  Future<List<ShopItemRow>> fetchShopItems() async {
    await _ensureCatalogLoaded();
    await _ensureUserStateLoaded();
    return _catalogItems.where((e) => e.isActive).toList();
  }

  @override
  Future<UserProfileRow?> fetchProfile(String userId) async {
    if (userId != _userId) {
      return null;
    }
    await _ensureCatalogLoaded();
    await _ensureUserStateLoaded();
    return _profile;
  }

  @override
  Future<List<UserItemRow>> fetchOwnedItems(String userId) async {
    if (userId != _userId) {
      return [];
    }
    await _ensureCatalogLoaded();
    await _ensureUserStateLoaded();
    return gggomDedupeOwnedItems(_owned);
  }

  @override
  Future<void> ensureDefaultUserItems(String userId) async {
    if (userId != _userId) {
      return;
    }
    await ensureUserEconomyReady();
    _ensureStarterGifts();
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
    if (userId != _userId) {
      return false;
    }
    await _ensureCatalogLoaded();
    await _ensureUserStateLoaded();
    final exists = _catalogItems.any((e) => e.id == itemId && e.isActive);
    if (!exists) {
      return false;
    }
    if (_profile.starFragments < price) {
      return false;
    }
    if (owned.any((i) => i.itemId == itemId && i.itemType == type)) {
      return false;
    }
    if (price == 1 &&
        !(gggomCanPurchaseStarOnePricedItemToday(_starOnePurchaseUtcYmd))) {
      return false;
    }
    if (price == 2 &&
        !gggomCanPurchaseStarTwoPricedItemToday(
          storedYmd: _starTwoPurchaseUtcYmd,
          storedCount: _starTwoPurchaseCount,
        )) {
      return false;
    }
    _profile = UserProfileRow(
      id: _profile.id,
      starFragments: _profile.starFragments - price,
      equippedCard: _profile.equippedCard,
      equippedMat: _profile.equippedMat,
      equippedCardBack: _profile.equippedCardBack,
      equippedSlot: _profile.equippedSlot,
    );
    _owned.add(UserItemRow(itemId: itemId, itemType: type, purchasedAt: _now));
    if (price == 1) {
      _starOnePurchaseUtcYmd = gggomTodayUtcYmdKey();
    }
    if (price == 2) {
      final next = gggomNextStarTwoPurchaseState(
        storedYmd: _starTwoPurchaseUtcYmd,
        storedCount: _starTwoPurchaseCount,
      );
      _starTwoPurchaseUtcYmd = next.ymd;
      _starTwoPurchaseCount = next.count;
    }
    await _persistUserState();
    return true;
  }

  @override
  Future<UserProfileRow?> equipItem({
    required String userId,
    required String itemId,
    required String type,
  }) async {
    if (userId != _userId) {
      return null;
    }
    await _ensureCatalogLoaded();
    await _ensureUserStateLoaded();
    final inCatalog = _catalogItems.any((e) => e.id == itemId);
    if (!inCatalog) {
      return null;
    }
    if (type == 'oracle_card' || type == 'korea_major_card') {
      return _profile;
    }
    if (type == 'card') {
      _profile = UserProfileRow(
        id: _profile.id,
        starFragments: _profile.starFragments,
        equippedCard: itemId,
        equippedMat: _profile.equippedMat,
        equippedCardBack: _profile.equippedCardBack,
        equippedSlot: _profile.equippedSlot,
      );
    } else if (type == 'card_back') {
      _profile = UserProfileRow(
        id: _profile.id,
        starFragments: _profile.starFragments,
        equippedCard: _profile.equippedCard,
        equippedMat: _profile.equippedMat,
        equippedCardBack: itemId,
        equippedSlot: _profile.equippedSlot,
      );
    } else if (type == 'slot') {
      _profile = UserProfileRow(
        id: _profile.id,
        starFragments: _profile.starFragments,
        equippedCard: _profile.equippedCard,
        equippedMat: _profile.equippedMat,
        equippedCardBack: _profile.equippedCardBack,
        equippedSlot: itemId,
      );
    } else {
      _profile = UserProfileRow(
        id: _profile.id,
        starFragments: _profile.starFragments,
        equippedCard: _profile.equippedCard,
        equippedMat: itemId,
        equippedCardBack: _profile.equippedCardBack,
        equippedSlot: _profile.equippedSlot,
      );
    }
    await _persistUserState();
    return _profile;
  }

  @override
  Future<AttendanceDailyRewardResult?> grantAttendanceDailyReward(String userId) async {
    if (userId != _userId) {
      return null;
    }
    await _ensureCatalogLoaded();
    await _ensureUserStateLoaded();

    _profile = UserProfileRow(
      id: _profile.id,
      starFragments: _profile.starFragments + 1,
      equippedCard: _profile.equippedCard,
      equippedMat: _profile.equippedMat,
      equippedCardBack: _profile.equippedCardBack,
      equippedSlot: _profile.equippedSlot,
    );

    final catalog = _catalogItems.where((e) => e.isActive).toList();
    final blockSurprise = <String>{};
    final spId = _surpriseGiftState.pendingItemId;
    final spType = _surpriseGiftState.pendingItemType;
    if (spId != null && spType != null) {
      blockSurprise.add(gggomShopOwnedKey(spId, spType));
    }
    final lucky = AttendanceLuckySync.evaluate(
      state: _attendanceLuckyState,
      catalog: catalog,
      owned: _owned,
      rng: Random(),
      nowUtc: DateTime.now().toUtc(),
      doNotGrantKeys: blockSurprise.isEmpty ? null : blockSurprise,
    );

    String? luckyName;
    var luckyGranted = false;
    final row = lucky.grantedItem;
    if (row != null) {
      if (!_owned.any((e) => e.itemId == row.id && e.itemType == row.type)) {
        _owned.add(UserItemRow(itemId: row.id, itemType: row.type, purchasedAt: _now));
        luckyName = row.name;
        luckyGranted = true;
      }
    }
    final applyNext = lucky.applyNextEligibleAfterUtc;
    if (applyNext != null) {
      _attendanceLuckyState.nextEligibleAfterUtc = applyNext;
    }

    await _persistUserState();
    return AttendanceDailyRewardResult(
      starFragmentsAdded: 1,
      luckyShopItemName: luckyName,
      luckyShopItemGranted: luckyGranted,
    );
  }

  @override
  Future<UserProfileRow?> grantAdRewardStars(String userId, {int amount = 3}) async {
    if (userId != _userId) {
      return null;
    }
    await _ensureCatalogLoaded();
    await _ensureUserStateLoaded();
    final next = _profile.starFragments + amount;
    _profile = UserProfileRow(
      id: _profile.id,
      starFragments: next,
      equippedCard: _profile.equippedCard,
      equippedMat: _profile.equippedMat,
      equippedCardBack: _profile.equippedCardBack,
      equippedSlot: _profile.equippedSlot,
    );
    await _persistUserState();
    return _profile;
  }

  @override
  Future<SurpriseGiftOffer?> syncSurpriseGift(
    String userId,
    List<ShopItemRow> activeCatalog,
  ) async {
    if (userId != _userId) {
      return null;
    }
    await ensureUserEconomyReady();
    final r = SurpriseGiftSync.run(
      state: _surpriseGiftState,
      catalog: activeCatalog,
      owned: _owned,
      rng: Random(),
      nowUtc: DateTime.now().toUtc(),
    );
    if (r.stateChanged) {
      await _persistUserState();
    }
    return r.offer;
  }

  @override
  Future<ClaimSurpriseGiftResult> claimSurpriseGift(
    String userId,
    SurpriseGiftOffer offer,
  ) async {
    if (userId != _userId) {
      return ClaimSurpriseGiftResult.failed;
    }
    await ensureUserEconomyReady();
    if (_surpriseGiftState.pendingItemId != offer.itemId ||
        _surpriseGiftState.pendingItemType != offer.itemType) {
      return ClaimSurpriseGiftResult.failed;
    }
    final ownedKeys = _owned.map((e) => gggomShopOwnedKey(e.itemId, e.itemType)).toSet();
    if (ownedKeys.contains(gggomShopOwnedKey(offer.itemId, offer.itemType))) {
      SurpriseGiftSync.clearPendingAndScheduleNext(
        state: _surpriseGiftState,
        nowUtc: DateTime.now().toUtc(),
        rng: Random(),
      );
      await _persistUserState();
      return ClaimSurpriseGiftResult.alreadyOwned;
    }
    if (!_catalogItems.any(
      (e) => e.id == offer.itemId && e.type == offer.itemType && e.isActive,
    )) {
      return ClaimSurpriseGiftResult.failed;
    }
    _owned.add(
      UserItemRow(
        itemId: offer.itemId,
        itemType: offer.itemType,
        purchasedAt: _now,
      ),
    );
    SurpriseGiftSync.clearPendingAndScheduleNext(
      state: _surpriseGiftState,
      nowUtc: DateTime.now().toUtc(),
      rng: Random(),
    );
    await _persistUserState();
    return ClaimSurpriseGiftResult.granted;
  }
}

/// 로컬 상점 행의 별조각 가격: 기본·데일리 품목은 0, 나머지 1~10.
int suggestedStarPriceForShopItem(ShopItemRow e) {
  switch (e.type) {
    case 'card':
      if (e.id == 'default') {
        return 0;
      }
      return e.price.clamp(1, 10).toInt();
    case 'korea_major_card':
      final idx = koreaMajorCardIndexFromShopItemId(e.id);
      if (idx != null) {
        return koreaMajorPieceShopStarPrice(idx);
      }
      return e.price.clamp(1, 10).toInt();
    case 'card_back':
      if (e.id == 'default-card-back') {
        return 0;
      }
      const map = <String, int>{
        'card-back-cat': 5,
        'card-back-dog': 6,
        'card-back-moon': 7,
        'card-back-tiger': 8,
        'card-back-wonyeos': 9,
        'card-back-owl': 10,
      };
      return map[e.id] ?? e.price.clamp(1, 10).toInt();
    case 'mat':
      if (e.id == MatThemeData.defaultId) {
        return 0;
      }
      final idx = matThemes.indexWhere((m) => m.id == e.id);
      if (idx <= 0) {
        return e.price.clamp(4, 9).toInt();
      }
      return 4 + ((idx - 1) % 6);
    case 'oracle_card':
      final n = oracleItemIdToCardNumber(e.id);
      if (n != null) {
        return oracleCardShopStarPrice(n);
      }
      return e.price.clamp(1, 10).toInt();
    case 'slot':
      if (e.id == kDefaultEquippedSlotId) {
        return 0;
      }
      return e.price.clamp(1, 10).toInt();
    default:
      if (e.price <= 0) {
        return 0;
      }
      return e.price.clamp(1, 10).toInt();
  }
}
