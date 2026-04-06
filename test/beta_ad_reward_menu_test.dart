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

  test('showBetaStarAdRewardMenu: Supabase 연동 시에는 adRewardTestMode와 동일', () {
    AppConfig.supabaseEnabled = true;
    expect(
      AppConfig.showBetaStarAdRewardMenu,
      AppConfig.adRewardTestMode,
    );
  });

  test('adRewardStarAmount는 양수', () {
    expect(AppConfig.adRewardStarAmount, greaterThan(0));
  });
}
