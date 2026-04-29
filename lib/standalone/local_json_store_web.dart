import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> loadLocalJsonFile(String name) async {
  final sp = await SharedPreferences.getInstance();
  final key = 'gggom_standalone_$name';
  final raw = sp.getString(key);
  if (raw != null && raw.isNotEmpty) {
    return raw;
  }
  return sp.getString('gggom_standalone_backup_$name');
}

Future<void> saveLocalJsonFile(String name, String data) async {
  final sp = await SharedPreferences.getInstance();
  final key = 'gggom_standalone_$name';
  final backupKey = 'gggom_standalone_backup_$name';
  var wrotePrimary = false;
  var wroteBackup = false;
  try {
    wrotePrimary = await sp.setString(key, data);
    if (!wrotePrimary) {
      debugPrint(
        'saveLocalJsonFile: SharedPreferences.setString 실패 ($name, ${data.length}자). '
        '브라우저 할당량 초과일 수 있어요. 게시물 이미지를 줄이거나 항목을 정리해 보세요.',
      );
    }
  } catch (e, st) {
    debugPrint('saveLocalJsonFile 예외 ($name): $e\n$st');
  }
  try {
    wroteBackup = await sp.setString(backupKey, data);
    if (!wroteBackup && wrotePrimary) {
      debugPrint('saveLocalJsonFile: 백업 저장 실패 ($name).');
    }
  } catch (e, st) {
    debugPrint('saveLocalJsonFile 백업 예외 ($name): $e\n$st');
  }
  // 둘 다 실패하면 피드 등 로컬 상태가 디스크에 안 남음 → 호출부에서 재시도·안내 가능하게 예외.
  if (!wrotePrimary && !wroteBackup) {
    throw StateError(
      '브라우저 저장 공간 부족 또는 저장 차단으로 데이터를 쓸 수 없습니다. '
      '사용하지 않는 게시를 지우거나, 창 내 저장 허용을 확인해 주세요.',
    );
  }
}

Future<void> removeLocalJsonFile(String name) async {
  final sp = await SharedPreferences.getInstance();
  try {
    await sp.remove('gggom_standalone_$name');
  } catch (e, st) {
    debugPrint('removeLocalJsonFile 예외 ($name): $e\n$st');
  }
  try {
    await sp.remove('gggom_standalone_backup_$name');
  } catch (e, st) {
    debugPrint('removeLocalJsonFile 백업 예외 ($name): $e\n$st');
  }
}
