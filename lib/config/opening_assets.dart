import 'dart:convert';

import 'package:flutter/services.dart';

const String kOpeningAssetDirPrefix = 'assets/opening/';

/// 번들된 `assets/opening/` 아래 이미지 경로를 이름순으로 반환합니다.
Future<List<String>> loadOpeningImageAssetPaths() async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final out = manifest
        .listAssets()
        .where((k) => k.startsWith(kOpeningAssetDirPrefix))
        .where(
          (k) => RegExp(
            r'\.(png|jpg|jpeg|webp|gif)$',
            caseSensitive: false,
          ).hasMatch(k),
        )
        .toList()
      ..sort();
    return out;
  } catch (_) {
    try {
      final raw = await rootBundle.loadString('AssetManifest.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final out = map.keys
          .whereType<String>()
          .where((k) => k.startsWith(kOpeningAssetDirPrefix))
          .where(
            (k) => RegExp(
              r'\.(png|jpg|jpeg|webp|gif)$',
              caseSensitive: false,
            ).hasMatch(k),
          )
          .toList()
        ..sort();
      return out;
    } catch (_) {
      return const [];
    }
  }
}
