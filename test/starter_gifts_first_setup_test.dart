import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/starter_gifts.dart';

void main() {
  test('첫 설정 지급: 오라클 8장·이모 7개(미보유 기준)', () {
    expect(
      pickFirstSetupOracleIds('test-user-oracle', {}).length,
      kFirstSetupOracleGiftCount,
    );
    expect(
      pickFirstSetupEmoticonIds('test-user-emo', {}).length,
      kFirstSetupEmoticonGiftCount,
    );
    expect(kFirstSetupOracleGiftCount, 8);
    expect(kFirstSetupEmoticonGiftCount, 7);
    expect(kStarterWelcomeStarFragments, 20);
  });

  test('이미 보유한 오라클 ID는 지급 목록에 넣지 않음', () {
    final owned = {'oracle-card-01', 'oracle-card-02'};
    final oracleIds = pickFirstSetupOracleIds('u1', owned);
    for (final id in owned) {
      expect(oracleIds.contains(id), isFalse);
    }
    expect(oracleIds.length, kFirstSetupOracleGiftCount);
  });
}
