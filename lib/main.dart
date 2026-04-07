import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'config/desktop_init.dart';
import 'config/gggom_offline_landing.dart';
import 'config/gggom_runtime_site_config.dart';
import 'theme/app_colors.dart';
import 'widgets/app_motion.dart';
import 'widgets/app_root.dart';
import 'widgets/app_scaffold_messenger.dart';
import 'widgets/site_access_gate.dart';

// 오프라인에서 문구·색·에셋만 손볼 때: docs/OFFLINE_EDITING.md 참고.
//
// =============================================================================
// 웹(gggom0505.kr) 로그인·탭 기능 ↔ 플러터 복제 맵
// -----------------------------------------------------------------------------
// UI/버튼 구현은 모두 아래 파일에 있고, 본 main 은 "URL 로그인·세션·부팅"만 연결한다.
// 한 파일에 수천 줄 복제는 유지보수·빌드에 불가능하므로, 진입점에서 Supabase·딥링크를
// 공식 패턴으로 고정한다.
//
// | 웹/기능              | Dart 구현 |
// |---------------------|-----------|
// | 스플래시·랜딩        | `widgets/splash_screen.dart`, `config/gggom_offline_landing.dart` |
// | 로그인(아이디·관리자 구글) | `widgets/login_screen.dart`, `widgets/local_account_auth_screens.dart`, `widgets/app_root.dart` |
// | 관리자 구글 OAuth·세션     | 본 파일 `Supabase.initialize` + PKCE + `detectSessionInUri`, `app_config.oauthRedirectUrl` |
// | 설치형·오프라인 베타 번들 | Supabase **없이** 실행 → `lib/standalone/*` + `StandaloneChatTab` (`home_screen.dart`) |
// | GNB·탭              | `widgets/gnb.dart`, `widgets/home_screen.dart` |
// | 타로·캡처·피드게시    | `widgets/tarot_tab.dart`, `widgets/post_capture_sheet.dart` |
// | 오라클              | `widgets/oracle_modal.dart` |
// | 게시물               | `widgets/feed_tab.dart` |
// | 채팅                | `widgets/chat_tab.dart` |
// | 상점·가방            | `widgets/shop_tab.dart`, `widgets/bag_tab.dart` |
// | 이벤트              | `widgets/event_tab.dart` |
// | 출석                | `widgets/attendance_modal.dart` |
// | 광고 보상(베타 시뮬) | `widgets/ad_reward_sheet.dart` — `advert/*.mp4` 1편 재생 후 보상; 연동 빌드는 `AD_REWARD_TEST_MODE` |
// | 결과 모달·공유·복사   | `widgets/result_modal.dart` |
// | 메이킹 노트(앱 내)   | `widgets/making_notes_screen.dart` — GNB 도서 아이콘, 에셋 `docs/MAKING_NOTES.md` |
//
// 기본: `www.gggom0505.kr` 과 동일 Supabase·에셋 (`lib/config/gggom_site_public_catalog.dart`).
// 재배포 없이 URL/키 변경: 사이트 `app/flutter_runtime_config.json` ([GggomRuntimeSiteConfig]).
// 가비아·정적 호스팅: `web/app/flutter_runtime_config.json` 이 `build/web/app/` 로 포함됨. 없으면 번들 폴백.
// 선택(스테이징/로컬 Next 등):
//   `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
//   `--dart-define=ASSET_ORIGIN=http://localhost:3000`  (에셋 호스트만 바꿀 때)
//   `--dart-define=OAUTH_REDIRECT_URL=...`    (딥링크 또는 Next `/auth/callback` 등; **웹 기본은 현재 오리진**으로 복귀)
// 오프라인 전용(번들·시뮬): `--dart-define=GGGOM_OFFLINE_BUNDLE=true` → Supabase 미초기화
//   `--dart-define=GGGOM_PROJECT_ROOT=C:\path\to\gggom0505_0403`  (로컬 JSON → assets/local_dev_state/ 미러)
//   (호환) `--dart-define=SHOP_CATALOG_REPO_ROOT=...`
//   연동 빌드에서만 시뮬 메뉴: `--dart-define=AD_REWARD_TEST_MODE=true`
//   보상 개수: `--dart-define=AD_REWARD_STARS=1` (기본 1)
//   오프라인 번들 이모 덮어쓰기: `EMOTICON_CATALOG_*`
//   웹 미리보기·스테이징만 암호 게이트: `--dart-define=SITE_ACCESS_PIN=비번` (공개 프로덕션 빌드에는 이 define을 넣지 않음.
//   Vercel이면 Preview 전용 Build Command에만 `SITE_ACCESS_PIN` 넣기 권장)
//
// 실행 예(스테이징만 바꿀 때):
//   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
// =============================================================================

