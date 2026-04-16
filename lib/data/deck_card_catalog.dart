import 'package:flutter/foundation.dart' show immutable;

import 'card_themes.dart';
import 'minor_clay_assets.dart';
import 'tarot_cards.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 마이너 vs 메이저 — **구분은 확실함**, 장 **수**는 말씀하신 50·24와 다름
// ═══════════════════════════════════════════════════════════════════════════
//
// * **구분 방법:** [TarotCard.arcana] — `minor` = 마이너(소아카나), `major` = 메이저,
//   `special` = 본 앱 확장 6장(일반 RW의 메이저/마이너와는 별칭).
// * **코드 정본 장 수:** 마이너 **56장** (id 22~77, `arcana: minor`), 메이저 **22장** (0~21),
//   특수 **6장** (78~83, `arcana: special`). 합계 84 = [tarotDeck].
// * **클레이 일러(`major-clay` 덱):** 마이너 **60장** — 숫자 40 `assets/cards/minor_number_clay/`,
//   궁정·확장 20 `assets/cards/minor_court_clay/` ([minor_clay_assets.dart], 각 manifest.json).
// * 사용자 구술과 숫자가 다르면 **이 주석·`kCatalog*` 상수**를 우선한다.
// ═══════════════════════════════════════════════════════════════════════════

/// Rider–Waite 계열 **메이저** — [TarotCard] id 0~21, [TarotCard.arcana] == `major`.
const int kCatalogStandardMajorArcanaCount = 22;

/// Rider–Waite 계열 **마이너** — id 22~77, 네 슈트×14, [TarotCard.arcana] == `minor`.
const int kCatalogStandardMinorArcanaCount = 56;

/// 확장 **특수** 카드 — id 78~83, [TarotCard.arcana] == `special`.
const int kCatalogStandardSpecialArcanaCount = 6;

/// [tarotDeck] 전체 (메이저+마이너+특수).
const int kCatalogStandardTarotDeckCardCount =
    kCatalogStandardMajorArcanaCount +
    kCatalogStandardMinorArcanaCount +
    kCatalogStandardSpecialArcanaCount; // 84

/// 한국전통 메이저 에셋 — 상점 `korea_major_card` 조각 22종, id 0~21과 대응.
/// 번들 경로: [korea_traditional_major_assets.dart].
const int kCatalogKoreaTraditionalMajorCount = 22;

/// 오라클 — 상점 `oracle_card` 번호 1~80 (`oracle-card-01` …), [TarotCard]와 별도.
const int kCatalogOracleCardCount = 80;

/// 클레이 마이너·확장 코트 일러 — [minor_clay_assets.dart], id **22~81** (60장).
const int kCatalogMinorClayIllustrationCount = 60;

/// 클레이 마이너 중 **에이스~10** (40장, Tarot id 22~31·36~45·50~59·64~73).
const int kCatalogMinorClayNumberIllustrationCount = 40;

/// 클레이 **궁정·확장**(20장: 페이지~킹 16 + id 78~81 special 4).
const int kCatalogMinorClayCourtIllustrationCount = 20;

/// 앱에서 다루는 **논리적 덱 계열** (에이전트·기능 공통 어휘).
enum DeckCardFamily {
  /// RW 메이저만 (TarotCard, major)
  standardMajorArcana,

  /// RW 마이너만 (TarotCard, minor)
  standardMinorArcana,

  /// RW 특수 6장 (TarotCard, special)
  standardSpecialArcana,

  /// 한국전통 메이저 조각 (동일하게 TarotCard id 0~21 · 에셋만 다름)
  koreaTraditionalMajor,

  /// 오라클 80장 — 이 열거에는 포함하지 않고 [kCatalogOracleCardCount]·상점 타입으로만 관리.
  oracleEighty,
}

@immutable
class DeckCardFamilyStats {
  const DeckCardFamilyStats({
    required this.family,
    required this.canonicalCount,
    required this.notes,
  });

  final DeckCardFamily family;
  final int canonicalCount;
  final String notes;
}

/// UI·프롬프트용 요약 (장 수 정본).
const List<DeckCardFamilyStats> kDeckCardFamilyStats = [
  DeckCardFamilyStats(
    family: DeckCardFamily.standardMajorArcana,
    canonicalCount: kCatalogStandardMajorArcanaCount,
    notes: 'RW 메이저 · TarotCard id 0~21',
  ),
  DeckCardFamilyStats(
    family: DeckCardFamily.standardMinorArcana,
    canonicalCount: kCatalogStandardMinorArcanaCount,
    notes: 'RW 마이너 · TarotCard id 22~77',
  ),
  DeckCardFamilyStats(
    family: DeckCardFamily.standardSpecialArcana,
    canonicalCount: kCatalogStandardSpecialArcanaCount,
    notes: '확장 특수 · TarotCard id 78~83',
  ),
  DeckCardFamilyStats(
    family: DeckCardFamily.koreaTraditionalMajor,
    canonicalCount: kCatalogKoreaTraditionalMajorCount,
    notes: '한국전통 메이저 에셋 · 상점 type korea_major_card',
  ),
  DeckCardFamilyStats(
    family: DeckCardFamily.oracleEighty,
    canonicalCount: kCatalogOracleCardCount,
    notes: '오라클 · 상점 type oracle_card, Tarot 탭 팬 덱과 별개',
  ),
];

