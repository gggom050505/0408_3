import 'package:flutter_test/flutter_test.dart';
import 'package:gggom_tarot/config/app_config.dart';

void main() {
  test('showBetaStarAdRewardMenu 기본 true', () {
    expect(AppConfig.showBetaStarAdRewardMenu, isTrue);
  });

  test('adRewardStarAmount는 양수', () {
    expect(AppConfig.adRewardStarAmount, greaterThan(0));
  });
}
