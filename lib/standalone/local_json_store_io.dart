import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'local_json_workspace_mirror_io.dart';

Future<String?> loadLocalJsonFile(String name) async {
  final dir = await getApplicationSupportDirectory();
  final sub = Directory(p.join(dir.path, 'gggom_standalone'));
  final file = File(p.join(sub.path, name));
  if (await file.exists()) {
    try {
      return await file.readAsString();
    } catch (_) {}
  }
  final bak = File(p.join(sub.path, '_backup_$name'));
  if (!await bak.exists()) {
    return null;
  }
  try {
    return await bak.readAsString();
  } catch (_) {
    return null;
  }
}

Future<void> saveLocalJsonFile(String name, String data) async {
  final dir = await getApplicationSupportDirectory();
  final sub = Directory(p.join(dir.path, 'gggom_standalone'));
  if (!await sub.exists()) {
    await sub.create(recursive: true);
  }
  final file = File(p.join(sub.path, name));
  await file.writeAsString(data);
  try {
    final bak = File(p.join(sub.path, '_backup_$name'));
    await bak.writeAsString(data);
  } catch (_) {}
  await mirrorLocalJsonAfterSave(name, data);
}

/// [loadLocalJsonFile] 과 동일한 경로의 파일을 삭제합니다. 없으면 무시합니다.
Future<void> removeLocalJsonFile(String name) async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'gggom_standalone', name));
  final bak = File(p.join(dir.path, 'gggom_standalone', '_backup_$name'));
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {}
  try {
    if (await bak.exists()) {
      await bak.delete();
    }
  } catch (_) {}
}
