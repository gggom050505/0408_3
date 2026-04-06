import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';

Future<void> showResultModal(
  BuildContext context, {
  required String cardName,
  required String meaning,
  required String advice,
  /// 앞면 PNG (네트워크 URL 또는 `assets/...`). 없으면 기존처럼 이모지만 표시.
  String? cardImageSrc,
}) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) {
      Future<void> copyReading() async {
        final text =
            '🔮 $cardName\n\n✨ 카드의 의미\n$meaning\n\n💌 오늘의 조언\n$advice';
        await Clipboard.setData(ClipboardData(text: text));
        if (!ctx.mounted) {
          return;
        }
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('클립보드에 복사되었습니다!')),
        );
      }

      void closeModal() => Navigator.pop(ctx);

      final imgSrc = cardImageSrc?.trim() ?? '';
      final hasCardImg = imgSrc.isNotEmpty;
      final sz = MediaQuery.sizeOf(ctx);
      final maxH = sz.height * 0.88;
      final maxW = sz.width - 40;
      // 타로 보드와 같이 가로 3칸 기준 1칸 너비 → 해석창 이미지는 2×2칸(가로 2칸·세로 2칸).
      final contentW = maxW - 36;
      final slotW = (contentW / 3).clamp(56.0, 200.0);
      final slotH = slotW * 116 / 80;
      var cardPreviewW = slotW * 2;
      var cardPreviewH = slotH * 2;
      if (cardPreviewH > maxH * 0.48) {
        final s = (maxH * 0.48) / cardPreviewH;
        cardPreviewH *= s;
        cardPreviewW *= s;
      }

      Widget actionRow() {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: closeModal,
                child: const Text('닫기'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: copyReading,
                child: const Text('복사'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                ),
                onPressed: () async {
                  final text =
                      '🔮 $cardName\n\n✨ 카드의 의미\n$meaning\n\n💌 오늘의 조언\n$advice';
                  await Share.share(text);
                },
                child: const Text('공유'),
              ),
            ),
          ],
        );
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: SizedBox(
          width: maxW,
          height: maxH,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F5E9), Color(0xFFD4E8DC)],
              ),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.cardBorder.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: closeModal,
                      icon: const Icon(Icons.close_rounded, size: 22),
                      label: const Text('닫기'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasCardImg) ...[
                          Center(
                            child: SizedBox(
                              width: cardPreviewW,
                              height: cardPreviewH,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.42),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.cardBorder.withValues(alpha: 0.35),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                alignment: Alignment.center,
                                child: AdaptiveNetworkOrAssetImage(
                                  src: imgSrc,
                                  fit: BoxFit.contain,
                                  width: cardPreviewW,
                                  height: cardPreviewH,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.auto_awesome,
                                    size: 40,
                                    color:
                                        AppColors.accentPurple.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ] else ...[
                          const Center(child: Text('🔮', style: TextStyle(fontSize: 36))),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          cardName,
                          textAlign: TextAlign.center,
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('✨ 카드의 의미',
                              style: Theme.of(ctx).textTheme.titleSmall),
                        ),
                        const SizedBox(height: 6),
                        Text(meaning,
                            style: Theme.of(ctx)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.35)),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('💌 오늘의 조언',
                              style: Theme.of(ctx).textTheme.titleSmall),
                        ),
                        const SizedBox(height: 6),
                        Text(advice,
                            style: Theme.of(ctx)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.35)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                actionRow(),
              ],
            ),
          ),
        ),
      );
    },
  );
}
