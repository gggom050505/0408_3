import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// 한국 날짜(UTC+9) 기준 «오늘» 방문자 수 — Supabase RPC [gggom_register_daily_visitor_and_count] 필요.
///
/// 클라이언트마다 [SharedPreferences]에 저장한 익명 ID로 하루 1회만 카운트에 반영됩니다.
class DailyVisitorCounter {
  DailyVisitorCounter._();

  static final DailyVisitorCounter instance = DailyVisitorCounter._();

  static const _prefsKey = 'gggom_visitor_client_id_v1';
  static const _prefsLocalDateKey = 'gggom_local_visitor_date_v1';
  static const _prefsLocalCountKey = 'gggom_local_visitor_count_v1';

  /// 한국 표준시 기준 `YYYY-MM-DD`.
  static String koreaDateKeyNow() {
    final korea = DateTime.now().toUtc().add(const Duration(hours: 9));
    return '${korea.year}-'
        '${korea.month.toString().padLeft(2, '0')}-'
        '${korea.day.toString().padLeft(2, '0')}';
  }

  Future<String> _ensureClientId() async {
    final p = await SharedPreferences.getInstance();
    var id = p.getString(_prefsKey);
    if (id == null || id.isEmpty) {
      const hex = '0123456789abcdef';
      final r = Random.secure();
      id = List.generate(16, (_) {
        final b = r.nextInt(256);
        return '${hex[b >> 4]}${hex[b & 0xf]}';
      }).join();
      await p.setString(_prefsKey, id);
    }
    return id;
  }

  static int? _parseCount(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  /// Supabase 없이도 동작하는 로컬 폴백 카운트.
  /// 같은 기기에서 앱을 다시 열 때마다 오늘 카운트를 +1 합니다.
  Future<int> _registerAndFetchLocalCount() async {
    final p = await SharedPreferences.getInstance();
    final today = koreaDateKeyNow();
    final savedDay = p.getString(_prefsLocalDateKey) ?? '';
    var count = p.getInt(_prefsLocalCountKey) ?? 0;
    if (savedDay != today) {
      count = 1;
    } else {
      count += 1;
    }
    await p.setString(_prefsLocalDateKey, today);
    await p.setInt(_prefsLocalCountKey, count);
    return count;
  }

  /// 오늘 첫 진입 시 행을 넣고, 같은 날짜의 고유 [client_id] 수를 반환. 실패 시 `null`.
  Future<int?> registerAndFetchTodayCount() async {
    if (AppConfig.supabaseEnabled) {
      try {
        final cid = await _ensureClientId();
        final dateKey = koreaDateKeyNow();
        final raw = await Supabase.instance.client.rpc(
          'gggom_register_daily_visitor_and_count',
          params: <String, dynamic>{
            'p_visit_date': dateKey,
            'p_client_id': cid,
          },
        );
        final parsed = _parseCount(raw);
        if (parsed != null) {
          return parsed;
        }
      } catch (_) {}
    }
    return _registerAndFetchLocalCount();
  }
}
