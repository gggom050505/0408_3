import '../data/tarot_cards.dart';

/// [TarotTab]과 동기: 슬롯 수·덱 장 수.
const tarotSessionSlotCount = 9;
const tarotSessionDeckCount = 22;

/// 디스크에서 읽은 세션 맵에서 덱·배치·뒤집힘만 검증합니다.
/// `equipped_*` 필드는 검사하지 않습니다(상점에서 바뀐 뒤에도 복원 가능).
class TarotSessionBoardData {
  const TarotSessionBoardData({
    required this.deckCardIds,
    required this.placedDeckIndices,
    required this.flippedSlots,
  });

  final List<int> deckCardIds;
  final List<int?> placedDeckIndices;
  final Set<int> flippedSlots;
}

TarotSessionBoardData? tryRestoreTarotSessionV1FromMap(Map<String, dynamic> map) {
  if ((map['version'] as num?)?.toInt() != 1) {
    return null;
  }
  final ids = map['deck_card_ids'] as List<dynamic>?;
  if (ids == null || ids.length != tarotSessionDeckCount) {
    return null;
  }
  final byId = {for (final c in tarotDeck) c.id: c};
  final deckIds = <int>[];
  for (final e in ids) {
    final id = (e as num).toInt();
    final c = byId[id];
    if (c == null) {
      return null;
    }
    deckIds.add(id);
  }
  var placedRaw = map['placed'] as List<dynamic>?;
  if (placedRaw == null) {
    return null;
  }
  // 예전 3+3+5(11칸) 세션 → 상단 9칸만 이어받기
  if (placedRaw.length == 11) {
    placedRaw = placedRaw.sublist(0, tarotSessionSlotCount);
  }
  if (placedRaw.length != tarotSessionSlotCount) {
    return null;
  }
  final newPlaced = List<int?>.filled(tarotSessionSlotCount, null);
  final usedIdx = <int>{};
  for (var i = 0; i < tarotSessionSlotCount; i++) {
    final v = placedRaw[i];
    if (v == null) {
      continue;
    }
    final di = (v as num).toInt();
    if (di < 0 || di >= tarotSessionDeckCount || usedIdx.contains(di)) {
      return null;
    }
    usedIdx.add(di);
    newPlaced[i] = di;
  }
  final flippedRaw = map['flipped'] as List<dynamic>? ?? [];
  final newFlipped = <int>{};
  for (final e in flippedRaw) {
    final s = (e as num).toInt();
    if (s < 0 || s >= tarotSessionSlotCount || newPlaced[s] == null) {
      return null;
    }
    newFlipped.add(s);
  }
  return TarotSessionBoardData(
    deckCardIds: deckIds,
    placedDeckIndices: newPlaced,
    flippedSlots: newFlipped,
  );
}