DeckCardFamily? deckFamilyOfTarotCard(TarotCard card) {
  return switch (card.arcana) {
    'major' => DeckCardFamily.standardMajorArcana,
    'minor' => DeckCardFamily.standardMinorArcana,
    'special' => DeckCardFamily.standardSpecialArcana,
    _ => null,
  };
}

/// RW **메이저 아르카나**만 (`major`). — 22장, id 0~21.
bool isStandardMajorArcanaTarotCard(TarotCard c) => c.arcana == 'major';

/// RW **마이너 아르카나**만 (`minor`). — 56장, id 22~77.
bool isStandardMinorArcanaTarotCard(TarotCard c) => c.arcana == 'minor';

/// 확장 **특수** 6장 (`special`). 메이저·마이너와 **별도** 취급.
bool isStandardSpecialArcanaTarotCard(TarotCard c) => c.arcana == 'special';

bool _isKoreaEligibleMajor(TarotCard c, Set<int> ownedKoreaMajorIds) =>
    c.arcana == 'major' &&
    c.id >= 0 &&
    c.id <= 21 &&
    ownedKoreaMajorIds.contains(c.id);

/// [DeckCardFamily.koreaTraditionalMajor]는 **보유 조각 id**로 필터한 메이저 [TarotCard]만 포함.
///
/// 오라클은 [TarotCard]가 아니므로 여기 넣지 않음.
List<TarotCard> tarotCardsForFamilies(
  Set<DeckCardFamily> families, {
  required Set<int> ownedKoreaMajorIds,
}) {
  final out = <TarotCard>[];
  final seen = <int>{};

  void addIfNew(TarotCard c) {
    if (seen.add(c.id)) {
      out.add(c);
    }
  }

  if (families.contains(DeckCardFamily.standardMajorArcana)) {
    for (final c in tarotDeck) {
      if (c.arcana == 'major') {
        addIfNew(c);
      }
    }
  }
  if (families.contains(DeckCardFamily.standardMinorArcana)) {
    for (final c in tarotDeck) {
      if (isStandardMinorArcanaTarotCard(c)) {
        addIfNew(c);
      }
    }
  }
  if (families.contains(DeckCardFamily.standardSpecialArcana)) {
    for (final c in tarotDeck) {
      if (c.arcana == 'special') {
        addIfNew(c);
      }
    }
  }
  if (families.contains(DeckCardFamily.koreaTraditionalMajor)) {
    for (final c in tarotMajorArcanaOnly) {
      if (ownedKoreaMajorIds.contains(c.id)) {
        addIfNew(c);
      }
    }
  }
  return out;
}

/// `mixed-minor-korea-major` 팬 덱용 원천: 마이너 전체 + **보유 중인** 한국전통 메이저.
List<TarotCard> buildMixedMinorAndKoreaTraditionalDrawPool({
  required Set<int> ownedKoreaMajorIds,
}) {
  return tarotCardsForFamilies({
    DeckCardFamily.standardMinorArcana,
    DeckCardFamily.koreaTraditionalMajor,
  }, ownedKoreaMajorIds: ownedKoreaMajorIds);
}

/// `korea-traditional-major` 덱용 원천: 클레이 마이너 60장 + 한국전통 메이저 22장(전체).
List<TarotCard> buildMinorClayAndKoreaTraditionalFullDrawPool() {
  final byId = {for (final c in tarotDeck) c.id: c};
  final out = <TarotCard>[];
  final used = <int>{};

  void addById(int id) {
    final card = byId[id];
    if (card == null || used.contains(id)) return;
    used.add(id);
    out.add(card);
  }

  for (final id in [...kMinorClayTarotCardIds]..sort()) {
    addById(id);
  }
  for (var id = 0; id <= 21; id++) {
    addById(id);
  }
  return out;
}

/// `korea-traditional-major` 덱 세션 복원 시 허용 카드인지(마이너60 + 한국전통 메이저22).
bool tarotCardAllowedInKoreaTraditionalMajorFullPool(TarotCard c) {
  final isMinorClay = kMinorClayTarotCardIds.contains(c.id);
  final isKoreaMajor = c.id >= 0 && c.id <= 21 && c.arcana == 'major';
  return isMinorClay || isKoreaMajor;
}

/// 혼합 덱 세션 복원 시 덱에 들어있어도 되는 카드인지.
bool tarotCardAllowedInMixedMinorKoreaPool(
  TarotCard c,
  Set<int> ownedKoreaMajorIds,
) {
  return isStandardMinorArcanaTarotCard(c) ||
      _isKoreaEligibleMajor(c, ownedKoreaMajorIds);
}

/// 한국전통 메이저 덱 선택 시 카드 앞면 테마를 결정한다.
///
/// - 메이저(0~21) 중 보유한 한국전통 조각 번호는 `korea-traditional-major` 우선 적용
/// - 그 외 메이저/마이너는 `major-clay`로 보완
String resolveFrontThemeForKoreaTraditionalDeckCard(
  TarotCard card,
  Set<int> ownedKoreaMajorIds,
) {
  final canUseKoreaMajor =
      card.arcana == 'major' &&
      card.id >= 0 &&
      card.id <= 21 &&
      ownedKoreaMajorIds.contains(card.id);
  if (canUseKoreaMajor) {
    return koreaTraditionalMajorThemeId;
  }
  return majorClayThemeId;
}
