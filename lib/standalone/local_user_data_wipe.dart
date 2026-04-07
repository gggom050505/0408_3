import 'dart:convert';

import 'local_app_preferences.dart';
import 'local_json_store.dart';
import 'local_peer_shop_repository.dart';

/// 파일명용 — [LocalShopRepository] 등과 동일 규칙.
String safeStandaloneUserFileId(String id) =>
    id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

/// 로컬 앱 사용자(`local-acc-…`)가 탈퇴·삭제할 때 이 [userId]에 묶인 기기 JSON·설정을 지웁니다.
/// (공유 카탈로그 `local_shop_catalog_v1.json` 은 건드리지 않습니다.)
Future<void> wipeStandaloneArtifactsForAppUserId(String userId) async {
  final su = safeStandaloneUserFileId(userId);
  final files = <String>[
    'local_shop_user_state_v1_$su.json',
    'local_star_one_purchase_v1_$su.json',
    'local_star_two_purchase_v1_$su.json',
    'local_surprise_gift_v1_$su.json',
    'local_attendance_lucky_v1_$su.json',
    'local_tarot_session_v1_$su.json',
    'local_chat_${su}_v1.json',
  ];
  for (final f in files) {
    await removeLocalJsonFile(f);
  }
  await LocalPeerShopRepository.instance.removeListingsForSeller(userId);
  await _stripAttendanceForUser(userId);
  await LocalAppPreferences.removePerUserEntries(userId);
}

Future<void> _stripAttendanceForUser(String userId) async {
  const file = 'local_attendance_v1.json';
  try {
    final raw = await loadLocalJsonFile(file);
    if (raw == null || raw.isEmpty) {
      return;
    }
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if ((map['version'] as num?)?.toInt() != 1) {
      return;
    }
    final by = map['by_user'];
    if (by is! Map) {
      return;
    }
    final next = Map<String, dynamic>.from(
      by.map((k, v) => MapEntry(k.toString(), v)),
    );
    next.remove(userId);
    map['by_user'] = next;
    await saveLocalJsonFile(file, jsonEncode(map));
  } catch (_) {}
}
