import 'dart:convert';

import 'data_sources.dart';
import 'local_json_store.dart';

String _todayKey() {
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// 오프라인·베타 번들 출석 — 사용자별 마지막 출석일을 [local_attendance_v1.json]에 저장·복원.
class LocalAttendanceRepository implements AttendanceDataSource {
  static const _file = 'local_attendance_v1.json';

  final _checked = <String, String>{};
  var _ready = false;

  Future<void> _ensureLoaded() async {
    if (_ready) {
      return;
    }
    try {
      final raw = await loadLocalJsonFile(_file);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        if ((map['version'] as num?)?.toInt() == 1) {
          final by = map['by_user'];
          if (by is Map) {
            for (final e in by.entries) {
              _checked[e.key.toString()] = e.value.toString();
            }
          }
        }
      }
    } catch (_) {}
    _ready = true;
  }

  Future<void> _persist() async {
    await saveLocalJsonFile(
      _file,
      jsonEncode({
        'version': 1,
        'by_user': _checked,
      }),
    );
  }

  @override
  Future<bool> checkToday(String userId) async {
    await _ensureLoaded();
    return _checked[userId] == _todayKey();
  }

  @override
  Future<Set<int>> fetchCheckedInDaysOfMonth(
    String userId, {
    required int year,
    required int month,
  }) async {
    await _ensureLoaded();
    final iso = _checked[userId];
    if (iso == null || iso.isEmpty) {
      return <int>{};
    }
    final d = DateTime.tryParse(iso);
    if (d == null || d.year != year || d.month != month) {
      return <int>{};
    }
    return <int>{d.day};
  }

  @override
  Future<Map<String, dynamic>?> doCheckIn(String userId) async {
    await _ensureLoaded();
    final k = _todayKey();
    if (_checked[userId] == k) {
      return {'already': true};
    }
    _checked[userId] = k;
    await _persist();
    return {
      'already': false,
      'reward_kind': 'attendance_star',
      'emoticon_image': null,
      'emoticon_name': null,
    };
  }
}
