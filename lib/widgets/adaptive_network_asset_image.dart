import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

bool looksLikeNetworkImageUrl(String src) =>
    src.startsWith('http://') || src.startsWith('https://');

bool _looksLikeFileUri(String src) => src.startsWith('file://');

bool _looksLikeDataImageUri(String src) =>
    src.startsWith('data:image/') && src.contains(',');

/// `http(s)://` 는 네트워크, `data:image/...;base64,...` 는 메모리 디코딩,
/// `file://`(비웹)는 파일, 그 외는 [Image.asset].
class AdaptiveNetworkOrAssetImage extends StatelessWidget {
  const AdaptiveNetworkOrAssetImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (looksLikeNetworkImageUrl(src)) {
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }
    if (_looksLikeDataImageUri(src)) {
      try {
        final comma = src.indexOf(',');
        final b64 = src.substring(comma + 1);
        final bytes = base64Decode(b64);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder,
        );
      } catch (_) {}
    }
    if (!kIsWeb && _looksLikeFileUri(src)) {
      try {
        final path = Uri.parse(src).toFilePath();
        return Image.file(
          File(path),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder,
        );
      } catch (_) {}
    }
    return Image.asset(
      src,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }
}
