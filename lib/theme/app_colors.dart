import 'package:flutter/material.dart';

/// 앱 전체 톤 — 라벤더·바이올렛·연한 민트 포인트 (핑크 배제, 보라 중심).
class AppColors {
  AppColors._();

  /// 메인 배경 (아주 연한 라일락)
  static const bgMain = Color(0xFFF3F0FA);

  /// 카드·패널 배경
  static const bgCard = Color(0xFFE6E0F4);

  /// 내부 하이라이트
  static const cardInner = Color(0xFFD8CEEC);

  /// 포인트 테두리 (자줏빛)
  static const cardBorder = Color(0xFFB59FD8);

  /// 메인 악센트 (라벤더)
  static const accentPurple = Color(0xFFB090E0);

  /// 보조 악센트 (연한 바이옛, 핑크 대신)
  static const accentLilac = Color(0xFFADA0E8);

  /// 살짝 차분한 딥 퍼플 (대비용)
  static const accentViolet = Color(0xFF8B72C9);

  /// 밝은 민트 포인트 (배경과 조화만 — 보라와 섞여도 무방)
  static const accentMint = Color(0xFF7EDCC4);

  /// 본문
  static const textPrimary = Color(0xFF3D3550);

  static const textSecondary = Color(0xFF655A78);

  /// 연한 파스텔/그라데이션 카드 위 제목·강조 (가독성 우선)
  static const textOnLightCard = Color(0xFF2A2238);

  /// 연한 카드 위 부가 설명
  static const textOnLightCardMuted = Color(0xFF4F455F);

  /// 밝은 글자/태그
  static const textLight = Color(0xFFF8F5FF);

  /// 유니크 품목(한국전통·오라클·이모) 본문·제목 강조 — 진한 골드톤(노란 계열, 가독성)
  static const uniqueItemForeground = Color(0xFFB8860B);

  /// 유니크 배지·비활성 버튼 배경
  static const uniqueItemSurface = Color(0xFFFFF9E6);

  /// 유니크 카드·칩 테두리
  static const uniqueItemBorder = Color(0xFFFFC947);

  /// 스플래시·로그인 등 상단→하단 그라데이션 (민트·라벤더·연보라)
  static const List<Color> scaffoldGradientStops = [
    Color(0xFFEFF6F3),
    Color(0xFFE8E4FA),
    Color(0xFFDDD4F2),
  ];

  static LinearGradient get scaffoldGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: scaffoldGradientStops,
        stops: [0.0, 0.5, 1.0],
      );

  /// 로그인 공 오브 (라벤더 → 바이옛 → 소프트 블루)
  static const LinearGradient loginOrbGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE4D9FF),
      Color(0xFFC8B4F2),
      Color(0xFFB8D8FF),
    ],
  );

  /// 하단 탭 바(필 레일) 배경
  static const LinearGradient gnbRailGradient = LinearGradient(
    colors: [
      Color(0xFFC8B0E8),
      Color(0xFFB098E0),
    ],
  );

  /// 선택된 탭 필
  static const LinearGradient gnbTabSelectedGradient = LinearGradient(
    colors: [
      Color(0xFFF0E8FF),
      Color(0xFFE0D4FA),
    ],
  );
}
