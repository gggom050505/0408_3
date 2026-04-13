import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

import 'gggom_runtime_site_config.dart';
import 'gggom_site_public_catalog.dart';

/// 에셋 오리진 등은 [GggomSitePublicCatalog]·[GggomRuntimeSiteConfig]·`dart-define` 순으로 읽습니다.
///
/// 이 앱 빌드는 **서버 DB 없이** 로컬 JSON·기기 저장만 사용합니다.
/// 오프라인 전용: `--dart-define=GGGOM_OFFLINE_BUNDLE=true` → 런타임 설정 원격 로드를 생략합니다.
class AppConfig {
  AppConfig._();

  static const _assetOriginEnv = String.fromEnvironment(
    'ASSET_ORIGIN',
    defaultValue: '',
  );

  /// `true` / `1` 이면 런타임 사이트 JSON 로드를 생략합니다 (로컬 에셋·시뮬 중심).
  static const _offlineBundleRaw = String.fromEnvironment(
    'GGGOM_OFFLINE_BUNDLE',
    defaultValue: 'false',
  );
  static bool get useOfflineBundleOnly =>
      _offlineBundleRaw == 'true' || _offlineBundleRaw == '1';

  /// **웹만** — 스플래시 뒤 로그인 랜딩 없이 게스트 홈으로 진입(로컬 테스트용).
  /// `flutter run -d chrome --dart-define=GGGOM_SKIP_LOGIN=true`
  static const _skipLoginRaw = String.fromEnvironment(
    'GGGOM_SKIP_LOGIN',
    defaultValue: 'false',
  );
  static bool get skipLoginScreen =>
      kIsWeb && (_skipLoginRaw == 'true' || _skipLoginRaw == '1');

  /// **웹 전용(디버그·프로파일)** — 브라우저에 로컬 ID 계정을 자동 생성·로그인하거나,
  /// [devWebPrefillLoginId]로 로그인/가입 화면에 아이디를 미리 넣습니다.
  ///
  /// `flutter run -d chrome --dart-define=GGGOM_DEV_WEB_SEED_LOGIN=gggom050501 --dart-define=GGGOM_DEV_WEB_SEED_PASSWORD=******`
  /// 비밀번호 6자 이상일 때만 첫 실행 자동 가입·로그인. **릴리스(`kReleaseMode`)에서는 전부 무시.**
  static const _devWebSeedLogin = String.fromEnvironment(
    'GGGOM_DEV_WEB_SEED_LOGIN',
    defaultValue: '',
  );
  static const _devWebSeedPassword = String.fromEnvironment(
    'GGGOM_DEV_WEB_SEED_PASSWORD',
    defaultValue: '',
  );

  /// 시드할 로그인 아이디(앞뒤 공백 제외). [devWebSeedLocalAccountEnabled]·[devWebPrefillLoginId] 참고.
  static String get devWebSeedLogin => _devWebSeedLogin.trim();

  /// 디버그·프로파일 웹에서 `GGGOM_DEV_WEB_SEED_LOGIN`이 있으면 로그인/가입 화면 아이디 칸에 넣습니다.
  static bool get devWebPrefillLoginId =>
      kIsWeb && !kReleaseMode && devWebSeedLogin.isNotEmpty;

  /// 디버그·프로파일 웹 + 시드 비밀번호 6자 이상일 때 자동 가입·세션 저장.
  static bool get devWebSeedLocalAccountEnabled =>
      kIsWeb &&
      !kReleaseMode &&
      devWebSeedLogin.isNotEmpty &&
      _devWebSeedPassword.length >= 6;

  static String get devWebSeedPassword => _devWebSeedPassword;

  /// **디버그·프로파일 전용**(릴리스 무시). 로컬 상점 경제(`LocalShopRepository`)에만 적용.
  static const _devGrantUserRequestPackRaw = String.fromEnvironment(
    'GGGOM_DEV_GRANT_USER_REQUEST_PACK',
    defaultValue: 'false',
  );
  static bool get devGrantUserRequestPack =>
      !kReleaseMode &&
      (_devGrantUserRequestPackRaw == 'true' ||
          _devGrantUserRequestPackRaw == '1');

