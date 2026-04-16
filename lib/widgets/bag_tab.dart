import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/bundle_emoticon_catalog.dart';
import '../config/emoticon_offline.dart';
import '../config/korea_major_card_catalog.dart';
import '../config/unique_shop_items.dart';
import '../data/card_themes.dart'
    show
        defaultThemeId,
        kKoreaTraditionalMajorShopThumbnailAsset,
        koreaTraditionalMajorAssetPath,
        koreaTraditionalMajorThemeId,
        majorClayThemeId,
        mixedMinorKoreaTraditionalMajorThemeId,
        resolvePublicAssetUrl,
        resolveShopItemThumbnailSrc,
        kCardThemeThumbnailPath;
import '../data/mat_themes.dart';
import '../data/oracle_assets.dart';
import '../data/slot_shop_assets.dart';
import '../models/shop_models.dart';
import '../standalone/data_sources.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';
import 'app_motion.dart';
import 'oracle_collection_screen.dart';

/// 한국전통 메이저 **덱** 선택 시 가방에 표시하는 안내.
const String _koreaTraditionalDeckEquipHint =
    '이 덱을 선택하면 타로 화면은 「마이너카드 60장 + 메이저카드(번호 매칭)」으로 구성돼요. '
    '한국전통 메이저 보유 번호는 우선 적용되고, 없는 번호는 기본 메이저로 자동 보완됩니다.';

const String _mixedMinorKoreaDeckEquipHint =
    '마이너카드 60장은 모두 들어가고, 한국전통 메이저는 가방에서 모은 장만 섞입니다. '
    '앞면 그림: 마이너=기본 덱, 메이저=한국전통.';

String? _koreaMajorBagPreviewSrc(_OwnedVisual c) {
  if (c.thumbnailUrl != null && c.thumbnailUrl!.isNotEmpty) {
    return c.thumbnailUrl;
  }
  final idx = koreaMajorCardIndexFromShopItemId(c.id);
  final path = idx != null ? koreaTraditionalMajorAssetPath(idx) : null;
  if (path == null) {
    return null;
  }
  return resolvePublicAssetUrl(path, AppConfig.assetOrigin);
}

class _OwnedVisual {
  _OwnedVisual({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.matThemeId,
    this.owned = true,
  });

  final String id;
  final String name;
  final String? thumbnailUrl;

  /// 타로 매트 행이면 [matThemes] 그라데이션 미리보기에 사용합니다.
  final String? matThemeId;
  final bool owned;
}

class BagTab extends StatelessWidget {
  const BagTab({
    super.key,
    required this.repo,
    required this.userId,
    required this.shopItems,
    required this.profile,
    required this.ownedItems,
    this.ownedEmoticonIds = const [],
    required this.onRefresh,
    required this.onNeedLogin,
    this.onOpenPersonalShop,
  });

  final ShopDataSource repo;
  final String? userId;
  final List<ShopItemRow> shopItems;
  final UserProfileRow? profile;
  final List<UserItemRow> ownedItems;

  /// 상점·선물로 보유한 번들 이모티콘 ID (`emo_asset_XX` 등).
  final List<String> ownedEmoticonIds;
  final Future<void> Function() onRefresh;
  final VoidCallback onNeedLogin;

  /// 가방 전용 개인 상점 배너(없으면 숨김).
  final VoidCallback? onOpenPersonalShop;

  ShopItemRow? _shop(String id) {
    for (final s in shopItems) {
      if (s.id == id) {
        return s;
      }
    }
    return null;
  }

