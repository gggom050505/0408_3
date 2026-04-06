import 'package:flutter/foundation.dart' show kIsWeb;

import 'gggom_runtime_site_config.dart';
import 'gggom_site_public_catalog.dart';

/// 백엔드는 **Supabase** 단일 서버입니다. `www.gggom0505.kr` 과 동일한 프로젝트 URL·anon 키·에셋 호스트를 **기본**으로 씁니다.
/// 스테이징/로컬은 `--dart-define=SUPABASE_URL=...` 등으로 덮어씁니다.
/// `dart-define`이 비어 있으면 [GggomRuntimeSiteConfig] 원격 JSON → [GggomSitePublicCatalog] 순입니다.
///
/// 오프라인 전용 번들: `--dart-define=GGGOM_OFFLINE_BUNDLE=true`
class AppConfig {
  AppConfig._();

  static bool supabaseEnabled = false;

  static const _supabaseUrlEnv =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const _supabaseAnonKeyEnv =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const _assetOriginEnv =
      String.fromEnvironment('ASSET_ORIGIN', defaultValue: '');
  static const _oauthRedirectEnv =
      String.fromEnvironment('OAUTH_REDIRECT_URL', defaultValue: '');

  /// `true` / `1` 이면 Supabase 초기화를 건너뜁니다 (로컬 에셋·시뮬 메뉴 중심 빌드).
  static const _offlineBundleRaw =
      String.fromEnvironment('GGGOM_OFFLINE_BUNDLE', defaultValue: 'false');
  static bool get useOfflineBundleOnly =>
      _offlineBundleRaw == 'true' || _offlineBundleRaw == '1';

  /// [GggomSitePublicCatalog] 프로덕션 프로젝트. `SUPABASE_URL` → 원격 JSON → 카탈로그.
  static String get supabaseUrl {
    if (_supabaseUrlEnv.isNotEmpty) return _supabaseUrlEnv;
    final r = GggomRuntimeSiteConfig.instance.supabaseUrl;
    if (r != null && r.isNotEmpty) return r;
    return GggomSitePublicCatalog.supabaseRestBase;
  }

  /// 웹과 동일한 anon 키. `SUPABASE_ANON_KEY` → 원격 JSON → 카탈로그.
  static String get supabaseAnonKey {
    if (_supabaseAnonKeyEnv.isNotEmpty) return _supabaseAnonKeyEnv;
    final r = GggomRuntimeSiteConfig.instance.supabaseAnonKey;
    if (r != null && r.isNotEmpty) return r;
    return GggomSitePublicCatalog.anonKey;
  }

  /// 카드·썸네일 등 `public/` 기준 URL. `ASSET_ORIGIN` → 원격 JSON → 카탈로그.
  static String get assetOrigin {
    if (_assetOriginEnv.isNotEmpty) return _assetOriginEnv;
    final r = GggomRuntimeSiteConfig.instance.assetOrigin;
    if (r != null && r.isNotEmpty) return r;
    return GggomSitePublicCatalog.siteOrigin;
  }

  /// Supabase Dashboard → Authentication → Redirect URLs 에 동일 등록 필요.
  /// 모바일/데스크톱: 앱 스킴 딥링크.
  /// **웹:** 기본은 **지금 Flutter 웹 오리진**(`https://www…/` 등)으로 복귀합니다(가비아·Vercel 정적 호스팅 공통).
  /// 사이트 도메인 콜백을 쓰려면 `--dart-define=OAUTH_REDIRECT_URL=https://…/auth/callback` 로 지정.
  static String get oauthRedirectUrl {
    if (_oauthRedirectEnv.isNotEmpty) return _oauthRedirectEnv;
    if (!kIsWeb) return 'com.gggom.gggom_tarot://login-callback/';
    final u = Uri.base;
    if (u.scheme == 'http' || u.scheme == 'https') {
      final o = u.origin;
      return o.endsWith('/') ? o : '$o/';
    }
    final rt = GggomRuntimeSiteConfig.instance;
    final origin =
        (rt.assetOrigin ?? GggomSitePublicCatalog.siteOrigin).replaceAll(
      RegExp(r'/$'),
      '',
    );
    final path =
        rt.webAuthCallbackPath ?? GggomSitePublicCatalog.webAuthCallbackPath;
    final p = path.startsWith('/') ? path : '/$path';
    return '$origin$p';
  }

  /// `true` / `1` 이면 Supabase 연동 빌드에서도 「별조각·광고(베타)」를 켭니다.
  /// 실제 광고 SDK 연동 전 — `--dart-define=AD_REWARD_TEST_MODE=true`
  static const _adRewardTestRaw =
      String.fromEnvironment('AD_REWARD_TEST_MODE', defaultValue: 'false');
  static bool get adRewardTestMode =>
      _adRewardTestRaw == 'true' || _adRewardTestRaw == '1';

  /// 별조각 광고(시뮬) 메뉴 표시 — **베타 번들**(Supabase 미연동)에서는 항상 true,
  /// 정식(연동) 빌드에서는 [adRewardTestMode] 일 때만 true.
  static bool get showBetaStarAdRewardMenu =>
      adRewardTestMode || !supabaseEnabled;

  /// 광고 보상(시뮬) 지급 별조각 — `--dart-define=AD_REWARD_STARS=1` (기본 1)
  static const adRewardStarAmount =
      int.fromEnvironment('AD_REWARD_STARS', defaultValue: 1);

  /// 같은 유저 기준 광고 보상 재시청 최소 간격(분). UI·저장 로직과 맞출 것.
  static const adRewardCooldownMinutes = 10;
}
