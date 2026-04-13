import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/gggom_offline_landing.dart';
import 'korea_traditional_major_assets.dart';
import 'major_clay_assets.dart';
import 'minor_clay_assets.dart';

export 'korea_traditional_major_assets.dart';

/// Next.js `cardThemes.ts`와 동일한 파일 규칙.
/// [assetOrigin]이 비면 [kGggomBundledPublicRoot] 에셋을 씁니다.
const String defaultThemeId = 'default';

/// 웹 `cardThemes.ts` 및 원격 URL·번들 경로와 동일한 ID. 상점/가방 목록에는 넣지 않아도
/// [getCardImageUrl]·[getBundledSiteCardAssetPath] 규칙은 유지합니다.
const String koreanClayThemeId = 'korean-clay';

/// `assets/major/` 클레이 메이저 22장 + id 82·83 확장 2장 (총 24일러).
const String majorClayThemeId = 'major-clay';

/// 상점·가방 카드 덱 ID — [koreaTraditionalMajorAssetPath] 22장.
const String koreaTraditionalMajorThemeId = 'korea-traditional-major';

/// RW **마이너 전체** + **보유 한국전통 메이저 조각**만 합쳐 섞는 팬 덱. (`deck_card_catalog.dart` 참고)
const String mixedMinorKoreaTraditionalMajorThemeId = 'mixed-minor-korea-major';

const _majorFiles = <int, String>{
  0: '00_fool.png',
  1: '01_magician.png',
  2: '02_high_priestess.png',
  3: '03_empress.png',
  4: '04_emperor.png',
  5: '05_hierophant.png',
  6: '06_lovers.png',
  7: '07_chariot.png',
  8: '08_strength.png',
  9: '09_hermit.png',
  10: '10_wheel.png',
  11: '11_justice.png',
  12: '12_hanged_man.png',
  13: '13_death.png',
  14: '14_temperance.png',
  15: '15_devil.png',
  16: '16_tower.png',
  17: '17_star.png',
  18: '18_moon.png',
  19: '19_sun.png',
  20: '20_judgement.png',
  21: '21_world.png',
};

const _fnRank = [
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

const _specialFiles = <int, String>{
  78: '78_son_of_wands.png',
  79: '79_daughter_of_pentacles.png',
  80: '80_daughter_of_cups.png',
  81: '81_son_of_swords.png',
  82: '82_mother_earth_water.png',
  83: '83_father_fire_air.png',
};

String? _fileForCardId(int cardId) {
  final m = _majorFiles[cardId];
  if (m != null) return m;
  if (cardId >= 22 && cardId <= 77) {
    final off = cardId - 22;
    final suitIdx = off ~/ 14;
    final rankIdx = off % 14;
    const suits = ['wands', 'cups', 'swords', 'pentacles'];
    return '${cardId}_${_fnRank[rankIdx]}_${suits[suitIdx]}.png';
  }
  return _specialFiles[cardId];
}

/// 한국 클레이 테마: 메이저 0~15만 매핑 (웹과 동일).
const koreanClayFiles = <int, String>{
  0: '00_fool.png',
  1: '01_magician.png',
  2: '02_high_priestess.png',
  3: '03_empress.png',
  4: '04_emperor.png',
  5: '05_hierophant.png',
  6: '06_lovers.png',
  7: '07_chariot.png',
  8: '08_strength.png',
  9: '09_hermit.png',
  10: '10_wheel.png',
  11: '11_justice.png',
  12: '12_hanged_man.png',
  13: '13_death.png',
  14: '14_temperance.png',
  15: '15_devil.png',
};

/// [assetOrigin] 예: `https://my-site.com` 또는 로컬 Next 서버 `http://10.0.2.2:3000`
String? getCardImageUrl({
  required String themeId,
  required int cardId,
  required String assetOrigin,
}) {
  if (themeId == koreaTraditionalMajorThemeId || themeId == majorClayThemeId) {
    return null;
  }
  // 웹 정적 배포(Vercel 등)에는 프로덕션 사이트의 /cards/ 경로가 없을 수 있음.
  // 이 경우 Image.network 실패 → 이모지만 보임. 번들 assets/www_gggom/cards/ 를 쓴다.
  if (kIsWeb) {
    return null;
  }
  if (assetOrigin.isEmpty) return null;
  final base = assetOrigin.replaceAll(RegExp(r'/$'), '');
  String? filename;
  String folder;
  if (themeId == koreanClayThemeId) {
    filename = koreanClayFiles[cardId];
    folder = 'korean-clay';
  } else {
    filename = _fileForCardId(cardId);
    folder = 'default';
  }
  if (filename == null) return null;
  return '$base/cards/$folder/$filename';
}

/// `www.gggom0505.kr` 에서 복제한 로컬 카드 PNG ([kGggomBundledPublicRoot]).
String? getBundledSiteCardAssetPath({
  required String themeId,
  required int cardId,
}) {
  if (themeId == koreaTraditionalMajorThemeId) {
    return koreaTraditionalMajorAssetPath(cardId);
  }
  if (themeId == majorClayThemeId) {
    final maj = majorClayAssetPathForTarotCardId(cardId);
    if (maj != null) {
      return maj;
    }
    final mino = minorClayAssetPathForTarotCardId(cardId);
    if (mino != null) {
      return mino;
    }
    final filename = _fileForCardId(cardId);
    if (filename == null) {
      return null;
    }
    return '$kGggomBundledPublicRoot/cards/default/$filename';
  }
  String? filename;
  String folder;
  if (themeId == koreanClayThemeId) {
    filename = koreanClayFiles[cardId];
    folder = 'korean-clay';
  } else {
    filename = _fileForCardId(cardId);
    folder = 'default';
  }
  if (filename == null) return null;
  return '$kGggomBundledPublicRoot/cards/$folder/$filename';
}

/// 가방/상점 썸네일용 (`CARD_THEMES.thumbnail` 규칙).
const Map<String, String> kCardThemeThumbnailPath = {
  defaultThemeId: '/cards/default/00_fool.png',
  koreanClayThemeId: '/cards/korean-clay/00_fool.png',
  majorClayThemeId: kMajorClayShopThumbnailAsset,
  koreaTraditionalMajorThemeId: kKoreaTraditionalMajorShopThumbnailAsset,
  mixedMinorKoreaTraditionalMajorThemeId: '/cards/default/22_ace_wands.png',
};

String? resolveGggomBundledSitePath(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return null;
  }
  final normalized = path.startsWith('/') ? path.substring(1) : path;
  if (normalized.startsWith('oracle_cards/')) {
    final rest = normalized.substring('oracle_cards/'.length);
    return 'assets/oracle/$rest';
  }
  if (normalized.startsWith('assets/major/') ||
      normalized.startsWith('assets/cards/minor_number_clay/') ||
      normalized.startsWith('assets/cards/minor_court_clay/') ||
      normalized.startsWith('assets/koreacard/')) {
    return normalized;
  }
  if (normalized.startsWith('cards/') || normalized.startsWith('card_backs/')) {
    return '$kGggomBundledPublicRoot/$normalized';
  }
  return null;
}

