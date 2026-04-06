import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/card_themes.dart' show resolveShopItemThumbnailSrc;
import '../models/shop_models.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';

/// 상점에서 오라클 카드 10장 묶음 상세(구매 그리드).
class OracleShopBundleScreen extends StatefulWidget {
  const OracleShopBundleScreen({
    super.key,
    required this.title,
    required this.items,
    required this.initiallyOwnedIds,
    required this.onBuy,
  });

  final String title;
  final List<ShopItemRow> items;
  final Set<String> initiallyOwnedIds;
  final Future<bool> Function(BuildContext context, ShopItemRow item) onBuy;

  @override
  State<OracleShopBundleScreen> createState() => _OracleShopBundleScreenState();
}

class _OracleShopBundleScreenState extends State<OracleShopBundleScreen> {
  late Set<String> _justBought;

  @override
  void initState() {
    super.initState();
    _justBought = {};
  }

  bool _isOwned(String itemId) =>
      widget.initiallyOwnedIds.contains(itemId) || _justBought.contains(itemId);

  Future<void> _tapBuy(BuildContext context, ShopItemRow item) async {
    final ok = await widget.onBuy(context, item);
    if (mounted && ok) {
      setState(() => _justBought.add(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.bgMain,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 128,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.items.length,
            itemBuilder: (context, i) {
              final item = widget.items[i];
              final owned = _isOwned(item.id);
              final thumb =
                  resolveShopItemThumbnailSrc(item.thumbnailUrl, AppConfig.assetOrigin);
              return Card(
                color: Colors.white.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: thumb != null
                              ? AdaptiveNetworkOrAssetImage(
                                  src: thumb,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _fallbackOracle(),
                                )
                              : _fallbackOracle(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.name.replaceFirst('오라클 카드 #', '#'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                      ),
                      const SizedBox(height: 2),
                      if (owned)
                        Text(
                          '보유',
                          style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                        )
                      else if (item.price == 0)
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentPurple,
                            minimumSize: const Size(double.infinity, 26),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => _tapBuy(context, item),
                          child: const Text('무료', style: TextStyle(fontSize: 9)),
                        )
                      else
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentPurple,
                            minimumSize: const Size(double.infinity, 26),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => _tapBuy(context, item),
                          child: Text('⭐ ${item.price}', style: const TextStyle(fontSize: 9)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _fallbackOracle() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.cardInner, Color(0xFF98BFAA)],
        ),
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('🔮', style: TextStyle(fontSize: 28)),
    );
  }
}
