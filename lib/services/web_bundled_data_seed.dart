import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;

import '../standalone/local_json_store.dart';

/// 웹 배포 시 `web/bundled_data/` 에 넣은 JSON 을, 방문자 로컬(SharedPreferences)에 **없을 때만** 채웁니다.
/// 기존 사용자 데이터는 덮어쓰지 않습니다.
Future<void> maybeSeedWebBundledData() async {
  if (!kIsWeb) {
    return;
  }
  try {
    final base = Uri.base;
    final manifestUri = base.resolve('bundled_data/manifest.json');
    final manifestRes = await http.get(manifestUri).timeout(const Duration(seconds: 12));
    if (manifestRes.statusCode == 200 && manifestRes.body.isNotEmpty) {
      var manifestBody = manifestRes.body;
      if (manifestBody.startsWith('\uFEFF')) {
        manifestBody = manifestBody.substring(1);
      }
      final decoded = jsonDecode(manifestBody);
      if (decoded is List) {
        for (final e in decoded) {
          if (e is String && e.isNotEmpty) {
            await _seedFileIfMissing(e);
          }
        }
        return;
      }
      if (decoded is String && decoded.isNotEmpty) {
        await _seedFileIfMissing(decoded);
        return;
      }
    }
    await _seedFileIfMissing('local_peer_shop_listings_v1.json');
    await _seedFileIfMissing('local_feed_v1.json');
  } catch (e, st) {
    debugPrint('maybeSeedWebBundledData: $e\n$st');
  }
}

Future<void> _seedFileIfMissing(String name) async {
  final existing = await loadLocalJsonFile(name);
  if (existing != null && existing.trim().isNotEmpty) {
    return;
  }
  try {
    final uri = Uri.base.resolve('bundled_data/$name');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200 || res.body.trim().isEmpty) {
      return;
    }
    await saveLocalJsonFile(name, res.body);
  } catch (e, st) {
    debugPrint('web seed skip $name: $e\n$st');
  }
}