/// `/assets/...` 처럼 앞에 슬래시만 다른 경우 [Image.asset] 키 `assets/...` 로 맞춥니다.
/// 그렇지 않으면 상대 경로가 [AppConfig.assetOrigin] 과 붙어 네트워크 URL이 되어
/// Flutter 웹·정적 호스트에서 404·빈 이미지가 납니다.
String normalizeFlutterBundledAssetKey(String path) {
  final t = path.trim();
  if (t.isEmpty) {
    return t;
  }
  if (t.startsWith('http://') ||
      t.startsWith('https://') ||
      t.startsWith('file://') ||
      t.startsWith('data:image/')) {
    return t;
  }
  var noLeadingSlashes = t.replaceFirst(RegExp(r'^/+'), '');
  if (noLeadingSlashes.startsWith('assets/')) {
    // 잘못 중첩된 키(`assets/assets/...`)를 단일 키로 정규화해
    // Flutter web 요청 경로가 `assets/assets/assets/...`가 되는 문제를 막는다.
    while (noLeadingSlashes.startsWith('assets/assets/')) {
      noLeadingSlashes = noLeadingSlashes.substring('assets/'.length);
    }
    return noLeadingSlashes;
  }
  return t;
}

String? resolvePublicAssetUrl(String path, String assetOrigin) {
  var t = path.trim();
  if (t.startsWith('http://') || t.startsWith('https://')) {
    return t;
  }
  final noLead = t.replaceFirst(RegExp(r'^/+'), '');
  if (noLead.startsWith('oracle_cards/')) {
    t = 'assets/oracle/${noLead.substring('oracle_cards/'.length)}';
  }
  final asBundled = normalizeFlutterBundledAssetKey(t);
  if (asBundled.startsWith('assets/')) {
    final o = assetOrigin.replaceAll(RegExp(r'/$'), '');
    if (o.isNotEmpty) {
      // Flutter web 번들 에셋 실제 서빙 경로: /assets/<asset-key>
      // asset-key 자체가 assets/... 이므로 최종 URL은 /assets/assets/... 형태가 됩니다.
      return '$o/assets/$asBundled';
    }
    return asBundled;
  }
  final o = assetOrigin.replaceAll(RegExp(r'/$'), '');
  if (o.isNotEmpty) {
    final p = asBundled.startsWith('/') ? asBundled : '/$asBundled';
    return '$o$p';
  }
  return resolveGggomBundledSitePath(asBundled);
}

/// 상점·가방 아이템 썸네일 — `file://`, `data:image/...` 는 그대로 두고 상대 경로만 오리진과 결합합니다.
String? resolveShopItemThumbnailSrc(String? raw, String assetOrigin) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  final t = raw.trim();
  if (t.startsWith('http://') || t.startsWith('https://')) {
    return t;
  }
  if (t.startsWith('file://')) {
    return t;
  }
  if (t.startsWith('data:image/')) {
    return t;
  }
  return resolvePublicAssetUrl(t, assetOrigin);
}
