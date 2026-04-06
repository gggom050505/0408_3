import 'package:flutter/material.dart';

class MatThemeData {
  const MatThemeData({
    required this.id,
    required this.name,
    required this.background,
    required this.deckAreaColor,
    required this.slotBorder,
    required this.slotBorderHighlight,
    required this.slotGlow,
  });

  final String id;
  final String name;
  final LinearGradient background;
  final Color deckAreaColor;
  final Color slotBorder;
  final Color slotBorderHighlight;
  final List<BoxShadow> slotGlow;

  static const defaultId = 'default-mint';
}

/// 타로 매트 5종 — 각각 **소품 하나**를 테이블 무드로 해석한 팔레트.
/// 상점·가방은 [matThemes] 순서를 그대로 사용합니다.
final List<MatThemeData> matThemes = [
  MatThemeData(
    id: 'default-mint',
    name: '🌿 세이지·린넨',
    background: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE8F0E4),
        Color(0xFFD4E4CC),
        Color(0xFFB8D4B0),
        Color(0xFF9CBF98),
      ],
      stops: [0.0, 0.35, 0.72, 1.0],
    ),
    deckAreaColor: Color(0xFFB8D4B0),
    slotBorder: Color(0x3D5D7A52),
    slotBorderHighlight: Color(0xFF7A9B6E),
    slotGlow: [
      BoxShadow(color: Color(0x597A9B6E), blurRadius: 14, spreadRadius: 0),
    ],
  ),
  MatThemeData(
    id: 'night-sky',
    name: '🔮 수정구슬 밤',
    background: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0C1520),
        Color(0xFF152A3D),
        Color(0xFF1E3D52),
        Color(0xFF143042),
      ],
      stops: [0.0, 0.35, 0.65, 1.0],
    ),
    deckAreaColor: Color(0x40204060),
    slotBorder: Color(0x4D7EC8E8),
    slotBorderHighlight: Color(0xFF5DD4E8),
    slotGlow: [
      BoxShadow(color: Color(0x6648D0E8), blurRadius: 18, spreadRadius: 0),
    ],
  ),
  MatThemeData(
    id: 'cherry-blossom',
    name: '🌸 꽃잎 소품',
    background: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFF5F7),
        Color(0xFFFCE4EC),
        Color(0xFFF8BBD9),
        Color(0xFFE1A4BE),
      ],
      stops: [0.0, 0.3, 0.65, 1.0],
    ),
    deckAreaColor: Color(0x33F8BBD9),
    slotBorder: Color(0x40C2185B),
    slotBorderHighlight: Color(0xFFC2185B),
    slotGlow: [
      BoxShadow(color: Color(0x55E91E63), blurRadius: 14, spreadRadius: 0),
    ],
  ),
  MatThemeData(
    id: 'wooden-table',
    name: '🕯️ 양초·원목',
    background: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF6B5344),
        Color(0xFF8B6F52),
        Color(0xFFA67C52),
        Color(0xFF7A5A3C),
      ],
      stops: [0.0, 0.35, 0.62, 1.0],
    ),
    deckAreaColor: Color(0x3D000000),
    slotBorder: Color(0x59FFCC80),
    slotBorderHighlight: Color(0xFFFFB74D),
    slotGlow: [
      BoxShadow(color: Color(0x80FF9800), blurRadius: 16, spreadRadius: -1),
    ],
  ),
  MatThemeData(
    id: 'deep-purple',
    name: '✨ 벨벳 타로천',
    background: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1A0A28),
        Color(0xFF2D1442),
        Color(0xFF4A1F5C),
        Color(0xFF351045),
      ],
      stops: [0.0, 0.32, 0.68, 1.0],
    ),
    deckAreaColor: Color(0x40000000),
    slotBorder: Color(0x4DD4AF37),
    slotBorderHighlight: Color(0xFFE8C547),
    slotGlow: [
      BoxShadow(color: Color(0x73D4AF37), blurRadius: 18, spreadRadius: 0),
    ],
  ),
];

MatThemeData matById(String id) {
  for (final m in matThemes) {
    if (m.id == id) return m;
  }
  return matThemes.first;
}
