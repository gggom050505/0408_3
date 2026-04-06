import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/bundle_emoticon_catalog.dart';
import '../config/emoticon_offline.dart';
import '../config/korea_major_card_catalog.dart';
import '../data/card_themes.dart'
    show
        defaultThemeId,
        kKoreaTraditionalMajorShopThumbnailAsset,
        koreaTraditionalMajorAssetPath,
        koreaTraditionalMajorThemeId,
        resolvePublicAssetUrl,
        resolveShopItemThumbnailSrc,
        kCardThemeThumbnailPath;
import '../data/oracle_assets.dart';
import '../data/slot_shop_assets.dart';
import '../models/shop_models.dart';
import '../standalone/data_sources.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';
import 'app_motion.dart';
import 'oracle_collection_screen.dart';
import 'star_fragments_balance_panel.dart';

/// 한국전통 메이저 **덱** 선택 시 가방에 표시하는 안내(타로는 보유한 장만 섞음).
const String _koreaTraditionalDeckEquipHint =
    '이 덱을 선택하면 타로 화면에는 가방에서 모은 「한국전통 메이저」장만 섞여 나와요. '
    '22장을 다 모을 필요 없고, 아래 🇰🇷 한국전통 메이저 목록에 보유한 카드만 사용됩니다.';

class _OwnedVisual {
  _OwnedVisual({required this.id, required this.name, this.thumbnailUrl});

