import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/shop_admin_gate.dart';
import 'package:gggom_tarot/models/shop_models.dart';
import 'package:gggom_tarot/standalone/local_shop_repository.dart';
import 'package:gggom_tarot/widgets/admin_user_activity_screen.dart';
import 'package:gggom_tarot/widgets/gnb.dart';
import 'package:gggom_tarot/widgets/shop_admin_screen.dart';

/// 관리자 모드(상점 편집·활동 화면·GNB 뱃지·Supabase 게이트) 자동 테스트.
///
/// **원격 전용:** 접속·활동 모니터의 Supabase 조회·Realtime 은
/// [AdminUserActivityScreen] 에서 `enforceSupabaseAdminGate: false` + 초기화된 클라이언트가
/// 필요하므로 여기서는 **게이트된 안내 문구**만 검증합니다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportRoot;

  setUpAll(() {
    supportRoot = Directory.systemTemp.createTempSync('gggom_admin_mode_');
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

  testWidgets('GNB: 관리자 세션일 때 「관리자」 뱃지', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Gnb(
            active: MainTab.tarot,
            onTab: (_) {},
            displayName: '테스터',
            onSignOut: () {},
            checkedInToday: false,
            onAttendance: () {},
            isShopAdminSession: true,
          ),
        ),
      ),
    );
    expect(find.text('관리자'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ShopAdminScreen: Supabase 게이트 시 지정 이메일 안내만 표시', (tester) async {
    final repo = LocalShopRepository('admin-gate-${tester.binding.hashCode}');
    await tester.pumpWidget(
      MaterialApp(
        home: ShopAdminScreen(
          repo: repo,
          enforceSupabaseAdminGate: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining(kShopAdminGoogleEmail), findsOneWidget);
    expect(find.textContaining('관리자 전용'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AdminUserActivityScreen: 게이트 시 동일 이메일 안내', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminUserActivityScreen(
          enforceSupabaseAdminGate: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining(kShopAdminGoogleEmail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ShopAdminScreen: 상품 추가·수정·삭제·JSON 보기·활동 화면 진입',
    (tester) async {
      final suffix = '${tester.binding.hashCode}';
      final repo = LocalShopRepository('admin-flow-$suffix');
      final testId = 'admin-flow-mat-$suffix';

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
      expect(find.textContaining('관리자 모드 · 상점 상품 편집'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('상품 추가'), findsOneWidget);

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(4));
      await tester.enterText(fields.at(0), testId);
      await tester.enterText(fields.at(1), '관리자플로우매트');
      await tester.enterText(fields.at(2), '42');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('관리자플로우매트'), findsWidgets);
      expect(find.textContaining(testId), findsWidgets);

      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('관리자플로우매트'),
            matching: find.byType(ListTile),
          ),
          matching: find.byIcon(Icons.edit_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('상품 수정'), findsOneWidget);
      await tester.enterText(fields.at(1), '관리자플로우매트수정');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.text('관리자플로우매트수정'), findsWidgets);

      await tester.tap(find.byIcon(Icons.code));
      await tester.pumpAndSettle();
      expect(find.text('카탈로그 JSON'), findsOneWidget);
      expect(find.textContaining(testId), findsWidgets);
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      expect(find.textContaining(kShopAdminGoogleEmail), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('관리자플로우매트수정'),
            matching: find.byType(ListTile),
          ),
          matching: find.byIcon(Icons.delete_outline),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('관리자플로우매트수정'), findsNothing);

      final catalog = await repo.loadFullCatalogForAdmin();
      expect(catalog.any((e) => e.id == testId), isFalse);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ShopAdminScreen: 빈 이름이면 스낵바', (tester) async {
    final repo = LocalShopRepository('admin-snack-${tester.binding.hashCode}');
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

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'empty-name-id-${tester.binding.hashCode}');
    await tester.enterText(fields.at(1), '');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('이름을 입력해 주세요.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ShopAdminScreen: 중복 ID 추가 시 스낵바', (tester) async {
    final repo = LocalShopRepository('admin-dup-${tester.binding.hashCode}');
    final id = 'dup-id-${tester.binding.hashCode}';
    final full = await repo.loadFullCatalogForAdmin();
    await repo.saveCatalogForAdmin([
      ...full,
      ShopItemRow(
        id: id,
        name: '기존',
        type: 'mat',
        price: 1,
        thumbnailUrl: null,
        isActive: true,
      ),
    ]);

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

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), id);
    await tester.enterText(fields.at(1), '또추가');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('이미 같은 ID가 있어요.'), findsOneWidget);

    final list = await repo.loadFullCatalogForAdmin();
    await repo.saveCatalogForAdmin(list.where((e) => e.id != id).toList());
    expect(tester.takeException(), isNull);
  });
}
