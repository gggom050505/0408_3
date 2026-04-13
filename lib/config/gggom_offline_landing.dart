import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// gggom0505.kr 홈(랜딩)을 네트워크 없이 쓰기 위한 로컬 에셋·스타일.
/// `public/` 과 동일 구조: `cards/`, `oracle_cards/` 등.
const String kGggomBundledPublicRoot = 'assets/www_gggom';

const String kGggomSiteSplashPngAsset = '$kGggomBundledPublicRoot/splash.png';

/// 오프닝·스플래시 배경 — [AppColors] 와 동일 톤.
const List<Color> kGggomSiteSplashGradientColors = AppColors.scaffoldGradientStops;

/// 사이트 HTML title 과 동일
const String kGggomSiteBrowserTitle = '공공곰타로덱';
