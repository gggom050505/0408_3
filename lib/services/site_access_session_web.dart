import 'package:web/web.dart';

const _sessionKey = 'gggom_site_access_ok';

/// 탭을 닫기 전까지만 유지( [Window.sessionStorage] ). 공용 PC에서 브라우저만 닫으면 다시 암호 필요.
Future<bool> isSiteAccessSessionOk() async =>
    window.sessionStorage.getItem(_sessionKey) == '1';

Future<void> setSiteAccessSessionOk() async {
  window.sessionStorage.setItem(_sessionKey, '1');
}
