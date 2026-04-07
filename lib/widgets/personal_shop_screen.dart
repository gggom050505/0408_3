import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/card_themes.dart' show resolveShopItemThumbnailSrc;
import '../models/peer_shop_models.dart';
import '../models/shop_models.dart';
import '../standalone/data_sources.dart';
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
      '서버에 개인 상점 테이블·구매 함수가 없어요. docs/supabase_peer_shop_listings.sql 을 적용해 주세요.',
    PeerShopPurchaseOutcome.error => '처리 중 오류가 났어요.',
  };
}

bool _itemEquipped(UserProfileRow p, UserItemRow o) {
  return switch (o.itemType) {
    'card' => p.equippedCard == o.itemId,
    'mat' => p.equippedMat == o.itemId,
    'card_back' => p.equippedCardBack == o.itemId,
    'slot' => p.equippedSlot == o.itemId,
    _ => false,
  };
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
  List<UserItemRow> _owned = [];
  var _loading = true;
  String? _loadError;

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
      final own = await widget.shopRepo.fetchOwnedItems(widget.userId);
      final m = await widget.peerShop.fetchMarketplace(widget.userId);
      final my = await widget.peerShop.fetchMyListings(widget.userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = prof;
        _owned = gggomDedupeOwnedItems(own);
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
    if (row != null && row.name.isNotEmpty) {
      return row.name;
    }
    return '$type · $itemId';
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
    final src = resolveShopItemThumbnailSrc(
      row?.thumbnailUrl,
      AppConfig.assetOrigin,
    );
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

  List<UserItemRow> _eligibleToList() {
    final p = _profile;
    if (p == null) {
      return [];
    }
    return _owned.where((o) {
      if (_itemEquipped(p, o)) {
        return false;
      }
      if (_mine.any((L) => L.itemId == o.itemId && L.itemType == o.itemType)) {
        return false;
      }
      return true;
    }).toList();
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
    var pickedIndex = 0;
    final priceCtrl = TextEditingController(text: '5');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setSt) {
          return AlertDialog(
            title: const Text('개인 상점에 올리기'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '보유 품목·희망 가격(별조각)을 정해 주세요.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ignore: deprecated_member_use
                  DropdownButtonFormField<int>(
                    value: pickedIndex,
                    decoration: const InputDecoration(labelText: '품목'),
                    items: [
                      for (var i = 0; i < eligible.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(
                            _itemLabel(
                              eligible[i].itemId,
                              eligible[i].itemType,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setSt(() => pickedIndex = v ?? 0),
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
    final picked = eligible[pickedIndex];
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
      _snack('등록에 실패했어요. 보유·장착·중복 진열·서버(DB) 설정을 확인해 주세요.');
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
                ? '오프라인 번들에서는 같은 기기의 로컬 계정끼리 `local_peer_shop_listings_v1.json` 으로 공유돼요.'
                : '친구가 상점에서 품목을 올리면 여기에 표시돼요. (Supabase에는 docs/supabase_peer_shop_listings.sql 적용이 필요해요.)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _market.length,
      separatorBuilder: (context, i) => const SizedBox(height: 6),
      itemBuilder: (c, i) {
        final L = _market[i];
        final isOwn = L.sellerId == widget.userId;
        return Card(
          child: ListTile(
            leading: _thumb(L.itemId, L.itemType),
            title: Text(_itemLabel(L.itemId, L.itemType)),
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
            isThreeLine: false,
          ),
        );
      },
    );
  }

  Widget _buildMine(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 16, 8),
          child: Text(
            '장착 중인 덱·매트·뒷면·슬롯은 올릴 수 없어요.',
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
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _mine.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 6),
                  itemBuilder: (c, i) {
                    final L = _mine[i];
                    return Card(
                      child: ListTile(
                        leading: _thumb(L.itemId, L.itemType),
                        title: Text(_itemLabel(L.itemId, L.itemType)),
                        subtitle: Text('⭐ ${L.priceStars}'),
                        trailing: TextButton(
                          onPressed: () => unawaited(_cancelMine(L)),
                          child: const Text('내리기'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
