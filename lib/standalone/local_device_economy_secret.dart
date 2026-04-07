import 'local_device_economy_secret_io.dart'
    if (dart.library.html) 'local_device_economy_secret_web.dart' as impl;

/// 오프라인 경제 JSON 서명용 — 기기마다 1개(웹은 SharedPreferences). 루팅 시에는 한계가 있습니다.
Future<List<int>> economyDeviceSecretBytes() => impl.economyDeviceSecretBytes();
