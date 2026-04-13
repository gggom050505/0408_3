import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/data/tarot_cards.dart';
import 'package:gggom_tarot/tarot/ai_reading_prompt.dart';

void main() {
  test('AI 리딩 프롬프트: 임의 배치·뒤집힌 카드가 프롬프트에 반영됨', () {
    final rng = Random(42);
    final deck22 = List<TarotCard>.from(tarotDeck.take(22));

    for (var i = deck22.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final t = deck22[i];
      deck22[i] = deck22[j];
      deck22[j] = t;
    }

    final placed = List<int?>.filled(kTarotAiReadingSlotCount, null);
    final flipped = <int>{};

    final slots = List<int>.generate(kTarotAiReadingSlotCount, (i) => i)
      ..shuffle(rng);
    final n = 3 + rng.nextInt(4);
    for (var k = 0; k < n; k++) {
      final slot = slots[k];
      placed[slot] = k;
      flipped.add(slot);
    }

    final prompt = buildTarotAiReadingPrompt(
      placed: placed,
      flippedSlots: flipped,
      deck22: deck22,
      equippedCardThemeId: 'default',
    );

    expect(prompt, isNotNull);
    for (var k = 0; k < n; k++) {
      final slot = slots[k];
      final card = deck22[k];
      expect(prompt!, contains(card.nameKo));
      expect(prompt, contains('슬롯 ${slot + 1}'));
      expect(prompt, contains('카드 번호 ${card.id}'));
    }
    expect(prompt, contains('[공개 카드]'));
    expect(prompt, contains('공공곰타로덱'));
  });

  test('AI 리딩 프롬프트: 뒤집힌 카드 없으면 null', () {
    final deck22 = tarotDeck.take(22).toList();
    final placed = List<int?>.filled(kTarotAiReadingSlotCount, null)..[0] = 0;
    final prompt = buildTarotAiReadingPrompt(
      placed: placed,
      flippedSlots: {},
      deck22: deck22,
      equippedCardThemeId: 'default',
    );
    expect(prompt, isNull);
  });
}
