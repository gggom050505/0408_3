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
