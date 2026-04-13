import 'dart:math';

/// 첫 설정 마법사 완료 시 지급하는 환영 별조각.
const int kStarterWelcomeStarFragments = 20;

/// 첫 설정에서 무작위 지급하는 오라클·이모 개수.
const int kFirstSetupOracleGiftCount = 8;
const int kFirstSetupEmoticonGiftCount = 7;

/// 로그인·로컬 계정 ID. 비어 있으면 `local-guest` 로 동일 계열로 처리.
String starterScopeUserId(String? userId) =>
    userId == null || userId.isEmpty ? 'local-guest' : userId;

/// 예전 [ensureDefaultUserItems] 호환 — 항상 빈 목록.
/// 오라클 선물은 [pickFirstSetupOracleIds] 첫 세팅 마법사에서만 지급합니다.
List<String> starterOracleItemIdsForUser(String? _) => const [];

/// 예전 스타터 이모 호환 — 항상 빈 목록. 이모는 [pickFirstSetupEmoticonIds] 로 지급.
List<String> starterEmoticonIdsForUser(String? _) => const [];

/// 첫 세팅: 미보유 오라클 최대 [kFirstSetupOracleGiftCount]장(1~80 중 [userId]별 시드 셔플).
List<String> pickFirstSetupOracleIds(String? userId, Set<String> alreadyOwnedIds) {
  final scope = starterScopeUserId(userId);
  final r = Random(Object.hashAll(['gggom_first_setup_v1', 'oracle', scope.hashCode]));
  final nums = List<int>.generate(80, (i) => i + 1)..shuffle(r);
  final out = <String>[];
  for (final n in nums) {
    if (out.length >= kFirstSetupOracleGiftCount) {
      break;
    }
    final id = 'oracle-card-${n.toString().padLeft(2, '0')}';
    if (!alreadyOwnedIds.contains(id)) {
      out.add(id);
    }
  }
  return out..sort();
}

/// 첫 세팅: 미보유 번들 이모 최대 [kFirstSetupEmoticonGiftCount]개(61개 중 시드 셔플).
List<String> pickFirstSetupEmoticonIds(String? userId, Set<String> alreadyOwnedIds) {
  final scope = starterScopeUserId(userId);
  final r = Random(Object.hashAll(['gggom_first_setup_v1', 'emo', scope.hashCode]));
  final nums = List<int>.generate(61, (i) => i + 1)..shuffle(r);
  final out = <String>[];
  for (final n in nums) {
    if (out.length >= kFirstSetupEmoticonGiftCount) {
      break;
    }
    final id = 'emo_asset_${n.toString().padLeft(2, '0')}';
    if (!alreadyOwnedIds.contains(id)) {
      out.add(id);
    }
  }
  return out..sort();
}

/// 서비스 선물: 한국전통 메이저 1장 — 22장 중 무작위 1장.
String starterKoreaMajorItemIdForUser(String? userId) {
  final scope = starterScopeUserId(userId);
  final r = Random(Object.hashAll(['gggom_starter_korea', scope.hashCode]));
  final idx = r.nextInt(22);
  return 'korea-major-${idx.toString().padLeft(2, '0')}';
}
