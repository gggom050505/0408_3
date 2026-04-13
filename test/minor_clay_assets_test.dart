import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/data/deck_card_catalog.dart';
import 'package:gggom_tarot/data/minor_clay_assets.dart';

void main() {
  test('마이너 클레이 60장 = 숫자 40 + 궁정 20', () {
    expect(kMinorClayTarotCardIds.length, kCatalogMinorClayIllustrationCount);
    expect(kMinorNumberClayTarotCardIds.length,
        kCatalogMinorClayNumberIllustrationCount);
    expect(kMinorCourtClayTarotCardIds.length,
        kCatalogMinorClayCourtIllustrationCount);
    expect(kCatalogMinorClayIllustrationCount, 60);

    for (final id in kMinorNumberClayTarotCardIds) {
      expect(minorClayKindForTarotCardId(id), MinorClayImageKind.number);
      expect(minorNumberClayAssetPathForTarotCardId(id), isNotNull);
      expect(minorCourtClayAssetPathForTarotCardId(id), isNull);
    }
    for (final id in kMinorCourtClayTarotCardIds) {
      expect(minorClayKindForTarotCardId(id), MinorClayImageKind.court);
      expect(minorCourtClayAssetPathForTarotCardId(id), isNotNull);
      expect(minorNumberClayAssetPathForTarotCardId(id), isNull);
    }
    for (final id in kMinorClayTarotCardIds) {
      expect(minorClayAssetPathForTarotCardId(id), isNotNull);
    }
    expect(minorClayAssetPathForTarotCardId(21), isNull);
    expect(minorClayAssetPathForTarotCardId(82), isNull);

    expect(
      minorNumberClayAssetPathForTarotCardId(50),
      'assets/cards/minor_number_clay/swords/ace.png',
    );
    expect(
      minorClayPublicUrlPathForTarotCardId(50),
      '/cards/minor_number_clay/swords/ace.png',
    );

    expect(
      minorCourtClayAssetPathForTarotCardId(80),
      'assets/cards/minor_court_clay/special/daughter_of_cups.png',
    );
    expect(
      minorClayPublicUrlPathForTarotCardId(80),
      '/cards/minor_court_clay/special/daughter_of_cups.png',
    );
  });
}
