import 'dart:convert';

import '../config/shop_random_prices.dart';
import 'local_json_store.dart';

String _safeUserId(String id) => id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

String _starOneFile(String userId) => 'local_star_one_purchase_v1_${_safeUserId(userId)}.json';

/// ⭐1 일일 1건 제한 — 로컬 JSON.
Future<String?> loadStarOneDailyPurchaseYmd(String userId) async {
  final raw = await loadLocalJsonFile(_starOneFile(userId));
  if (raw == null || raw.isEmpty) {
    return null;
  }
  try {
    final m = jsonDecode(raw);
    if (m is Map && m['utc_ymd'] is String) {
      return (m['utc_ymd'] as String).trim();
    }
  } catch (_) {}
  return null;
}

Future<void> recordStarOneDailyPurchaseYmd(String userId) async {
  final ymd = gggomTodayUtcYmdKey();
  await saveLocalJsonFile(_starOneFile(userId), jsonEncode({'utc_ymd': ymd}));
}

String _starTwoFile(String userId) => 'local_star_two_purchase_v1_${_safeUserId(userId)}.json';

/// 온라인: ⭐2 일일 건수 `{ utc_ymd, count }`.
Future<({String? ymd, int count})> loadStarTwoDailyState(String userId) async {
  final raw = await loadLocalJsonFile(_starTwoFile(userId));
  if (raw == null || raw.isEmpty) {
    return (ymd: null, count: 0);
  }
  try {
    final m = jsonDecode(raw);
    if (m is Map) {
      final y = m['utc_ymd'];
      final c = (m['count'] as num?)?.toInt() ?? 0;
      if (y is String && y.trim().isNotEmpty) {
        return (ymd: y.trim(), count: c);
      }
    }
  } catch (_) {}
  return (ymd: null, count: 0);
}

Future<void> saveStarTwoDailyState(String userId, String ymd, int count) async {
  await saveLocalJsonFile(
    _starTwoFile(userId),
    jsonEncode({'utc_ymd': ymd, 'count': count}),
  );
}
