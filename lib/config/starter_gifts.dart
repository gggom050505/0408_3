import 'dart:math';

/// 로그인·로컬 계정 ID. 비어 있으면 `local-guest` 로 동일 계열로 처리.
String starterScopeUserId(String? userId) =>
    userId == null || userId.isEmpty ? 'local-guest' : userId;

/// 서비스 선물: 오라클 5장 — 1~80 중 [userId]마다 다른 무작위 조합(시드 고정).
List<String> starterOracleItemIdsForUser(String? userId) {
  final scope = starterScopeUserId(userId);
  final r = Random(Object.hashAll(['gggom_starter_oracle', scope.hashCode]));
  final pick = List<int>.generate(80, (i) => i + 1)..shuffle(r);
  return pick
      .take(5)
      .map((n) => 'oracle-card-${n.toString().padLeft(2, '0')}')
      .toList()
    ..sort();
}

/// 서비스 선물: 번들 이모 5개 — 61개 중 무작위.
List<String> starterEmoticonIdsForUser(String? userId) {
  final scope = starterScopeUserId(userId);
  final r = Random(Object.hashAll(['gggom_starter_emo', scope.hashCode]));
  final pick = List<int>.generate(61, (i) => i + 1)..shuffle(r);
  return pick
      .take(5)
      .map((i) => 'emo_asset_${i.toString().padLeft(2, '0')}')
      .toList()
    ..sort();
}

/// 서비스 선물: 한국전통 메이저 1장 — 22장 중 무작위 1장.
String starterKoreaMajorItemIdForUser(String? userId) {
  final scope = starterScopeUserId(userId);
  final r = Random(Object.hashAll(['gggom_starter_korea', scope.hashCode]));
  final idx = r.nextInt(22);
  return 'korea-major-${idx.toString().padLeft(2, '0')}';
}
