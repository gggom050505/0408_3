import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/standalone/tarot_session_restore.dart';

void main() {
  test('tryRestoreTarotSessionV1FromMap: 장착 메타와 무관하게 덱·슬롯 복원', () {
    final deckIds = List<int>.generate(tarotSessionDeckCount, (i) => i);
    final placed = <dynamic>[0, ...List<dynamic>.filled(tarotSessionSlotCount - 1, null)];

    final data = tryRestoreTarotSessionV1FromMap({
      'version': 1,
      'equipped_card_theme': 'default',
      'equipped_mat': 'default-mint',
      'equipped_card_back': 'default-card-back',
      'deck_card_ids': deckIds,
      'placed': placed,
      'flipped': <int>[],
    });

    expect(data, isNotNull);
    expect(data!.deckCardIds, deckIds);
    expect(data.placedDeckIndices.first, 0);
    expect(data.placedDeckIndices[1], isNull);
    expect(data.flippedSlots, isEmpty);
  });

  test('tryRestoreTarotSessionV1FromMap: 저장 맵에 다른 equipped_* 가 있어도 파싱됨', () {
    final deckIds = List<int>.generate(tarotSessionDeckCount, (i) => i);
    final placed = List<dynamic>.filled(tarotSessionSlotCount, null);

    final data = tryRestoreTarotSessionV1FromMap({
      'version': 1,
      'equipped_card_theme': 'will-be-ignored',
      'equipped_mat': 'obsolete-mat',
      'equipped_card_back': 'other-back',
      'deck_card_ids': deckIds,
      'placed': placed,
      'flipped': <int>[],
    });

    expect(data, isNotNull);
    expect(data!.deckCardIds, deckIds);
  });

  test('tryRestoreTarotSessionV1FromMap: 잘못된 슬롯 인덱스는 null', () {
    expect(
      tryRestoreTarotSessionV1FromMap({
        'version': 1,
        'deck_card_ids': List<int>.generate(tarotSessionDeckCount, (i) => i),
        'placed': List<dynamic>.filled(tarotSessionSlotCount, null),
        'flipped': [0],
      }),
      isNull,
    );
  });

  test('tryRestoreTarotSessionV1FromMap: 덱 카드 id가 덱에 없으면 null', () {
    expect(
      tryRestoreTarotSessionV1FromMap({
        'version': 1,
        'deck_card_ids': List<int>.filled(tarotSessionDeckCount, 99999),
        'placed': List<dynamic>.filled(tarotSessionSlotCount, null),
        'flipped': <int>[],
      }),
      isNull,
    );
  });
}
