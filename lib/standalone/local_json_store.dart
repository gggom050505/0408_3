import 'local_json_store_io.dart' if (dart.library.html) 'local_json_store_web.dart' as impl;

/// 오프라인·베타 번들용 JSON 조각. VM에서는 앱 지원 디렉터리 파일, 웹에서는 SharedPreferences.
Future<String?> loadLocalJsonFile(String name) => impl.loadLocalJsonFile(name);

Future<void> saveLocalJsonFile(String name, String data) => impl.saveLocalJsonFile(name, data);
