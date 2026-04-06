import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

/// `--dart-define=GGGOM_PROJECT_ROOT=...` 또는 `SHOP_CATALOG_REPO_ROOT=...`
/// 비우면 작업 디렉터리에 `pubspec.yaml`이 있을 때 그 폴더를 프로젝트 루트로 씁니다.
String? resolveGggomProjectRootSync() {
  const rootA = String.fromEnvironment('GGGOM_PROJECT_ROOT', defaultValue: '');
  if (rootA.isNotEmpty) {
    final d = Directory(rootA);
    if (d.existsSync()) {
      return d.path;
    }
  }
  const rootB = String.fromEnvironment('SHOP_CATALOG_REPO_ROOT', defaultValue: '');
  if (rootB.isNotEmpty) {
    final d = Directory(rootB);
    if (d.existsSync()) {
      return d.path;
    }
  }
  final cwd = Directory.current.path;
  if (File(p.join(cwd, 'pubspec.yaml')).existsSync()) {
    return cwd;
  }
  return null;
}

bool _isFlutterWidgetTestBinding() {
  try {
    final name = WidgetsBinding.instance.runtimeType.toString();
    return name.contains('TestWidgetsFlutterBinding');
  } catch (_) {
    return false;
  }
}

/// 단위·위젯 테스트에서 저장소 오염 방지. 필요 시 `GGGOM_DISABLE_WORKSPACE_MIRROR=1`.
///
/// 비동기 연속(예: 저장 버튼 [Future] 이후)에서는 스택에 `package:flutter_test/` 가
/// 남지 않을 수 있어, [WidgetsBinding] 타입으로 위젯 테스트도 함께 판별합니다.
bool allowGggomWorkspaceMirrorSync() {
  if (Platform.environment['GGGOM_DISABLE_WORKSPACE_MIRROR'] == '1') {
    return false;
  }
  if (_isFlutterWidgetTestBinding()) {
    return false;
  }
  final s = StackTrace.current.toString();
  if (s.contains('package:flutter_test/')) {
    return false;
  }
  if (s.contains('package:test_api/') || s.contains('package:test/')) {
    return false;
  }
  return true;
}