  /// 디버그 전용 — 선물팩 지급 대상을 특정 계정 ID로 제한.
  /// 비어 있으면 계정 제한 없이(로그인한 계정마다 1회) 적용합니다.
  static const _devGrantUserRequestPackOnlyUserIdRaw = String.fromEnvironment(
    'GGGOM_DEV_GRANT_USER_REQUEST_PACK_ONLY_USER_ID',
    defaultValue: '',
  );
  static String get devGrantUserRequestPackOnlyUserId =>
      _devGrantUserRequestPackOnlyUserIdRaw.trim();

  /// 카드·썸네일 등 `public/` 기준 URL. `ASSET_ORIGIN` → 원격 JSON → 카탈로그.
  static String get assetOrigin {
    if (_assetOriginEnv.isNotEmpty) return _assetOriginEnv;
    final r = GggomRuntimeSiteConfig.instance.assetOrigin;
    if (r != null && r.isNotEmpty) return r;
    return GggomSitePublicCatalog.siteOrigin;
  }

  /// 별조각 광고(시뮬) — `--dart-define=AD_REWARD_TEST_MODE=true`
  static const _adRewardTestRaw = String.fromEnvironment(
    'AD_REWARD_TEST_MODE',
    defaultValue: 'false',
  );
  static bool get adRewardTestMode =>
      _adRewardTestRaw == 'true' || _adRewardTestRaw == '1';

  /// 별조각 광고 메뉴 표시. 숨기려면 `--dart-define=SHOW_AD_REWARD_MENU=false`
  static const _showAdRewardMenuRaw = String.fromEnvironment(
    'SHOW_AD_REWARD_MENU',
    defaultValue: 'true',
  );
  static bool get showBetaStarAdRewardMenu =>
      !(_showAdRewardMenuRaw == 'false' || _showAdRewardMenuRaw == '0');

  /// 광고 1회 시청 완료 시 지급 별조각 수. `--dart-define=AD_REWARD_STARS=N` 으로 덮어쓸 수 있음.
  static const adRewardStarAmount = int.fromEnvironment(
    'AD_REWARD_STARS',
    defaultValue: 3,
  );

  static const adRewardCooldownMinutes = 10;

  static const adInquiryContactLine = '광고 문의 gggom0505@gmail.com';

  static const communityMisconductReportLine =
      '다른 사용자에게 불쾌감이나 수치심을 주는 사용자를 보시면 화면캡처해서 '
      'gggom0505@gmail.com 으로 보내주세요';

  static const accountSecurityReminderLine =
      '계정 보안은 본인이 지키세요. 해킹으로부터 보호해 드리지 못합니다.';

  /// 기기에만 저장되는 ID·비밀번호 계정 안내.
  static const localIdAccountInfoLine =
      '이 계정은 이 기기에만 저장되는 ID·비밀번호 계정이에요. 다른 기기와 자동으로 동기화되지 않아요.';

  static const _siteAccessPinEnv = String.fromEnvironment(
    'SITE_ACCESS_PIN',
    defaultValue: '',
  );

  static bool get siteAccessPinRequired =>
      kIsWeb && _siteAccessPinEnv.trim().isNotEmpty;

  static String get siteAccessPin => _siteAccessPinEnv.trim();

  static const _authServerOriginEnv = String.fromEnvironment(
    'AUTH_SERVER_ORIGIN',
    defaultValue: '',
  );

  /// 웹 OAuth 시작 엔드포인트 베이스 URL (예: http://localhost:4000)
  static String get authServerOrigin => _authServerOriginEnv.trim();

  static bool get kakaoLoginEnabled => authServerOrigin.isNotEmpty;

  static const _supabaseUrlEnv = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const _supabaseAnonKeyEnv = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get supabaseUrl => _supabaseUrlEnv.trim();
  static String get supabaseAnonKey => _supabaseAnonKeyEnv.trim();

  static bool get supabaseEnabled =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Google OAuth 버튼 표시 여부 (웹/윈도우/모바일 공통).
  static bool get googleLoginEnabled => supabaseEnabled;

  /// 네이티브(윈도우/안드로이드/iOS) OAuth 콜백 딥링크.
  ///
  /// Supabase 대시보드(Auth > URL Configuration > Redirect URLs)에도
  /// `com.gggom.gggom_tarot://login-callback/` 를 등록해야 로그인 완료 후 앱으로 돌아옵니다.
  static const supabaseNativeRedirectUri =
      'com.gggom.gggom_tarot://login-callback/';
}
