import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'gggom_project_paths_io.dart';

/// `saveLocalJsonFile` 직후 호출: `assets/local_dev_state/<name>` 에 동일 내용 저장.
Future<void> mirrorLocalJsonAfterSave(String name, String data) async {
  if (!allowGggomWorkspaceMirrorSync()) {
    return;
  }
  final root = resolveGggomProjectRootSync();
  if (root == null) {
    return;
  }
  try {
    if (name.contains('/') || name.contains('\\') || name.contains('..')) {
      return;
    }
    final dir = Directory(p.join(root, 'assets', 'local_dev_state'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await File(p.join(dir.path, name)).writeAsString(data);
  } catch (_) {}
}

/// 기기 `gggom_standalone` 의 모든 `.json` 을 프로젝트로 다시 복사합니다.
Future<int> syncAllGggomJsonFromAppSupportToWorkspace() async {
  if (!allowGggomWorkspaceMirrorSync()) {
    return 0;
  }
  final root = resolveGggomProjectRootSync();
  if (root == null) {
    return 0;
  }
  try {
    final support = await getApplicationSupportDirectory();
    final srcDir = Directory(p.join(support.path, 'gggom_standalone'));
    if (!await srcDir.exists()) {
      return 0;
    }
    final destDir = Directory(p.join(root, 'assets', 'local_dev_state'));
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    var n = 0;
    await for (final e in srcDir.list(recursive: false)) {
      if (e is! File) {
        continue;
      }
      final base = p.basename(e.path);
      if (!base.endsWith('.json')) {
        continue;
      }
      if (base.contains('..')) {
        continue;
      }
      await File(p.join(destDir.path, base)).writeAsString(await e.readAsString());
      n++;
    }
    return n;
  } catch (_) {
    return 0;
  }
}
