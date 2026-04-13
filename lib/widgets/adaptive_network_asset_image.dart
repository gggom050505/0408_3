import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/card_themes.dart' show normalizeFlutterBundledAssetKey;

bool looksLikeNetworkImageUrl(String src) =>
    src.startsWith('http://') || src.startsWith('https://');

bool _looksLikeFileUri(String src) => src.startsWith('file://');

bool _looksLikeDataImageUri(String src) =>
    src.startsWith('data:image/') && src.contains(',');

String? _fallbackBundledAssetKeyFromNetworkUrl(String src) {
  if (!looksLikeNetworkImageUrl(src)) {
    return null;
  }
  Uri? uri;
  try {
    uri = Uri.parse(src);
  } catch (_) {
    return null;
  }
  final seg = uri.pathSegments;
  if (seg.isEmpty) {
    return null;
  }
  final assetsIdx = seg.indexOf('assets');
  if (assetsIdx >= 0 && assetsIdx < seg.length - 1) {
    final candidate = 'assets/${seg.sublist(assetsIdx + 1).join('/')}';
    return normalizeFlutterBundledAssetKey(candidate);
  }
  final cardsIdx = seg.indexOf('cards');
  if (cardsIdx >= 0 && cardsIdx < seg.length - 2) {
    final group = seg[cardsIdx + 1];
    final rest = seg.sublist(cardsIdx + 2).join('/');
    if (group == 'minor_number_clay') {
      return normalizeFlutterBundledAssetKey(
        'assets/cards/minor_number_clay/$rest',
      );
    }
    if (group == 'minor_court_clay') {
      return normalizeFlutterBundledAssetKey(
        'assets/cards/minor_court_clay/$rest',
      );
    }
  }
  return null;
}

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
    final resolvedSrc = normalizeFlutterBundledAssetKey(src);
    final fallbackAsset = _fallbackBundledAssetKeyFromNetworkUrl(resolvedSrc);
    if (looksLikeNetworkImageUrl(resolvedSrc)) {
      return Image.network(
        resolvedSrc,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          if (fallbackAsset != null && fallbackAsset.isNotEmpty) {
            return Image.asset(
              fallbackAsset,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: errorBuilder,
            );
          }
          if (errorBuilder != null) {
            return errorBuilder!(context, error, stackTrace);
          }
          return const SizedBox.shrink();
        },
      );
    }
    if (_looksLikeDataImageUri(resolvedSrc)) {
      try {
        final comma = resolvedSrc.indexOf(',');
        final b64 = resolvedSrc.substring(comma + 1);
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
    if (!kIsWeb && _looksLikeFileUri(resolvedSrc)) {
      try {
        final path = Uri.parse(resolvedSrc).toFilePath();
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
      resolvedSrc,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }
}
