import 'local_json_workspace_export_stub.dart'
    if (dart.library.io) 'local_json_workspace_export_io.dart' as impl;

/// 홈「저장하기」: 기기의 로컬 JSON 전부를 프로젝트 `assets/local_dev_state/` 로 복사.
Future<int> syncAllGggomJsonFromAppSupportToWorkspace() =>
    impl.syncAllGggomJsonFromAppSupportToWorkspace();
