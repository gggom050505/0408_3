import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/models/shop_models.dart';
import 'package:gggom_tarot/standalone/local_shop_repository.dart';
import 'package:gggom_tarot/widgets/shop_admin_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportRoot;

  setUpAll(() {
    supportRoot = Directory.systemTemp.createTempSync('gggom_shop_test_');
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

  test('ShopItemRow JSON 왕복', () {
    const j = {
      'id': 't1',
      'name': '테스트',
      'type': 'mat',
      'price': 42,
      'thumbnail_url': '/x.png',
      'is_active': false,
    };
    final r = ShopItemRow.fromJson(Map<String, dynamic>.from(j));
    final out = r.toJson();
    expect(out['id'], 't1');
    expect(out['price'], 42);
    expect(out['is_active'], false);
  });

  testWidgets('ShopAdminScreen 로드·기본 카탈로그', (tester) async {
    final repo = LocalShopRepository('widget-test-shop-${tester.binding.hashCode}');
    await tester.pumpWidget(
      MaterialApp(
        home: ShopAdminScreen(
          repo: repo,
          enforceSupabaseAdminGate: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('관리자'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('LocalShopRepository 장착 상태는 재시작 후에도 유지(자동 저장)', () async {
    final uid = 'persist-${DateTime.now().microsecondsSinceEpoch}';
    final repo1 = LocalShopRepository(uid);
    await repo1.equipItem(userId: uid, itemId: 'night-sky', type: 'mat');
    expect((await repo1.fetchProfile(uid))?.equippedMat, 'night-sky');
    await repo1.equipItem(userId: uid, itemId: 'default', type: 'card');
    expect((await repo1.fetchProfile(uid))?.equippedCard, 'default');

    final repo2 = LocalShopRepository(uid);
    final p2 = await repo2.fetchProfile(uid);
    expect(p2?.equippedMat, 'night-sky');
    expect(p2?.equippedCard, 'default');
  });

  test('LocalShopRepository 카탈로그 저장 후 반영', () async {
    final repo = LocalShopRepository('catalog-save-${DateTime.now().millisecondsSinceEpoch}');
    try {
      final initial = await repo.fetchShopItems();
      expect(initial.where((e) => e.id == 'default'), isNotEmpty);

      final full = await repo.loadFullCatalogForAdmin();
      final next = [
        ...full,
        ShopItemRow(
          id: 'zz-test-item',
          name: '단위테스트 상품',
          type: 'mat',
          price: 100,
          thumbnailUrl: null,
          isActive: true,
        ),
      ];
      await repo.saveCatalogForAdmin(next);
      final again = await repo.fetchShopItems();
      expect(again.any((e) => e.id == 'zz-test-item'), isTrue);

      final filtered = again.where((e) => e.id == 'zz-test-item').toList();
      expect(filtered.single.name, '단위테스트 상품');
    } finally {
      final list = await repo.loadFullCatalogForAdmin();
      await repo.saveCatalogForAdmin(
        list.where((e) => e.id != 'zz-test-item').toList(),
      );
    }
  });
}
