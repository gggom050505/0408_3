import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/bundle_emoticon_catalog.dart'
    show bundleEmoticonPriceForUser, kBundleEmoticonRows;
import '../config/korea_major_card_catalog.dart';
import '../config/emoticon_offline.dart';
import '../data/card_themes.dart';
import '../data/oracle_assets.dart';
import '../models/emoticon_models.dart';
import '../models/shop_models.dart';
import '../models/surprise_gift_models.dart';
import '../standalone/data_sources.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';
import 'app_motion.dart';
import 'oracle_shop_bundle_screen.dart';
import 'star_fragments_balance_panel.dart';

const int _kOracleShopBundleSize = 10;

String _shopItemPurchaseFailMessage(int price) {
  return switch (price) {
    1 => '별조각이 부족하거나, 오늘은 이미 ⭐1 상품을 구매했거나, 이미 수집했을 수 있어요. (UTC 기준 하루 1번)',
    2 =>
      '별조각이 부족하거나, 오늘은 ⭐2 상품 구매 가능 횟수(날마다 2~3번, UTC)를 모두 썼거나, 이미 수집했을 수 있어요.',
    _ => '별조각이 부족하거나 구매에 실패했습니다.',
  };
}

String _emoticonPurchaseFailMessage(int price) {
  return switch (price) {
    1 => '별조각이 부족하거나, 오늘은 이미 ⭐1 상품을 구매했거나, 이미 수집했을 수 있어요. (UTC 기준 하루 1번)',
    2 =>
      '별조각이 부족하거나, 오늘은 ⭐2 상품 구매 가능 횟수(날마다 2~3번, UTC)를 모두 썼거나, 이미 수집했을 수 있어요.',
    _ => '별조각이 부족하거나 이미 수집했을 수 있어요.',
  };
}

class ShopTab extends StatelessWidget {
  const ShopTab({
    super.key,
    required this.repo,
    required this.userId,
    required this.displayName,
    required this.shopItems,
    required this.profile,
    required this.ownedItems,
    required this.onRefresh,
    required this.onNeedLogin,
    required this.emoticonRepo,
    required this.emoticonPacks,
    required this.ownedEmoticonIds,
    this.surpriseGiftOffer,
    this.onClaimSurpriseGift,
    this.onBetaAdReward,
    this.onOpenPersonalShop,
    this.onOpenShopAdmin,
  });

  final ShopDataSource repo;
  final String? userId;
  final String displayName;
  final List<ShopItemRow> shopItems;
  final UserProfileRow? profile;
  final List<UserItemRow> ownedItems;
  final Future<void> Function() onRefresh;
  final VoidCallback onNeedLogin;
  final EmoticonDataSource emoticonRepo;
  final List<EmoticonPackRow> emoticonPacks;
  final List<String> ownedEmoticonIds;

  /// 2~7일 주기 깜짝 선물 — [onClaimSurpriseGift]와 함께 전달.
  final SurpriseGiftOffer? surpriseGiftOffer;
  final Future<void> Function(SurpriseGiftOffer offer)? onClaimSurpriseGift;

  /// 별조각 광고(영상 시청) 시트 — null이면 상점 배너 숨김
  final VoidCallback? onBetaAdReward;

  /// 개인 상점(유저 간 별조각 거래) — null이면 배너 숨김
  final VoidCallback? onOpenPersonalShop;

  /// 오프라인·베타 번들: 상품 CRUD 화면
  final VoidCallback? onOpenShopAdmin;

  bool _shopItemOwned(ShopItemRow item) =>
      ownedItems.any((e) => e.itemId == item.id && e.itemType == item.type);

  bool _emoOwned(String id) => ownedEmoticonIds.contains(id);

  List<EmoticonRow> _individualEmos() {
    final fromPacks = emoticonPacks
        .expand((p) => p.emoticons.where((e) => e.price > 0))
        .toList();
    if (fromPacks.isNotEmpty) {
      return fromPacks;
    }
    final uid = userId;
    return kBundleEmoticonRows
        .where((e) => bundleEmoticonPriceForUser(e.id, uid) > 0)
        .toList();
  }

