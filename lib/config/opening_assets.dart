import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'app_config.dart';

const String kOpeningAssetDirPrefix = 'assets/opening/';

Future<bool> _urlExists(String url) async {
  try {
    final res = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 4),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (_) {
    return false;
  }
}

String _joinUrl(String origin, String path) {
  final o = origin.replaceAll(RegExp(r'/$'), '');
  final p = path.startsWith('/') ? path : '/$path';
  return '$o$p';
}

List<String> _openingNameCandidates(int index) {
  return [
    'open_$index.png',
    'open($index).png',
    'open$index.png',
    'Opening_$index.png',
    'opening_$index.png',
  ];
}

Future<List<String>> _loadOnlineOpeningImageUrls() async {
  final origin = AppConfig.assetOrigin.trim();
  if (origin.isEmpty) {
    return const [];
  }
  const rootCandidates = [
    '/assets/assets/opening/',
    '/assets/opening/',
  ];
  final out = <String>[];
  for (var i = 1; i <= 3; i++) {
    var found = false;
    for (final root in rootCandidates) {
      for (final name in _openingNameCandidates(i)) {
        final url = _joinUrl(origin, '$root$name');
        if (await _urlExists(url)) {
          out.add(url);
          found = true;
          break;
        }
      }
      if (found) {
        break;
      }
    }
  }
  return out;
}

/// 오프닝 이미지는 온라인 URL을 우선 사용하고, 없으면 번들 `assets/opening/`를 씁니다.
Future<List<String>> loadOpeningImageAssetPaths() async {
  final online = await _loadOnlineOpeningImageUrls();
  if (online.isNotEmpty) {
    return online;
  }
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
