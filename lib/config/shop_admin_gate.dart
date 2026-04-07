import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

/// 상점 관리자(지정 구글 계정만). [shopAdminGateAllowsCurrentUser] 가 true일 때만 “관리자 모드” UI를 켭니다.
const String kShopAdminGoogleEmail = 'gggom0505@gmail.com';

// ---------------------------------------------------------------------------
// 로그인 화면「관리자로 구글 로그인」→ OAuth 직후 허용 여부 검사용 일회성 플래그
// ---------------------------------------------------------------------------

bool _pendingAdminGoogleOAuth = false;

void markPendingAdminGoogleOAuth() {
  _pendingAdminGoogleOAuth = true;
}

void clearPendingAdminGoogleOAuth() {
  _pendingAdminGoogleOAuth = false;
}

/// 직전에 관리자용 구글 로그인을 눌렀다면 true 한 번 반환하고 플래그를 땁니다.
bool consumePendingAdminGoogleOAuth() {
  if (!_pendingAdminGoogleOAuth) {
    return false;
  }
  _pendingAdminGoogleOAuth = false;
  return true;
}

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

/// Supabase가 꺼진 빌드에서는 이메일 대신 [ALLOW_OFFLINE_SHOP_ADMIN] 으로 허용 여부를 정합니다(기본 허용).
/// 연동 빌드에서는 지정 구글 계정만 관리자 UI를 봅니다.
///
/// Supabase 연동 시 **동시에** 만족해야 합니다:
/// - 현재 세션 이메일이 [kShopAdminGoogleEmail] 과 일치
/// - 로그인 제공자가 **google** (다른 방식으로 같은 이메일이 연결된 경우는 제외)
///
/// Supabase 미연동·오프라인 번들에서는 로컬 카탈로그만 있으므로 기본으로 관리자 UI를 켭니다.
/// 끄려면: `--dart-define=ALLOW_OFFLINE_SHOP_ADMIN=false`
bool shopAdminGateAllowsCurrentUser() {
  if (!AppConfig.supabaseEnabled) {
    return const bool.fromEnvironment(
      'ALLOW_OFFLINE_SHOP_ADMIN',
      defaultValue: true,
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