Future<void> main() async {
  await _bootstrapBindingAndDesktop();
  await _lockPortraitOnPhones();
  if (!AppConfig.useOfflineBundleOnly) {
    await GggomRuntimeSiteConfig.instance.load();
  }
  await _initSupabaseIfConfigured();
  runApp(
    ListenableBuilder(
      listenable: GggomRuntimeSiteConfig.instance,
      builder: (context, _) {
        const app = GgomTarotApp();
        return AppConfig.siteAccessPinRequired
            ? const SiteAccessGate(child: app)
            : app;
      },
    ),
  );
}

Future<void> _bootstrapBindingAndDesktop() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDesktopWindow();
}

Future<void> _lockPortraitOnPhones() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

/// Supabase + URL 로그인(OAuth) 복귀 처리.
/// [FlutterAuthClientOptions.detectSessionInUri] → app_links 로 `login-callback` URI 에서 세션 확보.
/// [AuthFlowType.pkce] → 브라우저에서 로그인 후 `?code=` 로 앱 복귀(권장).
///
/// 원격 JSON으로 Supabase URL/키가 바뀌어도, 이미 [Supabase.initialize] 된 세션은 **콜드 스타트**까지
/// 이전 엔드포인트를 쓸 수 있습니다. 에셋 오리진 등은 [ListenableBuilder]로 즉시 반영됩니다.
Future<void> _initSupabaseIfConfigured() async {
  if (AppConfig.useOfflineBundleOnly) {
    return;
  }
  final url = AppConfig.supabaseUrl;
  final key = AppConfig.supabaseAnonKey;
  if (url.isEmpty || key.isEmpty) {
    return;
  }
  await Supabase.initialize(
    url: url,
    anonKey: key,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
      detectSessionInUri: true,
    ),
  );
  AppConfig.supabaseEnabled = true;
}

class GgomTarotApp extends StatelessWidget {
  const GgomTarotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.accentPurple,
        onPrimary: Colors.white,
        primaryContainer: AppColors.accentLilac.withValues(alpha: 0.38),
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.accentLilac,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.bgMain,
        onSurface: AppColors.textPrimary,
        outline: AppColors.cardBorder.withValues(alpha: 0.55),
      ),
      scaffoldBackgroundColor: AppColors.bgMain,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.bgMain,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.35),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(
            color: AppColors.accentPurple.withValues(alpha: 0.55),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.45),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.accentPurple.withValues(alpha: 0.85),
            width: 2,
          ),
        ),
      ),
    );

    final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return MaterialApp(
      title: kGggomSiteBrowserTitle,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: gggomScaffoldMessengerKey,
      theme: base.copyWith(
        textTheme: textTheme,
        splashFactory: InkSparkle.splashFactory,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final p in TargetPlatform.values)
              p: p == TargetPlatform.iOS || p == TargetPlatform.macOS
                  ? const CupertinoPageTransitionsBuilder()
                  : const GgomFadeUpwardsPageTransitionsBuilder(),
          },
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const AppRoot(),
    );
  }
}
