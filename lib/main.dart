import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'config/desktop_init.dart';
import 'services/web_bundled_data_seed.dart';
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
// | 웹/기능              | Dart 구현 |
// |---------------------|-----------|
// | 스플래시·랜딩        | `widgets/splash_screen.dart`, `config/gggom_offline_landing.dart` |
// | 로그인(ID·회원가입·탈퇴)   | `widgets/login_screen.dart`, `widgets/local_account_auth_screens.dart`, `widgets/app_root.dart` |
// | 데이터 저장          | `lib/standalone/*` 로컬 JSON·기기 저장 (상점·피드·채팅·이벤트·출석) |
// | GNB·탭              | `widgets/gnb.dart`, `widgets/home_screen.dart` |
// | 타로·캡처·피드게시    | `widgets/tarot_tab.dart`, `widgets/post_capture_sheet.dart` |
// | 오라클              | `widgets/oracle_modal.dart` |
// | 게시물               | `widgets/feed_tab.dart` |
// | 채팅                | `widgets/standalone_chat_tab.dart` |
// | 상점·가방            | `widgets/shop_tab.dart`, `widgets/bag_tab.dart` |
// | 이벤트              | `widgets/event_tab.dart` |
// | 출석                | `widgets/attendance_modal.dart` |
// | 첫 가입 세팅        | `widgets/first_setup_wizard_screen.dart` — 확인 시 ⭐20·이모7·오라클8(`starter_gifts`), 뒷면·슬롯 → 가방 탭 |
// | 별조각 광고 | `widgets/ad_reward_sheet.dart` — `assets/advert/*.mp4` 1편 재생 → 「별조각 획득」 후 별조각 3개 지급 · 10분 쿨타임 |
// | 결과 모달·공유·복사   | `widgets/result_modal.dart` |
// | 메이킹 노트(앱 내)   | `widgets/making_notes_screen.dart` — GNB 도서 아이콘, 에셋 `docs/MAKING_NOTES.md` |
//
// 기본: `www.gggom0505.kr` 가비아 정적 호스팅·에셋 (`lib/config/gggom_site_public_catalog.dart`).
// 재배포 없이 에셋 오리진 변경: 사이트 `app/flutter_runtime_config.json` ([GggomRuntimeSiteConfig]).
// 가비아 업로드: `web/app/flutter_runtime_config.json` 이 `build/web/app/` 로 포함됨. 없으면 번들 폴백.
// 선택(로컬 등): `--dart-define=ASSET_ORIGIN=http://localhost:3000`
// 오프라인 전용(번들·시뮬): `--dart-define=GGGOM_OFFLINE_BUNDLE=true` → 런타임 사이트 JSON 로드 생략
// 웹 로컬 테스트: `--dart-define=GGGOM_SKIP_LOGIN=true` → 스플래시 후 로그인 화면 없이 게스트 홈
// 디버그·프로파일 웹: 시드로 첫 방문 자동 가입·로그인 + 같은 define이면 로그인/가입 화면에 아이디 미리 입력
//   `--dart-define=GGGOM_DEV_WEB_SEED_LOGIN=gggom050501 --dart-define=GGGOM_DEV_WEB_SEED_PASSWORD=6자이상`
//   비밀번호는 화면에서 직접 입력해 로그인해도 됨(아이디 칸은 define이 있으면 자동 채움).
//   `--dart-define=GGGOM_PROJECT_ROOT=C:\path\to\gggom0505_0403`  (로컬 JSON → assets/local_dev_state/ 미러)
//   (호환) `--dart-define=SHOP_CATALOG_REPO_ROOT=...`
//   광고 시뮬 플래그: `--dart-define=AD_REWARD_TEST_MODE=true`
//   보상 개수: `--dart-define=AD_REWARD_STARS=N` (기본 3)
//   오프라인 번들 이모 덮어쓰기: `EMOTICON_CATALOG_*`
//   웹 미리보기·스테이징만 암호 게이트: `--dart-define=SITE_ACCESS_PIN=비번` (공개 프로덕션 빌드에는 이 define을 넣지 않음.
//   Vercel이면 Preview 전용 Build Command에만 `SITE_ACCESS_PIN` 넣기 권장)
// =============================================================================

Future<void> main() async {
  await _bootstrapBindingAndDesktop();
  await maybeSeedWebBundledData();
  await _initSupabaseIfEnabled();
  await _lockPortraitOnPhones();
  if (!AppConfig.useOfflineBundleOnly) {
    await GggomRuntimeSiteConfig.instance.load();
  }
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

Future<void> _initSupabaseIfEnabled() async {
  if (!AppConfig.supabaseEnabled) {
    return;
  }
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
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