  final String id;
  final String name;
  final String? thumbnailUrl;
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
          name: si?.name ??
              (item.itemId == defaultThemeId
                  ? '기본카드'
                  : item.itemId == koreaTraditionalMajorThemeId
                      ? '한국전통 메이저카드'
                      : '카드 덱'),
          thumbnailUrl: si?.thumbnailUrl != null
              ? resolveShopItemThumbnailSrc(si!.thumbnailUrl, AppConfig.assetOrigin)
              : (path != null ? resolvePublicAssetUrl(path, AppConfig.assetOrigin) : null),
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
          thumbnailUrl:
              path != null ? resolvePublicAssetUrl(path, AppConfig.assetOrigin) : null,
        ),
      );
    }
    final hasKoreaPieces =
        ownedItems.any((e) => e.itemType == 'korea_major_card');
    if (hasKoreaPieces && !db.any((c) => c.id == koreaTraditionalMajorThemeId)) {
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
      if (e.id == koreaTraditionalMajorThemeId) {
        return ' (선택)';
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
    final db = <_OwnedVisual>[];
    for (final item in ownedItems.where((e) => e.itemType == 'korea_major_card')) {
      final si = _shop(item.itemId);
      final idx = koreaMajorCardIndexFromShopItemId(item.itemId);
      final path = idx != null ? koreaTraditionalMajorAssetPath(idx) : null;
      db.add(
        _OwnedVisual(
          id: item.itemId,
          name: si?.name ?? item.itemId,
          thumbnailUrl: si?.thumbnailUrl != null
              ? resolveShopItemThumbnailSrc(si!.thumbnailUrl, AppConfig.assetOrigin)
              : (path != null ? resolvePublicAssetUrl(path, AppConfig.assetOrigin) : null),
        ),
      );
    }
    db.sort((a, b) => a.id.compareTo(b.id));
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
              ? resolveShopItemThumbnailSrc(si!.thumbnailUrl, AppConfig.assetOrigin)
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
              ? resolveShopItemThumbnailSrc(si!.thumbnailUrl, AppConfig.assetOrigin)
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
              ? resolveShopItemThumbnailSrc(si!.thumbnailUrl, AppConfig.assetOrigin)
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
              ? resolveShopItemThumbnailSrc(si!.thumbnailUrl, AppConfig.assetOrigin)
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
              ? resolveShopItemThumbnailSrc(si!.thumbnailUrl, AppConfig.assetOrigin)
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
      final msg = successMessage ??
          (type == 'card' ? '선택했어요' : '장착했어요');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Center(
        child: Text(
          '로그인 후 가방을 열 수 있어요.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    final cards = _mergeCards();
    final cardBacks = _mergeCardBacks();
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
          stagger(Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                  '덱·카드 뒷면·빈 슬롯 테두리를 장착하면 타로 화면에 바로 반영됩니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          )),
          stagger(StarFragmentsBalancePanel(starFragments: profile?.starFragments)),
          stagger(_header(context, '🃏 카드 덱')),
          ...cards.map(
            (c) => _equipTile(
              context,
              c,
              'card',
              footnote:
                  c.id == koreaTraditionalMajorThemeId ? _koreaTraditionalDeckEquipHint : null,
            ),
          ),
          stagger(_header(context, '🎴 카드 뒷면')),
          ...cardBacks.map((c) => _equipTile(context, c, 'card_back')),
          stagger(_header(context, '🪟 카드 슬롯')),
          ...slots.map((s) => _equipTile(context, s, 'slot')),
          _oracleSectionHeader(context, oracles),
          if (oracles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '출석 이벤트·상점에서 모을 수 있어요',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          if (koreaPieces.isNotEmpty) ...[
            _koreaMajorBagHeader(context, koreaPieces.length),
            ...koreaPieces.map(
              (c) => ListTile(
                leading: SizedBox(
                  width: 40,
                  height: 52,
                  child: c.thumbnailUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AdaptiveNetworkOrAssetImage(
                            src: c.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Center(child: Text('🇰🇷', style: TextStyle(fontSize: 20))),
                          ),
                        )
                      : const Center(child: Text('🇰🇷', style: TextStyle(fontSize: 20))),
                ),
                title: Text(c.name),
                subtitle: const Text('보유', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
          if (emoticons.isNotEmpty) ...[
            stagger(_header(context, '😊 이모티콘')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisExtent: 104,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: emoticons.length,
                itemBuilder: (context, i) {
                  final id = emoticons[i];
                  final path = bundleEmoticonImagePathForId(id) ?? '';
                  return Card(
                    color: Colors.white.withValues(alpha: 0.45),
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
                            _emoticonDisplayName(id),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        t,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _koreaMajorBagHeader(BuildContext context, int ownedCount) {
    const total = 22;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '🇰🇷 한국전통 메이저',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  Widget _oracleSectionHeader(BuildContext context, List<_OwnedVisual> oracles) {
    final n = oracles.length;
    final total = kBundledOracleCardCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final entries = <OracleCollectionEntry>[];
            for (final v in oracles) {
              final imageSrc = (v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty)
                  ? v.thumbnailUrl!
                  : resolveOracleCollectionImageSrc(
                      itemId: v.id,
                      shopThumbnailUrl: _shop(v.id)?.thumbnailUrl,
                    );
              entries.add(
                OracleCollectionEntry(id: v.id, name: v.name, imageSrc: imageSrc),
              );
            }
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (ctx) => OracleCollectionScreen(
                  entries: entries,
                  ownedCount: n,
                  totalCount: total,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '🔮 오라클 카드',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '$n / $total',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _equipTile(
    BuildContext context,
    _OwnedVisual v,
    String type, {
    String? footnote,
  }) {
    final p = profile;
    final isKoreaDeck = type == 'card' && v.id == koreaTraditionalMajorThemeId;
    final koreaDeckActive =
        isKoreaDeck && p?.equippedCard == koreaTraditionalMajorThemeId;

    Widget trailing;
    if (koreaDeckActive) {
      trailing = OutlinedButton(
        onPressed: () => _equip(
          context,
          defaultThemeId,
          'card',
          successMessage: '기본 카드 덱으로 바꿨어요',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentPurple,
          side: const BorderSide(color: AppColors.accentPurple),
        ),
        child: const Text('취소'),
      );
    } else {
      trailing = FilledButton(
        onPressed: () => _equip(
          context,
          v.id,
          type,
          successMessage: isKoreaDeck
              ? '한국전통 메이저 덱을 선택했어요'
              : null,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentPurple,
        ),
        child: Text(type == 'card' ? '선택' : '장착'),
      );
    }

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 48,
        height: 56,
        child: v.thumbnailUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AdaptiveNetworkOrAssetImage(
                  src: v.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _ph(type),
                ),
              )
            : _ph(type),
      ),
      title: Text(v.name),
      trailing: trailing,
    );
    if (footnote == null || footnote.isEmpty) {
      return tile;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            footnote,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }

  Widget _ph(String type) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardInner,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        type == 'card'
            ? '🃏'
            : type == 'card_back'
                ? '🎴'
                : type == 'oracle_card'
                    ? '🔮'
                    : type == 'korea_major_card'
                        ? '🇰🇷'
                        : type == 'slot'
                            ? '🪟'
                            : '🧘',
      ),
    );
  }
}
