import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gggom_tarot/config/shop_random_prices.dart';
import 'package:gggom_tarot/models/shop_models.dart';
import 'package:gggom_tarot/standalone/local_shop_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportRoot;

  setUpAll(() {
    supportRoot = Directory.systemTemp.createTempSync('gggom_star1_daily_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async {
        switch (call.method) {
          case 'getApplicationSupportDirectory':
          case 'getTemporaryDirectory':
            return supportRoot.path;
          default:
            return null;
        }
      },
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (supportRoot.existsSync()) {
      supportRoot.deleteSync(recursive: true);
    }
  });

  group('gggomCanPurchaseStarOnePricedItemToday', () {
    test('미기록·빈 문자열이면 ⭐1 구매 허용', () {
      expect(gggomCanPurchaseStarOnePricedItemToday(null), true);
      expect(gggomCanPurchaseStarOnePricedItemToday(''), true);
    });

    test('과거 UTC 날짜면 오늘과 다르므로 허용', () {
      expect(gggomCanPurchaseStarOnePricedItemToday('1970-01-01'), true);
    });

    test('저장된 날짜가 오늘(UTC)과 같으면 거절', () {
      final today = gggomTodayUtcYmdKey();
      expect(gggomCanPurchaseStarOnePricedItemToday(today), false);
    });
  });

  group('LocalShopRepository ⭐1 일일 1건', () {
    const userId = 'star1_daily_repo_test';

    test('서로 다른 ⭐1 상품을 같은 UTC일에 연속 구매하면 두 번째는 false', () async {
      final repo = LocalShopRepository(userId);
      await repo.ensureUserEconomyReady();
      await repo.grantAdRewardStars(userId, amount: 20);

      final full = await repo.loadFullCatalogForAdmin();
      final ownedIds = (await repo.fetchOwnedItems(userId)).map((e) => e.itemId).toSet();
      final candidates = full
          .where(
            (e) => e.type == 'oracle_card' && e.isActive && !ownedIds.contains(e.id),
          )
          .take(2)
          .toList();

      expect(
        candidates.length,
        2,
        reason: '테스트에 미보유 오라클 카드 2개가 필요합니다.',
      );

      ShopItemRow withPrice1(ShopItemRow e) {
        if (e.id == candidates[0].id || e.id == candidates[1].id) {
          return ShopItemRow(
            id: e.id,
            name: e.name,
            type: e.type,
            price: 1,
            thumbnailUrl: e.thumbnailUrl,
            isActive: e.isActive,
          );
        }
        return e;
      }

      await repo.saveCatalogForAdmin(full.map(withPrice1).toList());

      final profile = await repo.fetchProfile(userId);
      expect(profile, isNotNull);

      var owned = await repo.fetchOwnedItems(userId);

      final ok1 = await repo.buyItem(
        userId: userId,
        itemId: candidates[0].id,
        price: 1,
        type: 'oracle_card',
        profile: profile!,
        owned: owned,
      );
      expect(ok1, true);

      owned = await repo.fetchOwnedItems(userId);
      final profile2 = await repo.fetchProfile(userId);

      final ok2 = await repo.buyItem(
        userId: userId,
        itemId: candidates[1].id,
        price: 1,
        type: 'oracle_card',
        profile: profile2!,
        owned: owned,
      );
      expect(ok2, false);
    });
  });
}
