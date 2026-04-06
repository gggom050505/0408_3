import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'local_json_workspace_mirror_io.dart';

Future<String?> loadLocalJsonFile(String name) async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'gggom_standalone', name));
  if (!await file.exists()) {
    return null;
  }
  return file.readAsString();
}

Future<void> saveLocalJsonFile(String name, String data) async {
  final dir = await getApplicationSupportDirectory();
  final sub = Directory(p.join(dir.path, 'gggom_standalone'));
  if (!await sub.exists()) {
    await sub.create(recursive: true);
  }
  final file = File(p.join(sub.path, name));
  await file.writeAsString(data);
  await mirrorLocalJsonAfterSave(name, data);
}
