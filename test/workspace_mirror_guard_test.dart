import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/standalone/gggom_project_paths_io.dart';
import 'package:gggom_tarot/standalone/local_json_workspace_export.dart';

void main() {
  test('flutter test 실행 시 워크스페이스 미러는 꺼져 있어야 한다', () {
    expect(
      allowGggomWorkspaceMirrorSync(),
      isFalse,
      reason: '단위 테스트가 실제 프로젝트 assets/local_dev_state 를 덮어쓰면 안 됨',
    );
  });

  test('전체 동기 API는 미러 비활성 시 0', () async {
    expect(await syncAllGggomJsonFromAppSupportToWorkspace(), 0);
  });
}
