import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/card_themes.dart'
    show resolvePublicAssetUrl, resolveShopItemThumbnailSrc;
import '../data/oracle_assets.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';

/// 가방·수집 화면용 오라클 카드 1장.
class OracleCollectionEntry {
  const OracleCollectionEntry({
    required this.id,
    required this.name,
    required this.imageSrc,
  });

  final String id;
  final String name;
  final String imageSrc;
}

String resolveOracleCollectionImageSrc({
  required String itemId,
  String? shopThumbnailUrl,
}) {
  final fromShop = resolveShopItemThumbnailSrc(
    shopThumbnailUrl,
    AppConfig.assetOrigin,
  );
  if (fromShop != null && fromShop.isNotEmpty) {
    return fromShop;
  }
  final n = oracleItemIdToCardNumber(itemId);
  final path = n != null ? bundledOracleAssetPath(n) : null;
  final fallback = path ?? 'assets/oracle/oracle(1).png';
  return resolvePublicAssetUrl(fallback, AppConfig.assetOrigin) ?? fallback;
}

/// 가방·오라클 수집 등에서 카드 이미지를 크게 보기 (닫기·핀치 줌).
Future<void> showOwnedCardImagePreviewDialog(
  BuildContext context, {
  required String title,
  required String imageSrc,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (ctx) {
      final mq = MediaQuery.sizeOf(ctx);
      return Dialog(
        backgroundColor: const Color(0xFF242424),
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: SizedBox(
          width: mq.width - 28,
          height: mq.height * 0.86,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: '닫기',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: InteractiveViewer(
                        minScale: 0.6,
                        maxScale: 4,
                        child: Center(
                          child: AdaptiveNetworkOrAssetImage(
                            src: imageSrc,
                            fit: BoxFit.contain,
                            width: c.maxWidth,
                            height: c.maxHeight,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                title.contains('한국') ? '🇰🇷' : '🔮',
                                style: const TextStyle(fontSize: 56),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 수집한 오라클 카드 전체를 그리드로 보는 화면.
class OracleCollectionScreen extends StatelessWidget {
  const OracleCollectionScreen({
    super.key,
    required this.entries,
    required this.ownedCount,
    required this.totalCount,
  });

  final List<OracleCollectionEntry> entries;
  final int ownedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        title: const Text('오라클 카드'),
        backgroundColor: AppColors.bgMain,
        surfaceTintColor: Colors.transparent,
      ),
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '아직 수집한 오라클 카드가 없어요.\n출석 이벤트·상점에서 모을 수 있어요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    '보유 $ownedCount / $totalCount',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final label = e.name.replaceFirst('오라클 카드 #', '#');
                      return Card(
                        color: Colors.white.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => unawaited(
                            showOwnedCardImagePreviewDialog(
                              context,
                              title: e.name,
                              imageSrc: e.imageSrc,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: AdaptiveNetworkOrAssetImage(
                                      src: e.imageSrc,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        alignment: Alignment.center,
                                        color: AppColors.cardInner,
                                        child: const Text(
                                          '🔮',
                                          style: TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
