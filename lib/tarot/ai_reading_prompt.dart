import '../data/card_themes.dart'
    show
        koreaTraditionalMajorThemeId,
        koreanClayThemeId,
        majorClayThemeId,
        mixedMinorKoreaTraditionalMajorThemeId;
import '../data/tarot_cards.dart';

/// 3×3 슬롯 수 ([TarotTab]과 동기).
const int kTarotAiReadingSlotCount = 9;

/// 격자 위치 안내 (슬롯 1~9, 행 우선).
const List<String> kTarotAiReadingSlotGridHintsKo = [
  '윗줄·왼', '윗줄·중', '윗줄·오',
  '중간·왼', '중간·중', '중간·오',
  '아랫줄·왼', '아랫줄·중', '아랫줄·오',
];

String tarotAiReadingDeckStyleNoteKo(String equippedCardThemeId) {
  return switch (equippedCardThemeId) {
    koreaTraditionalMajorThemeId =>
      '덱: 한국 전통 메이저 아르카나 일러스트(의미는 일반적인 라이더·웨이트식 메이저와 대응).',
    mixedMinorKoreaTraditionalMajorThemeId =>
      '덱: 혼합 풀 — 앱 내 라이더·웨이트형 마이너 전체 + 사용자가 보유한 한국 전통 메이저만; '
          '메이저는 한국화, 마이너는 기본 덱 그림.',
    majorClayThemeId =>
      '덱: 메이저 0~21 앞면은 한국 전통 아르카나, 확장(82~83)은 3D 클레이; '
          '마이너·궁정 60슬롯은 3D 클레이(RW 22~77 + 자녀 78~81).',
    koreanClayThemeId => '덱: 한국 클레이 일러스트 타로(메이저 위주).',
    _ => '덱: 앱 기본 타로(이번 판은 메이저 22장 부분 집합).',
  };
}

/// 앞면으로 뒤집힌 슬롯만 모아 클립보드에 넣을 짧은 프롬프트를 만듭니다.
/// 사용자가 외부 AI에 붙여 넣고 직접 질문합니다.
///
/// [placed]는 길이 9, 값은 [deck22] 안의 인덱스(팬 덱 순서).
/// 뒤집힌 카드가 없으면 `null`.
String? buildTarotAiReadingPrompt({
  required List<int?> placed,
  required Set<int> flippedSlots,
  required List<TarotCard> deck22,
  required String equippedCardThemeId,
}) {
  assert(placed.length == kTarotAiReadingSlotCount);
  final cardLines = <String>[];
  for (var s = 0; s < kTarotAiReadingSlotCount; s++) {
    final di = placed[s];
    if (di == null || !flippedSlots.contains(s)) {
      continue;
    }
    if (di < 0 || di >= deck22.length) {
      continue;
    }
    final card = deck22[di];
    final suit = card.suit;
    final arcanaLine =
        suit != null ? '${card.arcana} · $suit' : card.arcana;
    final hint = kTarotAiReadingSlotGridHintsKo[s];
    cardLines.add(
      '• 슬롯 ${s + 1} ($hint): 카드 번호 ${card.id} · ${card.nameKo} (${card.name}) — $arcanaLine',
    );
  }
  if (cardLines.isEmpty) {
    return null;
  }
  final header = '''
공공곰타로덱 · 3×3 타로 스프레드
아래는 앞면으로 공개된 카드입니다. 이 블록을 복사한 뒤 ChatGPT·제미나이 등에 붙여 넣고, 이어서 하고 싶은 질문을 직접 적어 주세요.

${tarotAiReadingDeckStyleNoteKo(equippedCardThemeId)}

[공개 카드]'''.trim();
  return '$header\n${cardLines.join('\n')}';
}
