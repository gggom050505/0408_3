import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/models/shop_models.dart';
import 'package:gggom_tarot/standalone/local_emoticon_repository.dart';
import 'package:gggom_tarot/standalone/local_shop_repository.dart';
import 'package:gggom_tarot/widgets/shop_tab.dart';

/// 상점 상단 「관리자 모드 · 상품 편집」 버튼: 콜백이 연결되면 탭이 동작하는지만 검증합니다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportRoot;

  setUpAll(() {
    supportRoot = Directory.systemTemp.createTempSync('gggom_shop_tab_admin_');
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

  testWidgets('onOpenShopAdmin 이 null 이면 관리자 아이콘 버튼 없음', (tester) async {
    final repo = LocalShopRepository('shop-tab-admin-null-${tester.binding.hashCode}');
    final emo = LocalEmoticonRepository(wallet: repo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShopTab(
            repo: repo,
            userId: 'u1',
            displayName: '테스트',
            shopItems: const [],
            profile: UserProfileRow(
              id: 'u1',
              starFragments: 10,
              equippedCard: 'default',
              equippedMat: 'default-mint',
              equippedCardBack: 'default-card-back',
            ),
            ownedItems: const [],
            onRefresh: () async {},
            onNeedLogin: () {},
            emoticonRepo: emo,
            emoticonPacks: const [],
            ownedEmoticonIds: const [],
            onOpenPersonalShop: null,
            onOpenShopAdmin: null,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byTooltip('관리자 모드 · 상품 편집'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onOpenShopAdmin 연결 시 탭하면 콜백 1회 호출', (tester) async {
    final repo = LocalShopRepository('shop-tab-admin-tap-${tester.binding.hashCode}');
    final emo = LocalEmoticonRepository(wallet: repo);
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShopTab(
            repo: repo,
            userId: 'u1',
            displayName: '테스트',
            shopItems: const [],
            profile: UserProfileRow(
              id: 'u1',
              starFragments: 10,
              equippedCard: 'default',
              equippedMat: 'default-mint',
              equippedCardBack: 'default-card-back',
            ),
            ownedItems: const [],
            onRefresh: () async {},
            onNeedLogin: () {},
            emoticonRepo: emo,
            emoticonPacks: const [],
            ownedEmoticonIds: const [],
            onOpenPersonalShop: null,
            onOpenShopAdmin: () => calls++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final adminBtn = find.byTooltip('관리자 모드 · 상품 편집');
    expect(adminBtn, findsOneWidget);
    await tester.tap(adminBtn);
    await tester.pump();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });
}
