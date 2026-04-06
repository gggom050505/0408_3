import 'package:flutter/material.dart';

import 'adaptive_network_asset_image.dart';

/// 피드 게시물의 스프레드 캡처 PNG를 가로 폭에 맞춰 **그대로** 표시합니다.
class FeedPostCapture extends StatelessWidget {
  const FeedPostCapture({
    super.key,
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Align(
          alignment: Alignment.topCenter,
          child: AdaptiveNetworkOrAssetImage(
            src: imageUrl,
            fit: BoxFit.contain,
            width: c.maxWidth,
            errorBuilder: (_, _, _) => Container(
              height: 120,
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        );
      },
    );
  }
}