  bool _allPackOwned(EmoticonPackRow pack) =>
      pack.emoticons.isNotEmpty && pack.emoticons.every((e) => _emoOwned(e.id));

  Future<void> _buyPack(BuildContext context, EmoticonPackRow pack) async {
    final uid = userId;
    if (uid == null) {
      return;
    }
    if (pack.price > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(pack.name),
          content: Text('⭐ ${pack.price} 별조각으로 팩을 구매할까요?'),
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
      if (ok != true) {
        return;
      }
    }
    final r = await emoticonRepo.buyPack(userId: uid, packId: pack.id);
    if (!context.mounted) {
      return;
    }
    if (r.ok) {
      await onRefresh();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('팩 구매 완료!')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(r.error ?? '팩 구매 실패')));
    }
  }

  Future<void> _buyEmo(BuildContext context, EmoticonRow emo) async {
    final uid = userId;
    if (uid == null) {
      return;
    }
    final price = bundleEmoticonPriceForUser(emo.id, uid);
    final okDlg = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(emo.name),
        content: Text('⭐ $price 별조각으로 구매할까요?'),
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
    if (okDlg != true) {
      return;
    }
    final ok = await emoticonRepo.buyEmoticon(
      userId: uid,
      emoticonId: emo.id,
      price: price,
      ownedIds: ownedEmoticonIds,
    );
    if (!context.mounted) {
      return;
    }
    if (ok) {
      await onRefresh();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('구매 완료!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_emoticonPurchaseFailMessage(price))),
      );
    }
  }

  /// 상점 단품 구매. 성공 시 `true`.
  Future<bool> _buy(BuildContext context, ShopItemRow item) async {
    final uid = userId;
    if (uid == null) {
      onNeedLogin();
      return false;
    }
    final p = profile;
    if (p == null) {
      return false;
    }
    if (_shopItemOwned(item)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 수집한 아이템입니다.')));
      return false;
    }
    if (item.price > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(item.name),
          content: Text('⭐ ${item.price} 별조각으로 구매할까요?'),
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
      if (ok != true) {
        return false;
      }
    }
    final success = await repo.buyItem(
      userId: uid,
      itemId: item.id,
      price: item.price,
      type: item.type,
      profile: p,
      owned: ownedItems,
    );
    if (!context.mounted) {
      return false;
    }
    if (success) {
      await onRefresh();
      if (!context.mounted) {
        return true;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('구매 완료!')));
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_shopItemPurchaseFailMessage(item.price))),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Center(
        child: Text(
          '로그인 후 상점을 이용할 수 있어요.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final cards = shopItems.where((e) => e.type == 'card').toList();
    final cardBacks = shopItems.where((e) => e.type == 'card_back').toList();
    final slots = shopItems.where((e) => e.type == 'slot').toList();
    final koreaMajors =
        shopItems.where((e) => e.type == 'korea_major_card').toList()
          ..sort((a, b) {
            final ia = koreaMajorCardIndexFromShopItemId(a.id) ?? 99;
            final ib = koreaMajorCardIndexFromShopItemId(b.id) ?? 99;
            return ia.compareTo(ib);
          });
    final oracles = shopItems.where((e) => e.type == 'oracle_card').toList();
    final gift = surpriseGiftOffer;
    final claimGift = onClaimSurpriseGift;

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
                          '🏪 상점',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '새로운 카드 덱과 테마를 만나보세요',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '매일매일 상점 품목 시세가 바껴요~',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (onOpenShopAdmin != null)
                    IconButton(
                      tooltip: '관리자 모드 · 상품 편집',
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      onPressed: onOpenShopAdmin,
                    ),
                ],
              ),
            ),
          ),
          stagger(
            StarFragmentsBalancePanel(
              starFragments: profile?.starFragments,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '보유 품목을 별조각에 올려 거래해요.',
                                  style: Theme.of(context).textTheme.labelSmall
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
          if (onBetaAdReward != null)
            stagger(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Material(
                  color: const Color(0xFFFFE8CC),
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onBetaAdReward,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.smart_display_outlined,
                            color: const Color(0xFFB45309),
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📺 별조각 광고',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '광고 시청 후 별조각 ${AppConfig.adRewardStarAmount}개 · ${AppConfig.adRewardCooldownMinutes}분마다 · 영상 순서 순환',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppConfig.adInquiryContactLine,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
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
          if (gift != null && claimGift != null)
            stagger(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer.withValues(alpha: 0.55),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: () {
                              final thumb = resolveShopItemThumbnailSrc(
                                gift.thumbnailUrl,
                                AppConfig.assetOrigin,
                              );
                              if (thumb != null) {
                                return AdaptiveNetworkOrAssetImage(
                                  src: thumb,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Text(
                                      '🎁',
                                      style: TextStyle(fontSize: 28),
                                    ),
                                  ),
                                );
                              }
                              return const Center(
                                child: Text(
                                  '🎁',
                                  style: TextStyle(fontSize: 28),
                                ),
                              );
                            }(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '깜짝 선물',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              Text(
                                gift.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '별조각 없이 무료로 받을 수 있어요',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => claimGift(gift),
                          child: const Text('받기'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          stagger(_sectionTitle(context, '🃏 카드 덱')),
          _itemGrid(context, cards),
          if (koreaMajors.isNotEmpty) ...[
            stagger(_sectionTitle(context, '🇰🇷 한국전통 메이저 (장별)')),
            _itemGrid(context, koreaMajors),
          ],
          stagger(_sectionTitle(context, '🎴 카드 뒷면')),
          _itemGrid(context, cardBacks),
          if (slots.isNotEmpty) ...[
            stagger(_sectionTitle(context, '🪟 카드 슬롯')),
            _itemGrid(context, slots),
          ],
          if (oracles.isNotEmpty) ...[
            stagger(_sectionTitle(context, '🔮 오라클 카드')),
            _oracleBundleToc(
              context,
              _chunkOracleShopItems(_sortOracleShopItems(oracles)),
            ),
          ],
          if (emoticonPacks.isNotEmpty) ...[
            stagger(_sectionTitle(context, '😊 이모티콘 팩')),
            _emoticonPackStrip(context),
          ],
          if (_individualEmos().isNotEmpty) ...[
            stagger(_sectionTitle(context, '😊 개별 이모티콘')),
            _individualEmoticonGrid(context),
          ],
        ],
      ),
    );
  }

  Widget _emoticonPackStrip(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: emoticonPacks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, idx) {
          final pack = emoticonPacks[idx];
          final allOwn = _allPackOwned(pack);
          final thumb = resolveEmoticonPackThumbnailSrc(
            packId: pack.id,
            remoteThumbnailPath: pack.thumbnailUrl,
            assetOrigin: AppConfig.assetOrigin,
          );
          return SizedBox(
            width: 132,
            child: Card(
              color: Colors.white.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Expanded(
                      child: thumb != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AdaptiveNetworkOrAssetImage(
                                src: thumb,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Text(
                                    '📦',
                                    style: TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                            )
                          : const Center(
                              child: Text('📦', style: TextStyle(fontSize: 28)),
                            ),
                    ),
                    Text(
                      pack.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${pack.emoticons.length}개',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (allOwn)
                      Text(
                        '수집',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          minimumSize: const Size(double.infinity, 30),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => _buyPack(context, pack),
                        child: Text(
                          '⭐ ${pack.price}',
                          style: const TextStyle(fontSize: 10),
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

  Widget _individualEmoticonGrid(BuildContext context) {
    final list = _individualEmos();
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
        itemCount: list.length,
        itemBuilder: (context, i) {
          final emo = list[i];
          final own = _emoOwned(emo.id);
          final emoPrice = bundleEmoticonPriceForUser(emo.id, userId);
          return Card(
            color: Colors.white.withValues(alpha: 0.45),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: AdaptiveNetworkOrAssetImage(
                      src: resolveEmoticonImageSrc(
                        remoteImageUrl: emo.imageUrl,
                        emoticonId: emo.id,
                      ),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.sentiment_satisfied),
                    ),
                  ),
                  Text(
                    emo.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (own)
                    Text(
                      '수집',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        minimumSize: const Size(double.infinity, 26),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _buyEmo(context, emo),
                      child: Text(
                        '⭐ $emoPrice',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        t,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _oracleBundleToc(
    BuildContext context,
    List<List<ShopItemRow>> bundles,
  ) {
    return Column(
      children: [
        for (final bundle in bundles)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Material(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  final nFirst = oracleItemIdToCardNumber(bundle.first.id);
                  final nLast = oracleItemIdToCardNumber(bundle.last.id);
                  final label = nFirst != null && nLast != null
                      ? '오라클 카드 #$nFirst – #$nLast'
                      : bundle.first.name;
                  final ownedOracleIds = ownedItems
                      .where((e) => e.itemType == 'oracle_card')
                      .map((e) => e.itemId)
                      .toSet();
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => OracleShopBundleScreen(
                        title: label,
                        items: bundle,
                        initiallyOwnedIds: ownedOracleIds,
                        onBuy: _buy,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Text('🔮', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Builder(
                          builder: (ctx) {
                            final nFirst = oracleItemIdToCardNumber(
                              bundle.first.id,
                            );
                            final nLast = oracleItemIdToCardNumber(
                              bundle.last.id,
                            );
                            final title = nFirst != null && nLast != null
                                ? '오라클 #$nFirst – #$nLast'
                                : '${bundle.length}장 묶음';
                            final ownedInBundle = bundle
                                .where((e) => _shopItemOwned(e))
                                .length;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(ctx).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '수집 $ownedInBundle/${bundle.length} · 탭하면 카드 ${bundle.length}장',
                                  style: Theme.of(ctx).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _itemGrid(BuildContext context, List<ShopItemRow> items) {
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
          final item = items[i];
          final owned = _shopItemOwned(item);
          final thumb = resolveShopItemThumbnailSrc(
            item.thumbnailUrl,
            AppConfig.assetOrigin,
          );
          return AppearAnimation(
            delay: Duration(milliseconds: 24 * i.clamp(0, 12)),
            duration: const Duration(milliseconds: 340),
            child: Card(
              color: Colors.white.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
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
                          child: thumb != null
                              ? AdaptiveNetworkOrAssetImage(
                                  src: thumb,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _fallbackDeck(item.type),
                                )
                              : _fallbackDeck(item.type),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (owned)
                      Text(
                        '수집',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (item.price == 0)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          minimumSize: const Size(double.infinity, 34),
                        ),
                        onPressed: () => _buy(context, item),
                        child: const Text('무료', style: TextStyle(fontSize: 11)),
                      )
                    else
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentPurple,
                          minimumSize: const Size(double.infinity, 34),
                        ),
                        onPressed: () => _buy(context, item),
                        child: Text(
                          '⭐ ${item.price}',
                          style: const TextStyle(fontSize: 11),
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

List<ShopItemRow> _sortOracleShopItems(List<ShopItemRow> oracles) {
  final copy = List<ShopItemRow>.from(oracles);
  copy.sort((a, b) {
    final na = oracleItemIdToCardNumber(a.id) ?? 9999;
    final nb = oracleItemIdToCardNumber(b.id) ?? 9999;
    return na.compareTo(nb);
  });
  return copy;
}

List<List<ShopItemRow>> _chunkOracleShopItems(List<ShopItemRow> sorted) {
  if (sorted.isEmpty) {
    return [];
  }
  final out = <List<ShopItemRow>>[];
  for (var i = 0; i < sorted.length; i += _kOracleShopBundleSize) {
    final end = (i + _kOracleShopBundleSize > sorted.length)
        ? sorted.length
        : i + _kOracleShopBundleSize;
    out.add(sorted.sublist(i, end));
  }
  return out;
}
