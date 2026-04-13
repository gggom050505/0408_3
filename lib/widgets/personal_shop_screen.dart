import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/bundle_emoticon_catalog.dart';
import '../config/unique_shop_items.dart';
import '../data/card_themes.dart' show resolveShopItemThumbnailSrc;
import '../models/emoticon_models.dart';
import '../models/peer_shop_models.dart';
import '../models/shop_models.dart';
import '../standalone/data_sources.dart';
import '../standalone/local_shop_repository.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';

String _purchaseOutcomeMessage(PeerShopPurchaseOutcome o) {
  return switch (o) {
    PeerShopPurchaseOutcome.success => '구매가 완료되었어요.',
    PeerShopPurchaseOutcome.listingGone => '이미 팔렸거나 종료된 진열이에요.',
    PeerShopPurchaseOutcome.insufficientStars => '별조각이 부족해요.',
    PeerShopPurchaseOutcome.alreadyOwns => '이미 같은 품목을 가지고 있어요.',
    PeerShopPurchaseOutcome.cannotBuyOwnListing => '내 진열은 살 수 없어요.',
    PeerShopPurchaseOutcome.sellerNoLongerHasItem =>
      '판매자가 더 이상 이 품목을 갖고 있지 않아요.',
    PeerShopPurchaseOutcome.notFound => '진열을 찾지 못했어요.',
    PeerShopPurchaseOutcome.serverNotConfigured =>
      '개인 상점용 서버가 연결되어 있지 않아요. (가비아 정적 사이트만 쓰는 빌드에서는 지원하지 않아요.)',
    PeerShopPurchaseOutcome.error => '처리 중 오류가 났어요.',
  };
}

enum _ListingSort { newest, priceAsc, priceDesc, nameAz }

const _peerShopTypeOrder = <String>[
  'card',
  'korea_major_card',
  'oracle_card',
  'emoticon',
  'card_back',
  'mat',
  'slot',
];

String _typeSectionTitle(String type) {
  return switch (type) {
    'card' => '🃏 카드 덱',
    'korea_major_card' => '🇰🇷 한국전통 메이저',
    'oracle_card' => '🔮 오라클',
    'emoticon' => '😊 이모티콘',
    'card_back' => '🎴 카드 뒷면',
    'mat' => '🧘 매트',
    'slot' => '🪟 슬롯',
    _ => '📦 기타',
  };
}

/// 칩·필터용 짧은 라벨
String _typeChipLabel(String type) {
  return switch (type) {
    'card' => '카드 덱',
    'korea_major_card' => '한국 메이저',
    'oracle_card' => '오라클',
    'emoticon' => '이모티콘',
    'card_back' => '뒷면',
    'mat' => '매트',
    'slot' => '슬롯',
    _ => type,
  };
}

List<String> _orderedTypesPresent(Iterable<String> types) {
  final set = types.toSet();
  final out = <String>[];
  for (final t in _peerShopTypeOrder) {
    if (set.contains(t)) {
      out.add(t);
    }
  }
  final rest = set.where((t) => !_peerShopTypeOrder.contains(t)).toList()
    ..sort();
  out.addAll(rest);
  return out;
}

int _typeSortRank(String type) {
  final idx = _peerShopTypeOrder.indexOf(type);
  return idx >= 0 ? idx : _peerShopTypeOrder.length + 1;
}

void _sortListings(
  List<PeerShopListing> list,
  _ListingSort sort,
  String Function(String itemId, String itemType) labelFn,
) {
  switch (sort) {
    case _ListingSort.priceAsc:
      list.sort((a, b) => a.priceStars.compareTo(b.priceStars));
    case _ListingSort.priceDesc:
      list.sort((a, b) => b.priceStars.compareTo(a.priceStars));
    case _ListingSort.nameAz:
      list.sort(
        (a, b) => labelFn(
          a.itemId,
          a.itemType,
        ).compareTo(labelFn(b.itemId, b.itemType)),
      );
    case _ListingSort.newest:
      list.sort((a, b) {
        final da =
            DateTime.tryParse(a.createdAtIso)?.millisecondsSinceEpoch ?? 0;
        final db =
            DateTime.tryParse(b.createdAtIso)?.millisecondsSinceEpoch ?? 0;
        return db.compareTo(da);
      });
  }
}

