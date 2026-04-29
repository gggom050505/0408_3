import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/data/deck_card_catalog.dart';
import 'package:gggom_tarot/data/tarot_cards.dart';

void main() {
  test('혼합 풀: 마이너 56 + 보유 한국 메이저만', () {
    final pool = buildMixedMinorAndKoreaTraditionalDrawPool(
      ownedKoreaMajorIds: {0, 21},
    );
    expect(pool.length, 58);
    expect(pool.where((c) => c.arcana == 'minor').length, 56);
    expect(
      pool.where((c) => c.arcana == 'major').map((c) => c.id).toSet(),
      {0, 21},
    );
  });

  test('tarotCardsForFamilies: oracle enum은 TarotCard를 늘리지 않음', () {
    final pool = tarotCardsForFamilies(
      {DeckCardFamily.oracleEighty},
      ownedKoreaMajorIds: {},
    );
    expect(pool, isEmpty);
  });

  test('카탈로그 총장: 84 + 오라클 80 정의', () {
    expect(kCatalogStandardTarotDeckCardCount, tarotDeck.length);
    expect(kCatalogOracleCardCount, 80);
    expect(kCatalogMinorClayIllustrationCount, 60);
  });

  test('메이저/마이너/특수: arcana로만 구분(56·22·6)', () {
    final majors = tarotDeck.where(isStandardMajorArcanaTarotCard).toList();
    final minors = tarotDeck.where(isStandardMinorArcanaTarotCard).toList();
    final specials = tarotDeck.where(isStandardSpecialArcanaTarotCard).toList();
    expect(majors.length, kCatalogStandardMajorArcanaCount);
    expect(minors.length, kCatalogStandardMinorArcanaCount);
    expect(specials.length, kCatalogStandardSpecialArcanaCount);
    expect(kCatalogStandardMajorArcanaCount == 24, isFalse);
    expect(kCatalogStandardMinorArcanaCount == 50, isFalse);
  });

  test('한국전통 덱 앞면: 메이저 0~21 전원 한국전통, 마이너는 클레이', () {
    final majorAny = tarotDeck.firstWhere((c) => c.id == 3);
    final minor = tarotDeck.firstWhere((c) => c.arcana == 'minor');

    expect(
      resolveFrontThemeForKoreaTraditionalDeckCard(majorAny),
      'korea-traditional-major',
    );
    expect(
      resolveFrontThemeForKoreaTraditionalDeckCard(minor),
      'major-clay',
    );
  });
}