  List<_OwnedVisual> _mergeCards() {
    final p = profile;
    final db = <_OwnedVisual>[];
    for (final item in ownedItems.where((e) => e.itemType == 'card')) {
      final si = _shop(item.itemId);
      final path = kCardThemeThumbnailPath[item.itemId];
      db.add(
        _OwnedVisual(
          id: item.itemId,
          name:
              si?.name ??
              (item.itemId == defaultThemeId
                  ? '기본카드'
                  : item.itemId == koreaTraditionalMajorThemeId
                  ? '한국전통 메이저카드'
                  : item.itemId == mixedMinorKoreaTraditionalMajorThemeId
                  ? '마이너 + 한국전통 메이저 (혼합)'
                  : item.itemId == majorClayThemeId
                  ? '클레이 덱 (메이저 24 + 마이너 60)'
                  : '카드 덱'),
          thumbnailUrl: si?.thumbnailUrl != null
              ? resolveShopItemThumbnailSrc(
                  si!.thumbnailUrl,
                  AppConfig.assetOrigin,
                )
              : (path != null
                    ? resolvePublicAssetUrl(path, AppConfig.assetOrigin)
                    : null),
        ),
      );
    }
    if (!db.any((c) => c.id == defaultThemeId)) {
      final path = kCardThemeThumbnailPath[defaultThemeId];
      db.insert(
        0,
        _OwnedVisual(
          id: defaultThemeId,
          name: '기본카드',
          thumbnailUrl: path != null
              ? resolvePublicAssetUrl(path, AppConfig.assetOrigin)
              : null,
        ),
      );
    }
    final hasKoreaPieces = ownedItems.any(
      (e) => e.itemType == 'korea_major_card',
    );
    if (hasKoreaPieces &&
        !db.any((c) => c.id == koreaTraditionalMajorThemeId)) {
      final thumb = resolvePublicAssetUrl(
        kKoreaTraditionalMajorShopThumbnailAsset,
        AppConfig.assetOrigin,
      );
      db.add(
        _OwnedVisual(
          id: koreaTraditionalMajorThemeId,
          name: '한국전통 메이저카드',
          thumbnailUrl: thumb,
        ),
      );
    }
    String cardSuffix(_OwnedVisual e) {
      if (p == null || p.equippedCard != e.id) {
        return '';
      }
      return ' (장착)';
    }

    return db
        .map(
          (e) => _OwnedVisual(
            id: e.id,
            name: '${e.name}${cardSuffix(e)}',
            thumbnailUrl: e.thumbnailUrl,
          ),
        )
        .toList();
  }

  List<_OwnedVisual> _mergeKoreaMajorPieces() {
    final ownedIds = ownedItems
        .where((e) => e.itemType == 'korea_major_card')
        .map((e) => e.itemId)
        .toSet();
    final db = <_OwnedVisual>[];
    for (var i = 0; i < 22; i++) {
      final itemId = koreaMajorCardShopItemId(i);
      final si = _shop(itemId);
      final path = koreaTraditionalMajorAssetPath(i);
      db.add(
        _OwnedVisual(
          id: itemId,
          name: si?.name ?? '한국전통 · ${i + 1}번',
          thumbnailUrl: si?.thumbnailUrl != null
              ? resolveShopItemThumbnailSrc(
                  si!.thumbnailUrl,
                  AppConfig.assetOrigin,
                )
              : (path != null
                    ? resolvePublicAssetUrl(path, AppConfig.assetOrigin)
                    : null),
          owned: ownedIds.contains(itemId),
        ),
      );
    }
    db.sort((a, b) {
      final ai = koreaMajorCardIndexFromShopItemId(a.id);
      final bi = koreaMajorCardIndexFromShopItemId(b.id);
      if (ai != null && bi != null) {
        return ai.compareTo(bi);
      }
      if (ai != null) return -1;
      if (bi != null) return 1;
      return a.id.compareTo(b.id);
    });
    return db;
  }

  List<_OwnedVisual> _mergeCardBacks() {
    final p = profile;
    final db = <_OwnedVisual>[];
    for (final item in ownedItems.where((e) => e.itemType == 'card_back')) {
      final si = _shop(item.itemId);
      db.add(
        _OwnedVisual(
          id: item.itemId,
          name: si?.name ?? '카드 뒷면',
          thumbnailUrl: si?.thumbnailUrl != null
              ? resolveShopItemThumbnailSrc(
                  si!.thumbnailUrl,
                  AppConfig.assetOrigin,
                )
              : null,
        ),
      );
    }
    const freeId = 'default-card-back';
    if (!db.any((c) => c.id == freeId)) {
      final si = _shop(freeId);
      db.insert(
        0,
        _OwnedVisual(
          id: freeId,
          name: si?.name ?? '기본 카드 뒷면',
          thumbnailUrl: si?.thumbnailUrl != null
              ? resolveShopItemThumbnailSrc(
                  si!.thumbnailUrl,
                  AppConfig.assetOrigin,
                )
              : null,
        ),
      );
    }
    return db
        .map(
          (e) => _OwnedVisual(
            id: e.id,
            name: '${e.name}${p?.equippedCardBack == e.id ? ' (장착)' : ''}',
            thumbnailUrl: e.thumbnailUrl,
          ),
        )
        .toList();
  }

