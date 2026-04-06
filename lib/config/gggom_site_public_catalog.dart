/// `www.gggom0505.kr` 프로덕션 **공개** Supabase 엔드포인트(anon 역할).
/// (가비아·Vercel 등 어디에 정적 웹을 올리든 동일 키로 동작.)
/// 서비스 전용 비밀키(service_role)가 아니라, 웹 방문자와 동일한 수준의 키입니다.
/// 배포사가 URL/키를 바꾸면 여기와 동기화하거나 `--dart-define=EMOTICON_CATALOG_*` 로 덮어쓰면 됩니다.
class GggomSitePublicCatalog {
  GggomSitePublicCatalog._();

  /// 카드·이모티콘 등 원격 경로를 붙일 프로덕션 호스트(`https://www…`).
  static const siteOrigin = 'https://www.gggom0505.kr';

  /// 문서·폴백용 콜백 경로. 웹에서는 [AppConfig.oauthRedirectUrl] 이 보통 **사이트 루트 오리진**을 씁니다.
  static const webAuthCallbackPath = '/auth/callback';

  /// Flutter 웹 기본 redirect — Supabase Dashboard Redirect URLs 에 등록.
  static String get webOAuthRedirectUrl =>
      '$siteOrigin$webAuthCallbackPath';

  static const supabaseRestBase = 'https://nktapegejzujsxuhdcxz.supabase.co';

  /// REST `apikey` / `Authorization: Bearer` 용 anon JWT.
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5rdGFwZWdlanp1anN4dWhkY3h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMjMxNzcsImV4cCI6MjA4ODc5OTE3N30.9_2NWfnDoKfrnwbfFG1YGFrKD7pwF8Hq5TjEAvzCSFU';
}
