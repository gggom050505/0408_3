import 'package:flutter_test/flutter_test.dart';
import 'package:gggom_tarot/config/app_config.dart';

void main() {
  tearDown(() {
    AppConfig.supabaseEnabled = false;
  });

  test('showBetaStarAdRewardMenu: Supabase 미연동(베타 번들)이면 true', () {
    AppConfig.supabaseEnabled = false;
    expect(AppConfig.showBetaStarAdRewardMenu, isTrue);
  });

  test('showBetaStarAdRewardMenu: 기본값은 Supabase 연동 여부와 무관하게 true', () {
    AppConfig.supabaseEnabled = true;
    expect(AppConfig.showBetaStarAdRewardMenu, isTrue);
  });

  test('adRewardStarAmount는 양수', () {
    expect(AppConfig.adRewardStarAmount, greaterThan(0));
  });
}
