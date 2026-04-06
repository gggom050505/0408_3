import 'dart:io';

import 'package:path/path.dart' as p;

import 'gggom_project_paths_io.dart';

/// 기기 데이터가 없을 때: 프로젝트에 미러된 카탈로그를 읽습니다.
Future<String?> tryReadShopCatalogFromWorkspace() async {
  final root = resolveGggomProjectRootSync();
  if (root == null) {
    return null;
  }
  final candidates = [
    File(p.join(root, 'assets', 'local_dev_state', 'local_shop_catalog_v1.json')),
    File(p.join(root, 'assets', 'data', 'local_shop_catalog_v1.json')),
  ];
  for (final file in candidates) {
    try {
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
  }
  return null;
}
