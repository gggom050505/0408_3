import 'dart:math';

/// 유니크 품목 별가격을 **1~12**로 고정 매핑(앱 버전마다 안 바뀌는 시드).
/// - 오라클 24장: 1~12가 각각 정확히 2번씩.
/// - 한국전통 유니크 7장: 1~12 중 서로 다른 7개.
/// - 이모 유니크 12종: 1~12를 한 번씩(카드 ID와 무작위 대응).

List<int> _buildOracleUniqueStars() {
  final r = Random(Object.hashAll(['gggom_unique_oracle_star_v1']));
  final values = <int>[
    for (var v = 1; v <= 12; v++) ...[v, v],
  ]..shuffle(r);
  final cardNums = List.generate(24, (i) => i + 1)
    ..shuffle(Random(r.nextInt(0x7FFFFFFF)));
  final byCard = List<int>.filled(24, 1);
  for (var i = 0; i < 24; i++) {
    byCard[cardNums[i] - 1] = values[i];
  }
  return byCard;
}

List<int> _buildKoreaUniqueStarsByIndex() {
  final r = Random(Object.hashAll(['gggom_unique_korea_star_v1']));
  final prices = List.generate(12, (i) => i + 1)..shuffle(r);
  final slotPerm = List.generate(7, (i) => i)
    ..shuffle(Random(r.nextInt(0x7FFFFFFF)));
  final out = List<int>.filled(7, 1);
  for (var i = 0; i < 7; i++) {
    out[slotPerm[i]] = prices[i];
  }
  return out;
}

Map<String, int> _buildEmoticonUniqueStarsById() {
  final r = Random(Object.hashAll(['gggom_unique_emo_star_v1']));
  final ids = List.generate(12, (i) {
    return 'emo_asset_${(i + 1).toString().padLeft(2, '0')}';
  })..shuffle(r);
  final prices = List.generate(12, (i) => i + 1)
    ..shuffle(Random(r.nextInt(0x7FFFFFFF)));
  return {for (var i = 0; i < 12; i++) ids[i]: prices[i]};
}

final List<int> _oracleUniqueStars = _buildOracleUniqueStars();
final List<int> _koreaUniqueStarsByIndex = _buildKoreaUniqueStarsByIndex();
final Map<String, int> _emoUniqueStarsById = _buildEmoticonUniqueStarsById();

int uniqueOracleShopStarPrice(int cardNumber1Based) {
  assert(cardNumber1Based >= 1 && cardNumber1Based <= 24);
  return _oracleUniqueStars[cardNumber1Based - 1];
}

int uniqueKoreaMajorShopStarPrice(int cardIndex0to6) {
  assert(cardIndex0to6 >= 0 && cardIndex0to6 <= 6);
  return _koreaUniqueStarsByIndex[cardIndex0to6];
}

int uniqueBundleEmoticonShopStarPrice(String emoticonId) {
  return _emoUniqueStarsById[emoticonId]!;
}
