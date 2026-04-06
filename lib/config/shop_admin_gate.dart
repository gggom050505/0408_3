import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

/// 상점 관리자(지정 구글 계정만). [shopAdminGateAllowsCurrentUser] 가 true일 때만 “관리자 모드” UI를 켭니다.
const String kShopAdminGoogleEmail = 'gggom0505@gmail.com';

bool _emailIsShopAdmin(String? email) {
  if (email == null || email.isEmpty) {
    return false;
  }
  return email.toLowerCase().trim() == kShopAdminGoogleEmail.toLowerCase().trim();
}

/// 현재 세션이 **구글 OAuth** 인지 (이메일만 맞고 다른 제공자면 제외).
bool _sessionIsGoogleOAuth(User user) {
  final ids = user.identities;
  if (ids != null && ids.isNotEmpty) {
    return ids.any((i) => i.provider == 'google');
  }
  final p = user.appMetadata['provider'];
  if (p is String && p.toLowerCase() == 'google') {
    return true;
  }
  return false;
}

/// Supabase가 꺼진 빌드에서는 세션 이메일을 확인할 수 없으므로 항상 거부합니다.
/// (게스트·이 기기 전용 계정으로는 관리자 UI가 보이지 않습니다.)
///
/// Supabase 연동 시 **동시에** 만족해야 합니다:
/// - 현재 세션 이메일이 [kShopAdminGoogleEmail] 과 일치
/// - 로그인 제공자가 **google** (다른 방식으로 같은 이메일이 연결된 경우는 제외)
///
/// 오프라인에서만 상점 JSON을 손볼 때: `--dart-define=ALLOW_OFFLINE_SHOP_ADMIN=true`
bool shopAdminGateAllowsCurrentUser() {
  if (!AppConfig.supabaseEnabled) {
    return const bool.fromEnvironment(
      'ALLOW_OFFLINE_SHOP_ADMIN',
      defaultValue: false,
    );
  }
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return false;
  }
  if (!_emailIsShopAdmin(user.email)) {
    return false;
  }
  return _sessionIsGoogleOAuth(user);
}
