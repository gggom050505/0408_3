import 'dart:convert';

import 'local_json_store.dart';

class LocalPeriodicBackup {
  LocalPeriodicBackup._();

  static const _interval = Duration(minutes: 30);

  static String _safeUserId(String userId) =>
      userId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  static String _chatFile(String userId) =>
      'local_chat_${_safeUserId(userId)}_v1.json';
  static String _shopUserStateFile(String userId) =>
      'local_shop_user_state_v1_${_safeUserId(userId)}.json';
  static String _tarotSessionFile(String userId) =>
      'local_tarot_session_v1_${_safeUserId(userId)}.json';
  static String _backupStateFile(String userId) =>
      'local_backup_state_v1_${_safeUserId(userId)}.json';

  static String _backupFileNameUtc(DateTime utcNow) {
    final y = utcNow.year.toString().padLeft(4, '0');
    final mo = utcNow.month.toString().padLeft(2, '0');
    final d = utcNow.day.toString().padLeft(2, '0');
    final h = utcNow.hour.toString().padLeft(2, '0');
    final mi = utcNow.minute.toString().padLeft(2, '0');
    return 'databackup_$y$mo${d}_$h$mi.json';
  }

  static dynamic _tryDecodeJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  /// 4시간이 지난 경우에만 백업을 1회 저장합니다.
  static Future<void> backupIfDue(String userId) async {
    final nowUtc = DateTime.now().toUtc();
    var lastMs = 0;
    try {
      final stateRaw = await loadLocalJsonFile(_backupStateFile(userId));
      if (stateRaw != null && stateRaw.isNotEmpty) {
        final m = jsonDecode(stateRaw) as Map<String, dynamic>;
        lastMs = (m['last_backup_utc_ms'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    if (lastMs > 0) {
      final elapsed = nowUtc.millisecondsSinceEpoch - lastMs;
      if (elapsed < _interval.inMilliseconds) {
        return;
      }
    }
    await backupNow(userId, nowUtc: nowUtc);
  }

  /// 즉시 백업 저장.
  static Future<void> backupNow(String userId, {DateTime? nowUtc}) async {
    final utc = nowUtc ?? DateTime.now().toUtc();
    final backupName = _backupFileNameUtc(utc);

    final feedRaw = await loadLocalJsonFile('local_feed_v1.json');
    final chatRaw = await loadLocalJsonFile(_chatFile(userId));
    final shopRaw = await loadLocalJsonFile(_shopUserStateFile(userId));
    final tarotSessionRaw = await loadLocalJsonFile(_tarotSessionFile(userId));
    final attendanceRaw = await loadLocalJsonFile('local_attendance_v1.json');
    final starDailyRaw = await loadLocalJsonFile(
      'local_star_one_purchase_daily_v1_${_safeUserId(userId)}.json',
    );
    final prefRaw = await loadLocalJsonFile('local_app_preferences_v1.json');
    final peerBoardRaw = await loadLocalJsonFile(
      'local_peer_shop_listings_v1.json',
    );

    final payload = <String, dynamic>{
      'version': 1,
      'created_at_utc': utc.toIso8601String(),
      'user_id': userId,
      'backup_scope': const [
        'feed',
        'today_tarot_feed',
        'chat',
        'tarot_session',
        'shop_user_state',
        'peer_shop_listings',
        'attendance',
        'star_one_purchase_daily',
        'user_settings',
      ],
      'data': {
        'feed': _tryDecodeJson(feedRaw),
        'chat': _tryDecodeJson(chatRaw),
        'tarot_session': _tryDecodeJson(tarotSessionRaw),
        'peer_shop_listings': _tryDecodeJson(peerBoardRaw),
        'shop_user_state': _tryDecodeJson(shopRaw),
        'attendance': _tryDecodeJson(attendanceRaw),
        'star_one_purchase_daily': _tryDecodeJson(starDailyRaw),
        'app_preferences': _tryDecodeJson(prefRaw),
      },
    };

    await saveLocalJsonFile(backupName, jsonEncode(payload));
    await saveLocalJsonFile(
      _backupStateFile(userId),
      jsonEncode({
        'version': 1,
        'last_backup_utc_ms': utc.millisecondsSinceEpoch,
        'latest_backup_file': backupName,
      }),
    );
  }
}
