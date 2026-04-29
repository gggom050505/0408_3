import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/widgets/today_tarot_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// [TodayTarotScreen] 안에서 prefs를 쓰는 코드 경로(다시 뽑기 등)가 테스트에서 동작하도록.
  late Directory pathMockRoot;

  setUpAll(() {
    pathMockRoot =
        Directory.systemTemp.createTempSync('gggom_today_tarot_tests_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => pathMockRoot.path,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (pathMockRoot.existsSync()) {
      try {
        pathMockRoot.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('오늘의 타로(게이트 스킵)', () {
    testWidgets('인트로·키워드·뽑기 화면 진입', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TodayTarotScreen(
            userId: 'test-user',
            displayName: '테스터',
            avatarEmojiOrUrl: '🔮',
            feed: null,
            skipDailyCompletionLock: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('오늘의 키워드'), findsOneWidget);
      expect(find.text('카드 뽑으러 가기'), findsOneWidget);

      await tester.tap(find.text('카드 뽑으러 가기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('/ 10'), findsOneWidget);
      expect(find.textContaining('길게 눌러 드래그'), findsOneWidget);
    });

    testWidgets('설명서 다이얼로그 열고 닫기', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TodayTarotScreen(
            userId: 'test-user',
            displayName: '테스터',
            avatarEmojiOrUrl: '🔮',
            feed: null,
            skipDailyCompletionLock: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('설명서'));
      await tester.pumpAndSettle();

      expect(find.text('오늘의 타로 설명서'), findsOneWidget);

      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();

      expect(find.text('오늘의 타로 설명서'), findsNothing);
    });

    testWidgets('다시 뽑기 후에도 인트로 유지', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TodayTarotScreen(
            userId: 'test-user',
            displayName: '테스터',
            avatarEmojiOrUrl: '🔮',
            feed: null,
            skipDailyCompletionLock: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('카드 뽑으러 가기'), findsOneWidget);

      await tester.tap(find.byTooltip('다시 뽑기'));
      await tester.pumpAndSettle();

      expect(find.text('카드 뽑으러 가기'), findsOneWidget);
    });

    testWidgets('뽑기 화면 진입 직후 한 번에 뒤집기 버튼은 비활성 노출', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TodayTarotScreen(
            userId: 'flip-all-disabled-user',
            displayName: '테스터',
            avatarEmojiOrUrl: '🔮',
            feed: null,
            skipDailyCompletionLock: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('카드 뽑으러 가기'));
      await tester.pumpAndSettle();

      final btnFinder = find.widgetWithText(
        OutlinedButton,
        '한 번에 뒤집기 (10장 배치 후 가능)',
      );
      expect(btnFinder, findsOneWidget);
      final btn = tester.widget<OutlinedButton>(btnFinder);
      expect(btn.onPressed, isNull);
    });

    testWidgets('뽑기 진행 중에도 한 번에 뒤집기 버튼은 계속 노출', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: TodayTarotScreen(
            userId: 'flip-all-user',
            displayName: '테스터',
            avatarEmojiOrUrl: '🔮',
            feed: null,
            skipDailyCompletionLock: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('카드 뽑으러 가기'));
      await tester.pumpAndSettle();

      // 하단 팬 덱 중심을 여러 번 탭해 슬롯을 채웁니다.
      final rootRect = tester.getRect(find.byType(TodayTarotScreen));
      final centerX = rootRect.center.dx;
      final tapY = rootRect.bottom - 72;
      final offsets = <double>[
        0, -24, 24, -36, 36, -12, 12, -48, 48, 0, -18, 18,
        -30, 30, -42, 42, -8, 8, -54, 54, -15, 15,
      ];

      for (final dx in offsets) {
        await tester.tapAt(Offset(centerX + dx, tapY));
        await tester.pump(const Duration(milliseconds: 180));
      }
      await tester.pumpAndSettle();

      expect(find.textContaining('한 번에 뒤집기'), findsOneWidget);
    });
  });

  group('오늘의 타로(완료 차단 UI)', () {
    testWidgets('차단 문구·다시 뽑기 버튼', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TodayTarotScreen(
            userId: 'gate-block-user',
            displayName: '테스터',
            avatarEmojiOrUrl: '🔮',
            feed: null,
            skipDailyCompletionLock: false,
            debugForceBlockedGateForTest: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('이미 완료'), findsOneWidget);
      expect(find.text('다시 뽑기'), findsWidgets);
    });
  });

}