  List<_OwnedVisual> _mergeMats() {
    final p = profile;
    final db = <_OwnedVisual>[];
    for (final item in ownedItems.where((e) => e.itemType == 'mat')) {
      final si = _shop(item.itemId);
      db.add(
        _OwnedVisual(
          id: item.itemId,
          name: si?.name ?? matById(item.itemId).name,
          matThemeId: item.itemId,
        ),
      );
    }
    final freeId = MatThemeData.defaultId;
    if (!db.any((c) => c.id == freeId)) {
      final si = _shop(freeId);
      db.insert(
        0,
        _OwnedVisual(
          id: freeId,
          name: si?.name ?? matById(freeId).name,
          matThemeId: freeId,
        ),
      );
    }
    return db
        .map(
          (e) => _OwnedVisual(
            id: e.id,
            name: '${e.name}${p?.equippedMat == e.id ? ' (장착)' : ''}',
            matThemeId: e.matThemeId,
          ),
        )
        .toList();
  }

  List<_OwnedVisual> _mergeSlots() {
    final p = profile;
    final db = <_OwnedVisual>[];
    for (final item in ownedItems.where((e) => e.itemType == 'slot')) {
      final si = _shop(item.itemId);
      db.add(
        _OwnedVisual(
          id: item.itemId,
          name: si?.name ?? '카드 슬롯',
          thumbnailUrl: si?.thumbnailUrl != null
              ? resolveShopItemThumbnailSrc(
                  si!.thumbnailUrl,
                  AppConfig.assetOrigin,
                )
              : null,
        ),
      );
    }
    if (!db.any((c) => c.id == kDefaultEquippedSlotId)) {
      final si = _shop(kDefaultEquippedSlotId);
      db.insert(
        0,
        _OwnedVisual(
          id: kDefaultEquippedSlotId,
          name: si?.name ?? '기본 카드 슬롯',
          thumbnailUrl: si?.thumbnailUrl != null
              ? resolveShopItemThumbnailSrc(
                  si!.thumbnailUrl,
                  AppConfig.assetOrigin,
                )
              : bundledSlotAssetPathForShopId(kDefaultEquippedSlotId),
        ),
      );
    }
    return db
        .map(
          (e) => _OwnedVisual(
            id: e.id,
            name: '${e.name}${p?.equippedSlot == e.id ? ' (장착)' : ''}',
            thumbnailUrl: e.thumbnailUrl,
          ),
        )
        .toList();
  }

  List<_OwnedVisual> _mergeOracles() {
    final db = <_OwnedVisual>[];
    for (final item in ownedItems.where((e) => e.itemType == 'oracle_card')) {
      final si = _shop(item.itemId);
      db.add(
        _OwnedVisual(
          id: item.itemId,
          name: si?.name ?? item.itemId,
          thumbnailUrl: si?.thumbnailUrl != null
              ? resolveShopItemThumbnailSrc(
                  si!.thumbnailUrl,
                  AppConfig.assetOrigin,
                )
              : null,
        ),
      );
    }
    db.sort((a, b) => a.id.compareTo(b.id));
    return db;
  }

  String _emoticonDisplayName(String id) {
    for (final e in kBundleEmoticonRows) {
      if (e.id == id) {
        return e.name;
      }
    }
    return id;
  }

  bool _isUniqueOwned(String id, String type) => isUniqueShopItem(id, type);

