import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'app_config.dart';

const String kOpeningAssetDirPrefix = 'assets/opening/';

/// 오프닝 정적 이미지(표시 순서). 파일명에 `()`가 있어 매니페스트만으로 순서가 흔들릴 수 있어 명시합니다.
const List<String> kOpeningBundledPreferredOrder = [
  'assets/opening/open(1).png',
  'assets/opening/open(2).png',
  'assets/opening/open(3).png',
];

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

Future<List<String>> _discoverOpeningPathsFromManifest() async {
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

/// [kOpeningBundledPreferredOrder] 에 있고 매니페스트에 실제로 포함된 경로만 순서대로 반환.
/// 비어 있으면 매니페스트 자동 목록(정렬)로 폴백.
Future<List<String>> _loadBundledOpeningAssetPaths() async {
  final discovered = await _discoverOpeningPathsFromManifest();
  final set = discovered.toSet();
  final ordered = <String>[];
  for (final p in kOpeningBundledPreferredOrder) {
    if (set.contains(p)) {
      ordered.add(p);
    }
  }
  if (ordered.isNotEmpty) {
    return ordered;
  }
  return discovered;
}

Future<List<String>> _loadOnlineOpeningImageUrls(List<String> localPaths) async {
  final origin = AppConfig.assetOrigin.trim();
  if (origin.isEmpty || localPaths.isEmpty) {
    return const [];
  }
  const rootCandidates = <String>[
    '/assets/assets/opening', // flutter web 기본 배포 경로
    '/assets/opening', // CDN/커스텀 동기화 경로
  ];
  final resolved = <String>[];
  for (final local in localPaths) {
    final filename = p.basename(local);
    final encodedName = Uri.encodeComponent(filename);
    var foundUrl = '';
    for (final root in rootCandidates) {
      final url = _joinUrl(origin, '$root/$encodedName');
      if (await _urlExists(url)) {
        foundUrl = url;
        break;
      }
    }
    if (foundUrl.isEmpty) {
      // 하나라도 온라인 경로가 없으면 전체를 번들 에셋으로 폴백한다.
      return const [];
    }
    resolved.add(foundUrl);
  }
  return resolved;
}

/// 오프닝 이미지는 온라인 URL을 우선 사용하고, 없으면 번들 `assets/opening/`를 씁니다.
Future<List<String>> loadOpeningImageAssetPaths() async {
  final localPaths = await _loadBundledOpeningAssetPaths();
  final online = await _loadOnlineOpeningImageUrls(localPaths);
  if (online.isNotEmpty) {
    return online;
  }
  return localPaths;
}
