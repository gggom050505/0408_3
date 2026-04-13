/// 수집·희귀도용 **카드 등급** (낮음 → 높음).
///
/// 정책 (사용자 확정):  
/// **마이너 일반** → **마이너 궁정** → **메이저** → **한국전통 메이저** (최상).
library;

import 'minor_clay_assets.dart';

/// 등급이 높을수록 [tier] 값이 큼 (0~3). 정렬 시 **높은 등급 먼저**면 `b.tier.compareTo(a.tier)`.
enum CardCollectionGrade {
  /// 마이너 숫자 카드 (에이스~10, Tarot id 22~31·36~45·50~59·64~73).
  minorNumber(0, '마이너 일반'),

  /// 마이너 궁정 + 확장 Son/Daughter (페이지~킹 16장 + id 78~81).
  minorCourt(1, '마이너 궁정'),

  /// RW 메이저 22장 (0~21) 및 클레이 확장 메이저 일러(id 82~83).
  majorArcana(2, '메이저'),

  /// 한국전통 메이저 조각·에셋 (상점 `korea_major_card`, 최상 등급).
  koreaTraditionalMajor(3, '한국전통 메이저');

  const CardCollectionGrade(this.tier, this.labelKo);

  /// 0 = 최하, 3 = 최상 (한국전통 메이저).
  final int tier;

  final String labelKo;
}

/// Tarot 카드 id → 등급. 메이저·마이너·확장 규칙은 [minor_clay_assets]·덱 정의와 맞춤.
///
/// * 0~21, 82~83 → [CardCollectionGrade.majorArcana]
/// * 22~77 중 숫자(에이스~10) → [CardCollectionGrade.minorNumber]
/// * 22~77 중 궁정(페이지~킹), 78~81 → [CardCollectionGrade.minorCourt]
/// * 그 외 → `null`
CardCollectionGrade? collectionGradeForTarotCardId(int cardId) {
  if (cardId >= 0 && cardId <= 21) {
    return CardCollectionGrade.majorArcana;
  }
  if (cardId >= 82 && cardId <= 83) {
    return CardCollectionGrade.majorArcana;
  }
  if (cardId >= 22 && cardId <= 81) {
    return switch (minorClayKindForTarotCardId(cardId)) {
      MinorClayImageKind.number => CardCollectionGrade.minorNumber,
      MinorClayImageKind.court => CardCollectionGrade.minorCourt,
      null => null,
    };
  }
  return null;
}

/// 가방·개인 상점 등 — 상점 [itemType] 기준 등급.
///
/// * `korea_major_card` → [CardCollectionGrade.koreaTraditionalMajor]
/// * 그 외 타입(덱 테마 `card`, 오라클, 매트 등)은 카드 한 장 등급으로 특정하기 어려워 `null`.
CardCollectionGrade? collectionGradeForShopItemType(String itemType) {
  return switch (itemType) {
    'korea_major_card' => CardCollectionGrade.koreaTraditionalMajor,
    _ => null,
  };
}

/// 등급 높은 쪽이 양수 (a보다 b가 더 높으면 양수).
int compareCollectionGradeTier(
  CardCollectionGrade a,
  CardCollectionGrade b,
) =>
    b.tier.compareTo(a.tier);
