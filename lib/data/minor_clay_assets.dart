/// 3D 클레이풍 **마이너** 일러 — **숫자 카드**와 **궁정(코트) 카드**를 디렉터리로 분리합니다.
///
/// * **숫자(에이스~10)** 40장 — `assets/cards/minor_number_clay/{suit}/{ace|…|ten}.png`
/// * **궁정** 20장 — 슈트별 `page|knight|queen|king` 16장 + 확장 `special/*.png` 4장(id 78~81)
///
/// 웹·CDN에서는 `manifest.json`(각 루트) 또는 [minorClayPublicUrlPathForTarotCardId] 사용.
/// 동기화: `dart run tool/sync_minor_clay_web_assets.dart` (`assets/minor/` 소스).
library;

import 'major_clay_assets.dart';

/// 숫자 마이너(에이스~10) 번들 루트.
const String kMinorNumberClayAssetDir = 'assets/cards/minor_number_clay';

/// 궁정·확장 코트 번들 루트.
const String kMinorCourtClayAssetDir = 'assets/cards/minor_court_clay';

/// 상점 썸네일 등 — 숫자 덱 컵 에이스.
const String kMinorClayShopThumbnailSampleAsset =
    '$kMinorNumberClayAssetDir/cups/ace.png';

const _fnRank = <String>[
  'ace',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'page',
  'knight',
  'queen',
  'king',
];

const _suits = ['wands', 'cups', 'swords', 'pentacles'];

/// 마이너 클레이 일러의 세부 종류(숫자 vs 궁정·확장).
enum MinorClayImageKind {
  /// 에이스~텐 (40장).
  number,

  /// 페이지~킹 + id 78~81 special (20장).
  court,
}

MinorClayImageKind? minorClayKindForTarotCardId(int cardId) {
  if (cardId < 22 || cardId > 81) {
    return null;
  }
  if (cardId >= 78) {
    return MinorClayImageKind.court;
  }
  final rankIdx = (cardId - 22) % 14;
  return rankIdx < 10
      ? MinorClayImageKind.number
      : MinorClayImageKind.court;
}

/// Tarot id **22~77** 중 에이스~10만. 그 외 `null`.
String? minorNumberClayAssetPathForTarotCardId(int cardId) {
  if (cardId < 22 || cardId > 77) {
    return null;
  }
  final off = cardId - 22;
  final rankIdx = off % 14;
  if (rankIdx >= 10) {
    return null;
  }
  final suit = _suits[off ~/ 14];
  final rank = _fnRank[rankIdx];
  return '$kMinorNumberClayAssetDir/$suit/$rank.png';
}

/// Tarot id **32~35, 46~49, … , 74~77** + **78~81**. 숫자 카드만 있으면 `null`.
String? minorCourtClayAssetPathForTarotCardId(int cardId) {
  if (cardId >= 78 && cardId <= 81) {
    return switch (cardId) {
      78 => '$kMinorCourtClayAssetDir/special/son_of_wands.png',
      79 => '$kMinorCourtClayAssetDir/special/daughter_of_pentacles.png',
      80 => '$kMinorCourtClayAssetDir/special/daughter_of_cups.png',
      81 => '$kMinorCourtClayAssetDir/special/son_of_swords.png',
      _ => null,
    };
  }
  if (cardId < 22 || cardId > 77) {
    return null;
  }
  final off = cardId - 22;
  final rankIdx = off % 14;
  if (rankIdx < 10) {
    return null;
  }
  final suit = _suits[off ~/ 14];
  final rank = _fnRank[rankIdx];
  return '$kMinorCourtClayAssetDir/$suit/$rank.png';
}

/// 숫자 또는 궁정 경로 하나 (기존 API). id **22~81**.
String? minorClayRelativeAssetPathForTarotCardId(int cardId) =>
    minorNumberClayAssetPathForTarotCardId(cardId) ??
    minorCourtClayAssetPathForTarotCardId(cardId);

/// [minorClayRelativeAssetPathForTarotCardId] 와 동일.
String? minorClayAssetPathForTarotCardId(int cardId) =>
    minorClayRelativeAssetPathForTarotCardId(cardId);

/// 정적 URL — `/cards/minor_number_clay/...` 또는 `/cards/minor_court_clay/...`.
String? minorClayPublicUrlPathForTarotCardId(int cardId) {
  final n = minorNumberClayAssetPathForTarotCardId(cardId);
  if (n != null) {
    final rest = n.substring(kMinorNumberClayAssetDir.length + 1);
    return '/cards/minor_number_clay/$rest';
  }
  final c = minorCourtClayAssetPathForTarotCardId(cardId);
  if (c != null) {
    final rest = c.substring(kMinorCourtClayAssetDir.length + 1);
    return '/cards/minor_court_clay/$rest';
  }
  return null;
}

/// 숫자 마이너 일러 id (40개).
const Set<int> kMinorNumberClayTarotCardIds = {
  22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
  36, 37, 38, 39, 40, 41, 42, 43, 44, 45,
  50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
  64, 65, 66, 67, 68, 69, 70, 71, 72, 73,
};

/// 궁정·확장 일러 id (20개).
const Set<int> kMinorCourtClayTarotCardIds = {
  32, 33, 34, 35,
  46, 47, 48, 49,
  60, 61, 62, 63,
  74, 75, 76, 77,
  78, 79, 80, 81,
};

/// 클레이 마이너 전체 (60개).
const Set<int> kMinorClayTarotCardIds = {
  ...kMinorNumberClayTarotCardIds,
  ...kMinorCourtClayTarotCardIds,
};

/// 메이저 클레이 덱 + 마이너: 이 경로가 있으면 클레이 PNG 사용.
bool hasFullClayBundledArtForTarotCardId(int cardId) {
  return majorClayAssetPathForTarotCardId(cardId) != null ||
      minorClayAssetPathForTarotCardId(cardId) != null;
}
