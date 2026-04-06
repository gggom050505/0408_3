/// 번들 오라클 카드 80장 — `assets/oracle/oracle(1).png` ~ `oracle(80).png`
const int kBundledOracleCardCount = 80;

/// [cardNumber] 1~80. 그 외는 null.
String? bundledOracleAssetPath(int cardNumber) {
  if (cardNumber < 1 || cardNumber > kBundledOracleCardCount) {
    return null;
  }
  return 'assets/oracle/oracle($cardNumber).png';
}

/// 상점·가방 ID `oracle-card-01` ~ `oracle-card-80` → 카드 번호 1~80.
int? oracleItemIdToCardNumber(String itemId) {
  final m = RegExp(r'^oracle-card-(\d+)$').firstMatch(itemId);
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}
