/// `www.gggom0505.kr` 프로덕션 — **가비아 정적 호스팅** 기준 기본값.
/// 카드·이모티콘 등 원격 경로는 [siteOrigin]·런타임 JSON [`flutter_runtime_config.json`]의
/// `asset_origin` 으로 맞춥니다.
class GggomSitePublicCatalog {
  GggomSitePublicCatalog._();

  static const siteOrigin = 'https://www.gggom0505.kr';

  static const webAuthCallbackPath = '/auth/callback';

  static String get webOAuthRedirectUrl =>
      '$siteOrigin$webAuthCallbackPath';
}