  Future<void> _equip(
    BuildContext context,
    String id,
    String type, {
    String? successMessage,
  }) async {
    final uid = userId;
    if (uid == null) {
      onNeedLogin();
      return;
    }
    await repo.equipItem(userId: uid, itemId: id, type: type);
    await onRefresh();
    if (context.mounted) {
      final msg = successMessage ?? (type == 'card' ? '선택했어요' : '장착했어요');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Center(
        child: Text(
          '로그인 후 가방을 열 수 있어요.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final cards = _mergeCards();
    final cardBacks = _mergeCardBacks();
    final mats = _mergeMats();
    final slots = _mergeSlots();
    final oracles = _mergeOracles();
    final koreaPieces = _mergeKoreaMajorPieces();
    final emoticons = List<String>.from(ownedEmoticonIds)..sort();

    var st = 0;
    Widget stagger(Widget w) => StaggerItem(index: st++, child: w);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          stagger(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎒 가방',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '보유한 덱·뒷면·매트·슬롯을 장착하면 타로 화면에 곧바로 반영돼요.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onOpenPersonalShop != null)
            stagger(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Material(
                  color: const Color(0xFFE8F4FC),
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onOpenPersonalShop,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            color: const Color(0xFF0369A1),
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🏠 개인 상점',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '별조각 거래 · 유저 간 진열·구매',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (koreaPieces.isNotEmpty) ...[
            stagger(
              _sectionTitle(
                context,
                '🇰🇷 한국전통 메이저 · ${koreaPieces.length} / 22',
                uniqueAccent: true,
              ),
            ),
            _koreaPieceGrid(context, koreaPieces),
          ],
          stagger(_sectionTitle(context, '🃏 카드 덱')),
          _equipTypeGrid(context, cards, 'card'),
          if (cards.any((c) => c.id == koreaTraditionalMajorThemeId))
            _deckFootnote(context, _koreaTraditionalDeckEquipHint),
          if (cards.any((c) => c.id == mixedMinorKoreaTraditionalMajorThemeId))
            _deckFootnote(context, _mixedMinorKoreaDeckEquipHint),
          stagger(_sectionTitle(context, '🎴 카드 뒷면')),
          _equipTypeGrid(context, cardBacks, 'card_back'),
          stagger(_sectionTitle(context, '🧘 타로 매트')),
          _equipTypeGrid(context, mats, 'mat'),
          stagger(_sectionTitle(context, '🪟 카드 슬롯')),
          _equipTypeGrid(context, slots, 'slot'),
          stagger(
            _oracleSectionTitleRow(
              context,
              ownedCount: oracles.length,
              onOpenCollection: oracles.isEmpty
                  ? null
                  : () => _openOracleCollection(context, oracles),
            ),
          ),
          if (oracles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '출석 이벤트·상점에서 모을 수 있어요',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            _oracleThumbnailGrid(context, oracles),
          if (emoticons.isNotEmpty) ...[
            stagger(
              _sectionTitle(
                context,
                '😊 이모티콘 (보유 ${emoticons.length})',
              ),
            ),
            _ownedEmoticonGridShopStyle(context, emoticons),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String t, {
    bool uniqueAccent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        t,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: uniqueAccent ? AppColors.uniqueItemForeground : null,
            ),
      ),
    );
  }

  Widget _deckFootnote(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
      ),
    );
  }

  Widget _oracleSectionTitleRow(
    BuildContext context, {
    required int ownedCount,
    required VoidCallback? onOpenCollection,
  }) {
    final total = kBundledOracleCardCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpenCollection,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '🔮 오라클 카드',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.uniqueItemForeground,
                        ),
                  ),
                ),
                Text(
                  '$ownedCount / $total',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (onOpenCollection != null)
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openOracleCollection(
    BuildContext context,
    List<_OwnedVisual> oracles,
  ) {
    final entries = <OracleCollectionEntry>[];
    for (final v in oracles) {
      final imageSrc =
          (v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty)
          ? v.thumbnailUrl!
          : resolveOracleCollectionImageSrc(
              itemId: v.id,
              shopThumbnailUrl: _shop(v.id)?.thumbnailUrl,
            );
      entries.add(
        OracleCollectionEntry(
          id: v.id,
          name: v.name,
          imageSrc: imageSrc,
        ),
      );
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => OracleCollectionScreen(
          entries: entries,
          ownedCount: oracles.length,
          totalCount: kBundledOracleCardCount,
        ),
      ),
    );
  }

