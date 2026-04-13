import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/data/card_collection_grade.dart';

void main() {
  test('등급 순서: 마이너 일반 < 궁정 < 메이저 < 한국전통 메이저', () {
    expect(CardCollectionGrade.minorNumber.tier < CardCollectionGrade.minorCourt.tier, isTrue);
    expect(CardCollectionGrade.minorCourt.tier < CardCollectionGrade.majorArcana.tier, isTrue);
    expect(CardCollectionGrade.majorArcana.tier < CardCollectionGrade.koreaTraditionalMajor.tier, isTrue);
    expect(CardCollectionGrade.koreaTraditionalMajor.tier, 3);
  });

  test('Tarot id 예시', () {
    expect(collectionGradeForTarotCardId(50), CardCollectionGrade.minorNumber); // 검 에이스
    expect(collectionGradeForTarotCardId(80), CardCollectionGrade.minorCourt); // Daughter of Cups
    expect(collectionGradeForTarotCardId(0), CardCollectionGrade.majorArcana);
    expect(collectionGradeForTarotCardId(82), CardCollectionGrade.majorArcana);
  });

  test('상점 타입: 한국전통 메이저만 최상 등급 매핑', () {
    expect(
      collectionGradeForShopItemType('korea_major_card'),
      CardCollectionGrade.koreaTraditionalMajor,
    );
    expect(collectionGradeForShopItemType('card'), isNull);
  });
}