List<PeerShopListing> _filterByType(
  List<PeerShopListing> src,
  String? typeFilter,
) {
  if (typeFilter == null) {
    return List<PeerShopListing>.from(src);
  }
  return src.where((L) => L.itemType == typeFilter).toList();
}

ShopItemRow? _catalogRow(
  List<ShopItemRow> catalog,
  String itemId,
  String type,
) {
  for (final r in catalog) {
    if (r.id == itemId && r.type == type) {
      return r;
    }
  }
  return null;
}

class PersonalShopScreen extends StatefulWidget {
  const PersonalShopScreen({
    super.key,
    required this.shopRepo,
    required this.peerShop,
    required this.userId,
    required this.displayName,
    required this.shopItems,
    required this.onNeedRefreshShop,
    this.scaffoldMessengerKey,
  });

  final ShopDataSource shopRepo;
  final PeerShopDataSource peerShop;
  final String userId;
  final String displayName;
  final List<ShopItemRow> shopItems;
  final Future<void> Function() onNeedRefreshShop;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  @override
  State<PersonalShopScreen> createState() => _PersonalShopScreenState();
}

class _PersonalShopScreenState extends State<PersonalShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  List<PeerShopListing> _market = [];
  List<PeerShopListing> _mine = [];
  UserProfileRow? _profile;
  final Set<String> _ownedItemKeys = <String>{};
  final Set<String> _ownedEmoticonIds = <String>{};
  var _loading = true;
  String? _loadError;

  /// `null` = 전체
  String? _marketTypeFilter;
  _ListingSort _marketSort = _ListingSort.newest;
  String? _mineTypeFilter;
  _ListingSort _mineSort = _ListingSort.newest;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    unawaited(_reload());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final prof = await widget.shopRepo.fetchProfile(widget.userId);
      final owned = await widget.shopRepo.fetchOwnedItems(widget.userId);
      final m = await widget.peerShop.fetchMarketplace(widget.userId);
      final my = await widget.peerShop.fetchMyListings(widget.userId);
      final ownedItemKeys = <String>{
        for (final o in owned) '${o.itemId}\u{1e}${o.itemType}',
      };
      final ownedEmoticons = <String>{};
      final repo = widget.shopRepo;
      if (repo is LocalShopRepository) {
        final list = await repo.getOwnedEmoticonIds();
        ownedEmoticons.addAll(list);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = prof;
        _ownedItemKeys
          ..clear()
          ..addAll(ownedItemKeys);
        _ownedEmoticonIds
          ..clear()
          ..addAll(ownedEmoticons);
        _market = m;
        _mine = my;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _snack(String text) {
    widget.scaffoldMessengerKey?.currentState?.showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _buy(PeerShopListing listing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('별조각으로 구매'),
        content: Text(
          '${_itemLabel(listing.itemId, listing.itemType)}\n'
          '⭐ ${listing.priceStars} · 판매자 ${_sellerLabel(listing)}\n\n'
          '구매할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('구매'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    final out = await widget.peerShop.purchaseListing(
      buyerId: widget.userId,
      listingId: listing.id,
    );
    if (!mounted) {
      return;
    }
    _snack(_purchaseOutcomeMessage(out));
    if (out == PeerShopPurchaseOutcome.success) {
      await widget.onNeedRefreshShop();
      await _reload();
    }
  }

  Future<void> _cancelMine(PeerShopListing listing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('진열 내리기'),
        content: const Text('이 품목을 진열에서 내릴까요? (보유는 유지돼요.)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('아니오'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('내리기'),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    final done = await widget.peerShop.cancelListing(
      listingId: listing.id,
      sellerId: widget.userId,
    );
    if (!mounted) {
      return;
    }
    _snack(done ? '진열을 내렸어요.' : '진열 내리기에 실패했어요.');
    await _reload();
  }

  String _itemLabel(String itemId, String type) {
    final row = _catalogRow(widget.shopItems, itemId, type);
    final unique = isUniqueShopItem(itemId, type);
    if (type == 'emoticon') {
      EmoticonRow? emo;
      for (final e in kBundleEmoticonRows) {
        if (e.id == itemId) {
          emo = e;
          break;
        }
      }
      final base = emo?.name ?? '이모티콘';
      return unique ? '$base · 유니크' : base;
    }
    if (row != null && row.name.isNotEmpty) {
      return unique ? '${row.name} · 유니크' : row.name;
    }
    return unique ? '$type · $itemId · 유니크' : '$type · $itemId';
  }

  Widget _filterSortControls({
    required ThemeData theme,
    required bool forMine,
  }) {
    final src = forMine ? _mine : _market;
    final types = _orderedTypesPresent(src.map((L) => L.itemType));
    final filter = forMine ? _mineTypeFilter : _marketTypeFilter;
    final sort = forMine ? _mineSort : _marketSort;

    void setFilter(String? v) {
      setState(() {
        if (forMine) {
          _mineTypeFilter = v;
        } else {
          _marketTypeFilter = v;
        }
      });
    }

    void setSort(_ListingSort v) {
      setState(() {
        if (forMine) {
          _mineSort = v;
        } else {
          _marketSort = v;
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '종류',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('전체'),
                  selected: filter == null,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setFilter(null),
                ),
                for (final t in types) ...[
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(_typeChipLabel(t)),
                    selected: filter == t,
                    visualDensity: VisualDensity.compact,
                    onSelected: (sel) => setFilter(sel ? t : null),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '정렬',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<_ListingSort>(
            key: ValueKey<_ListingSort>(sort),
            initialValue: sort,
            isDense: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: _ListingSort.newest,
                child: Text('최신 진열 순'),
              ),
              DropdownMenuItem(
                value: _ListingSort.priceAsc,
                child: Text('가격 낮은 순'),
              ),
              DropdownMenuItem(
                value: _ListingSort.priceDesc,
                child: Text('가격 높은 순'),
              ),
              DropdownMenuItem(
                value: _ListingSort.nameAz,
                child: Text('이름 순 (가나다·ABC)'),
              ),
            ],
            onChanged: (v) => setSort(v ?? _ListingSort.newest),
          ),
        ],
      ),
    );
  }

  Widget _marketListingTile(ThemeData theme, PeerShopListing L) {
    final isOwn = L.sellerId == widget.userId;
    final unique = isUniqueShopItem(L.itemId, L.itemType);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: unique
            ? const BorderSide(color: AppColors.uniqueItemBorder, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: _thumb(L.itemId, L.itemType),
        title: Text(
          _itemLabel(L.itemId, L.itemType),
          style: unique
              ? theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.uniqueItemForeground,
                  fontWeight: FontWeight.w700,
                )
              : null,
        ),
        subtitle: Text(
          isOwn
              ? '내 진열 · ⭐ ${L.priceStars}'
              : '${_sellerLabel(L)} · ⭐ ${L.priceStars}',
        ),
        trailing: isOwn
            ? Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '내가 올림',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : FilledButton(
                onPressed: () => unawaited(_buy(L)),
                child: const Text('구매'),
              ),
      ),
    );
  }

  Widget _mineListingTile(ThemeData theme, PeerShopListing L) {
    final unique = isUniqueShopItem(L.itemId, L.itemType);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: unique
            ? const BorderSide(color: AppColors.uniqueItemBorder, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: _thumb(L.itemId, L.itemType),
        title: Text(
          _itemLabel(L.itemId, L.itemType),
          style: unique
              ? theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.uniqueItemForeground,
                  fontWeight: FontWeight.w700,
                )
              : null,
        ),
        subtitle: Text('⭐ ${L.priceStars}'),
        trailing: TextButton(
          onPressed: () => unawaited(_cancelMine(L)),
          child: const Text('내리기'),
        ),
      ),
    );
  }

  String _sellerLabel(PeerShopListing L) {
    final n = L.sellerDisplayName?.trim();
    if (n != null && n.isNotEmpty) {
      return n;
    }
    final id = L.sellerId;
    if (id.length <= 10) {
      return id;
    }
    return '${id.substring(0, 6)}…${id.substring(id.length - 4)}';
  }

  Widget _thumb(String itemId, String type) {
    final row = _catalogRow(widget.shopItems, itemId, type);
    final rawThumb = type == 'emoticon'
        ? bundleEmoticonImagePathForId(itemId)
        : row?.thumbnailUrl;
    final src = resolveShopItemThumbnailSrc(rawThumb, AppConfig.assetOrigin);
    final r = 8.0;
    if (src == null || src.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Container(
          width: 52,
          height: 52,
          color: AppColors.accentLilac.withValues(alpha: 0.35),
          alignment: Alignment.center,
          child: const Icon(Icons.inventory_2_outlined, size: 26),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: looksLikeNetworkImageUrl(src)
          ? Image.network(src, width: 52, height: 52, fit: BoxFit.cover)
          : Image.asset(src, width: 52, height: 52, fit: BoxFit.cover),
    );
  }

  String? _thumbSrcForItem(String itemId, String type) {
    final row = _catalogRow(widget.shopItems, itemId, type);
    final rawThumb = type == 'emoticon'
        ? bundleEmoticonImagePathForId(itemId)
        : row?.thumbnailUrl;
    return resolveShopItemThumbnailSrc(rawThumb, AppConfig.assetOrigin);
  }

  Widget _tinyThumb(String itemId, String type) {
    final src = _thumbSrcForItem(itemId, type);
    Widget tinyFallback() {
      final icon = switch (type) {
        'card' => Icons.style_outlined,
        'korea_major_card' => Icons.flag_outlined,
        'oracle_card' => Icons.auto_awesome_outlined,
        'emoticon' => Icons.sentiment_satisfied_outlined,
        'card_back' => Icons.layers_outlined,
        'mat' => Icons.grid_on_outlined,
        'slot' => Icons.crop_square_outlined,
        _ => Icons.inventory_2_outlined,
      };
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accentLilac.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      );
    }
    if (src == null || src.isEmpty) {
      return SizedBox(
        width: 24,
        height: 24,
        child: tinyFallback(),
      );
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AdaptiveNetworkOrAssetImage(
          src: src,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) => tinyFallback(),
        ),
      ),
    );
  }

  Widget _itemDropdownRow(
    BuildContext context, {
    required String itemId,
    required String itemType,
  }) {
    final isUnique = isUniqueShopItem(itemId, itemType);
    final owned = _isOwnedCandidate(itemId, itemType);
    return Row(
      children: [
        _tinyThumb(itemId, itemType),
        const SizedBox(width: 8),
        Text(
          '[${_typeChipLabel(itemType)}] ',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            _itemLabel(itemId, itemType),
            overflow: TextOverflow.ellipsis,
            style: isUnique
                ? const TextStyle(
                    color: AppColors.uniqueItemForeground,
                    fontWeight: FontWeight.w700,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          owned ? '[보유]' : '[미보유]',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: owned ? const Color(0xFF2563EB) : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isUnique ? '[유니크]' : '[일반]',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isUnique
                ? AppColors.uniqueItemBorder
                : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  bool _isOwnedCandidate(String itemId, String itemType) {
    if (itemType == 'emoticon') {
      return _ownedEmoticonIds.contains(itemId);
    }
    return _ownedItemKeys.contains('$itemId\u{1e}$itemType');
  }

  List<({String itemId, String itemType})> _eligibleToList() {
    final seen = <String>{};
    final out = <({String itemId, String itemType})>[];
    for (final s in widget.shopItems) {
      final key = '${s.id}\u{1e}${s.type}';
      if (!seen.add(key)) {
        continue;
      }
      if (_mine.any((L) => L.itemId == s.id && L.itemType == s.type)) {
        continue;
      }
      out.add((itemId: s.id, itemType: s.type));
    }
    for (final emo in kBundleEmoticonRows) {
      final emoId = emo.id;
      final key = '$emoId\u{1e}emoticon';
      if (!seen.add(key)) {
        continue;
      }
      if (_mine.any((L) => L.itemId == emoId && L.itemType == 'emoticon')) {
        continue;
      }
      out.add((itemId: emoId, itemType: 'emoticon'));
    }
    out.sort((a, b) {
      final typeCmp = _typeSortRank(
        a.itemType,
      ).compareTo(_typeSortRank(b.itemType));
      if (typeCmp != 0) {
        return typeCmp;
      }
      return _itemLabel(
        a.itemId,
        a.itemType,
      ).compareTo(_itemLabel(b.itemId, b.itemType));
    });
    return out;
  }

  Future<void> _openListDialog() async {
    final p = _profile;
    if (p == null) {
      return;
    }
    final eligible = _eligibleToList();
    if (eligible.isEmpty) {
      _snack('진열할 수 있는 품목이 없어요. (장착 중이거나 이미 진열 중인 품목은 제외돼요.)');
      return;
    }
    var typeFilter = 'all';
    var pickedIndex = 0;
    final priceCtrl = TextEditingController(text: '5');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setSt) {
          final typeItems = <DropdownMenuItem<String>>[
            const DropdownMenuItem(value: 'all', child: Text('전체')),
            ..._orderedTypesPresent(eligible.map((e) => e.itemType)).map(
              (t) => DropdownMenuItem(value: t, child: Text(_typeChipLabel(t))),
            ),
          ];
          final filteredEligible = typeFilter == 'all'
              ? eligible
              : eligible.where((e) => e.itemType == typeFilter).toList();
          if (filteredEligible.isEmpty) {
            pickedIndex = 0;
          } else if (pickedIndex >= filteredEligible.length) {
            pickedIndex = 0;
          }
          return AlertDialog(
            title: const Text('개인 상점에 올리기'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '상점 품목 전체에서 선택하세요.\n종류별로 묶어 정렬되어 있어 빠르게 찾을 수 있어요.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>('type-$typeFilter'),
                    initialValue: typeFilter,
                    decoration: const InputDecoration(labelText: '종류'),
                    items: typeItems,
                    onChanged: (v) {
                      setSt(() {
                        typeFilter = v ?? 'all';
                        pickedIndex = 0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey<String>('item-$typeFilter-$pickedIndex'),
                    initialValue: filteredEligible.isEmpty ? null : pickedIndex,
                    decoration: const InputDecoration(labelText: '품목'),
                    selectedItemBuilder: (_) => [
                      for (var i = 0; i < filteredEligible.length; i++)
                        _itemDropdownRow(
                          context,
                          itemId: filteredEligible[i].itemId,
                          itemType: filteredEligible[i].itemType,
                        ),
                    ],
                    items: [
                      for (var i = 0; i < filteredEligible.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: _itemDropdownRow(
                            context,
                            itemId: filteredEligible[i].itemId,
                            itemType: filteredEligible[i].itemType,
                          ),
                        ),
                    ],
                    onChanged: filteredEligible.isEmpty
                        ? null
                        : (v) => setSt(() => pickedIndex = v ?? 0),
                  ),
                  if (filteredEligible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '선택한 종류에 등록 가능한 품목이 없어요.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '가격 (⭐)',
                      hintText: '1 ~ 999999',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('등록'),
              ),
            ],
          );
        },
      ),
    );
    final priceRaw = priceCtrl.text.trim();
    priceCtrl.dispose();
    final price = int.tryParse(priceRaw) ?? 0;
    if (ok != true) {
      return;
    }
    final finalEligible = typeFilter == 'all'
        ? eligible
        : eligible.where((e) => e.itemType == typeFilter).toList();
    if (finalEligible.isEmpty) {
      _snack('선택한 종류에 등록 가능한 품목이 없어요.');
      return;
    }
    final picked = finalEligible[pickedIndex];
    if (price < 1 || price > 999999) {
      _snack('가격은 1~999999 별조각 사이로 입력해 주세요.');
      return;
    }
    final created = await widget.peerShop.createListing(
      sellerId: widget.userId,
      sellerDisplayName: widget.displayName,
      itemId: picked.itemId,
      itemType: picked.itemType,
      priceStars: price,
    );
    if (!mounted) {
      return;
    }
    if (created == null) {
      _snack('등록에 실패했어요. 중복 진열·가격 범위를 확인해 주세요.');
      return;
    }
    _snack('진열에 올렸어요.');
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인 상점'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '둘러보기'),
            Tab(text: '내가 팔기'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '불러오지 못했어요.\n$_loadError',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
          : TabBarView(
              controller: _tab,
              children: [_buildMarket(theme), _buildMine(theme)],
            ),
    );
  }

  Widget _buildMarket(ThemeData theme) {
    if (_market.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '표시할 진열이 없어요.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppConfig.useOfflineBundleOnly
                ? '같은 기기의 로컬 계정끼리 `local_peer_shop_listings_v1.json` 으로 거래돼요.'
                : '현재 빌드는 같은 브라우저/기기의 계정끼리 개인 상점 거래가 동작해요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      );
    }
    final filtered = _filterByType(_market, _marketTypeFilter);
    if (filtered.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _filterSortControls(theme: theme, forMine: false),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '조건에 맞는 진열이 없어요.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }
    final typeKeys = _orderedTypesPresent(filtered.map((L) => L.itemType));
    final children = <Widget>[
      _filterSortControls(theme: theme, forMine: false),
    ];
    for (final t in typeKeys) {
      final items = filtered.where((L) => L.itemType == t).toList();
      if (items.isEmpty) {
        continue;
      }
      _sortListings(items, _marketSort, _itemLabel);
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(
            _typeSectionTitle(t),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
      for (final L in items) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: _marketListingTile(theme, L),
          ),
        );
      }
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: children,
    );
  }

  Widget _buildMine(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 16, 8),
          child: Text(
            '상점의 모든 품목(카드·한국전통·오라클·이모티콘·뒷면·매트·슬롯)을 진열할 수 있어요.\n같은 품목은 동시에 1개 진열만 가능해요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            onPressed: _openListDialog,
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('품목 진열하기'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _mine.isEmpty
              ? Center(
                  child: Text(
                    '올린 진열이 없어요.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : Builder(
                  builder: (ctx) {
                    final filtered = _filterByType(_mine, _mineTypeFilter);
                    if (filtered.isEmpty) {
                      return ListView(
                        children: [
                          _filterSortControls(theme: theme, forMine: true),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              '조건에 맞는 진열이 없어요.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    final typeKeys = _orderedTypesPresent(
                      filtered.map((L) => L.itemType),
                    );
                    final children = <Widget>[
                      _filterSortControls(theme: theme, forMine: true),
                    ];
                    for (final t in typeKeys) {
                      final items = filtered
                          .where((L) => L.itemType == t)
                          .toList();
                      if (items.isEmpty) {
                        continue;
                      }
                      _sortListings(items, _mineSort, _itemLabel);
                      children.add(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                          child: Text(
                            _typeSectionTitle(t),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                      for (final L in items) {
                        children.add(
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                            child: _mineListingTile(theme, L),
                          ),
                        );
                      }
                    }
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: children,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