  Widget _equipTypeGrid(
    BuildContext context,
    List<_OwnedVisual> items,
    String equipType,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 200,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final v = items[i];
          return AppearAnimation(
            delay: Duration(milliseconds: 24 * i.clamp(0, 12)),
            duration: const Duration(milliseconds: 340),
            child: _equipGridCell(context, v, equipType),
          );
        },
      ),
    );
  }

  Widget _equGridThumb(
    BuildContext context,
    _OwnedVisual v,
    String equipType,
  ) {
    if (v.matThemeId != null) {
      final mat = matById(v.matThemeId!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: mat.background),
          child: const SizedBox.expand(),
        ),
      );
    }
    if (v.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AdaptiveNetworkOrAssetImage(
          src: v.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackDeck(equipType),
        ),
      );
    }
    return _fallbackDeck(equipType);
  }

  Widget _equipGridCell(
    BuildContext context,
    _OwnedVisual v,
    String equipType,
  ) {
    final p = profile;
    final isKoreaDeck =
        equipType == 'card' && v.id == koreaTraditionalMajorThemeId;
    final koreaDeckActive =
        isKoreaDeck && p?.equippedCard == koreaTraditionalMajorThemeId;
    final equipped = switch (equipType) {
      'card' => p?.equippedCard == v.id,
      'card_back' => p?.equippedCardBack == v.id,
      'mat' => p?.equippedMat == v.id,
      'slot' => p?.equippedSlot == v.id,
      _ => false,
    };
    final uniqueBorder =
        equipType != 'mat' &&
        equipType != 'card' &&
        _isUniqueOwned(v.id, equipType);

    Widget action;
    if (equipType == 'card' && koreaDeckActive) {
      action = OutlinedButton(
        onPressed: () => _equip(
          context,
          defaultThemeId,
          'card',
          successMessage: '기본 카드 덱으로 바꿨어요',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentPurple,
          side: const BorderSide(color: AppColors.accentPurple),
          minimumSize: const Size(double.infinity, 34),
          padding: EdgeInsets.zero,
        ),
        child: const Text('취소', style: TextStyle(fontSize: 11)),
      );
    } else if (equipped) {
      action = Text(
        '장착 중',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      );
    } else {
      action = FilledButton(
        onPressed: () => _equip(
          context,
          v.id,
          equipType,
          successMessage: isKoreaDeck ? '한국전통 메이저 덱을 선택했어요' : null,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentPurple,
          minimumSize: const Size(double.infinity, 34),
        ),
        child: Text(
          equipType == 'card' ? '선택' : '장착',
          style: const TextStyle(fontSize: 11),
        ),
      );
    }

    return Card(
      color: Colors.white.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: uniqueBorder
            ? const BorderSide(color: AppColors.uniqueItemBorder, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 0.75,
                child: _equGridThumb(context, v, equipType),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              v.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: uniqueBorder ? AppColors.uniqueItemForeground : null,
                  ),
            ),
            const SizedBox(height: 6),
            action,
          ],
        ),
      ),
    );
  }

  Widget _oracleThumbnailGrid(
    BuildContext context,
    List<_OwnedVisual> oracles,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 200,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: oracles.length,
        itemBuilder: (context, i) {
          final c = oracles[i];
          final imageSrc =
              (c.thumbnailUrl != null && c.thumbnailUrl!.isNotEmpty)
              ? c.thumbnailUrl!
              : resolveOracleCollectionImageSrc(
                  itemId: c.id,
                  shopThumbnailUrl: _shop(c.id)?.thumbnailUrl,
                );
          final oracleUnique = _isUniqueOwned(c.id, 'oracle_card');
          return AppearAnimation(
            delay: Duration(milliseconds: 24 * i.clamp(0, 12)),
            duration: const Duration(milliseconds: 340),
            child: Card(
              color: Colors.white.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: oracleUnique
                    ? const BorderSide(
                        color: AppColors.uniqueItemBorder,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => unawaited(
                  showOwnedCardImagePreviewDialog(
                    context,
                    title: c.name,
                    imageSrc: imageSrc,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 0.75,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AdaptiveNetworkOrAssetImage(
                              src: imageSrc,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _fallbackDeck(
                                'oracle_card',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: oracleUnique
                                  ? AppColors.uniqueItemForeground
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        oracleUnique ? '유니크 · 탭하여 확대' : '탭하여 확대',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: oracleUnique
                                  ? AppColors.uniqueItemForeground
                                  : AppColors.textSecondary,
                              fontWeight:
                                  oracleUnique ? FontWeight.w600 : null,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _koreaPieceGrid(
    BuildContext context,
    List<_OwnedVisual> koreaPieces,
  ) {
    final koreaDeckEquipped = profile?.equippedCard == koreaTraditionalMajorThemeId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 200,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: koreaPieces.length,
        itemBuilder: (context, i) {
          final c = koreaPieces[i];
          final koreaUnique = c.owned && _isUniqueOwned(c.id, 'korea_major_card');
          final src = _koreaMajorBagPreviewSrc(c);
          final ownedLabel = c.owned ? '보유' : '미보유';
          return AppearAnimation(
            delay: Duration(milliseconds: 24 * i.clamp(0, 12)),
            duration: const Duration(milliseconds: 340),
            child: Card(
              color: Colors.white.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: koreaUnique
                    ? const BorderSide(
                        color: AppColors.uniqueItemBorder,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                    if (!c.owned) {
                      return;
                    }
                  if (src == null || src.isEmpty) {
                    return;
                  }
                  unawaited(
                    showOwnedCardImagePreviewDialog(
                      context,
                      title: c.name,
                      imageSrc: src,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 0.75,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: src != null
                                ? Opacity(
                                    opacity: c.owned ? 1 : 0.4,
                                    child: AdaptiveNetworkOrAssetImage(
                                      src: src,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => _fallbackDeck(
                                        'korea_major_card',
                                      ),
                                    ),
                                  )
                                : _fallbackDeck('korea_major_card'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        koreaUnique ? '${c.name} · 유니크' : c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: koreaUnique
                                  ? AppColors.uniqueItemForeground
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.owned ? '탭하여 확대' : '미보유',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: c.owned
                                  ? AppColors.textSecondary
                                  : const Color(0xFFB45309),
                              fontWeight: c.owned ? null : FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      if (c.owned)
                        FilledButton(
                          onPressed: koreaDeckEquipped
                              ? null
                              : () => _equip(
                                    context,
                                    koreaTraditionalMajorThemeId,
                                    'card',
                                    successMessage: '한국전통 메이저 덱을 선택했어요',
                                  ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 30),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: AppColors.accentPurple,
                          ),
                          child: Text(
                            koreaDeckEquipped ? '장착' : '선택',
                            style: const TextStyle(fontSize: 11),
                          ),
                        )
                      else
                        OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 30),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            ownedLabel,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _ownedEmoticonGridShopStyle(
    BuildContext context,
    List<String> emoticons,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 128,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: emoticons.length,
        itemBuilder: (context, i) {
          final id = emoticons[i];
          final path = bundleEmoticonImagePathForId(id) ?? '';
          final emoUnique = isUniqueEmoticonId(id);
          return AppearAnimation(
            delay: Duration(milliseconds: 20 * i.clamp(0, 15)),
            duration: const Duration(milliseconds: 320),
            child: Card(
              color: Colors.white.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: emoUnique
                    ? const BorderSide(
                        color: AppColors.uniqueItemBorder,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Expanded(
                      child: AdaptiveNetworkOrAssetImage(
                        src: resolveEmoticonImageSrc(
                          remoteImageUrl: path,
                          emoticonId: id,
                        ),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.sentiment_satisfied),
                      ),
                    ),
                    Text(
                      emoUnique
                          ? '${_emoticonDisplayName(id)} · 유니크'
                          : _emoticonDisplayName(id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: emoUnique ? AppColors.uniqueItemForeground : null,
                      ),
                    ),
                    if (emoUnique)
                      Text(
                        '개인 상점 거래 가능',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.uniqueItemForeground,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fallbackDeck(String itemType) {
    final emoji = itemType == 'card_back'
        ? '🎴'
        : itemType == 'oracle_card'
        ? '🔮'
        : itemType == 'korea_major_card'
        ? '🇰🇷'
        : itemType == 'slot'
        ? '🪟'
        : itemType == 'mat'
        ? '🧘'
        : '🃏';
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.cardInner, Color(0xFF98BFAA)],
        ),
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }
}
