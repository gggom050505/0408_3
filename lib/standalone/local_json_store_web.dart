import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> loadLocalJsonFile(String name) async {
  final sp = await SharedPreferences.getInstance();
  return sp.getString('gggom_standalone_$name');
}

Future<void> saveLocalJsonFile(String name, String data) async {
  final sp = await SharedPreferences.getInstance();
  final key = 'gggom_standalone_$name';
  try {
    final ok = await sp.setString(key, data);
    if (!ok) {
      debugPrint(
        'saveLocalJsonFile: SharedPreferences.setString 실패 ($name, ${data.length}자). '
        '브라우저 할당량 초과일 수 있어요. 게시물 이미지를 줄이거나 항목을 정리해 보세요.',
      );
    }
  } catch (e, st) {
    debugPrint('saveLocalJsonFile 예외 ($name): $e\n$st');
  }
}
