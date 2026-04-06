import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/widgets/gnb.dart';
import 'package:gggom_tarot/widgets/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportRoot;

  setUp(() {
    HomeScreen.debugResetSaveToWorkspaceCalls();
    supportRoot = Directory.systemTemp.createTempSync('gggom_home_save_');
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

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (supportRoot.existsSync()) {
      supportRoot.deleteSync(recursive: true);
    }
  });

  testWidgets('Gnb: 저장하기 탭 시 onSaveForCoding 호출', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Gnb(
            active: MainTab.tarot,
            onTab: (_) {},
            displayName: '게스트',
            onSignOut: () {},
            onAttendance: () {},
            onSaveForCoding: () => calls++,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('저장하기 — 로컬 기록을 프로젝트 JSON 으로'));
    expect(calls, 1);
  });

  testWidgets('홈 저장하기 버튼: 표시되고 탭하면 스낵바(프로젝트 안내)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userId: 'local-guest',
          displayName: '게스트',
          onSignOut: () {},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final saveBtn = find.byTooltip('저장하기 — 로컬 기록을 프로젝트 JSON 으로');
    expect(saveBtn, findsOneWidget);

    expect(HomeScreen.debugSaveToWorkspaceCalls, 0);
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(
      HomeScreen.debugSaveToWorkspaceCalls,
      greaterThanOrEqualTo(1),
      reason: '저장하기가 호출되어야 함',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(tester.takeException(), isNull);

    expect(find.textContaining('프로젝트'), findsOneWidget);
    expect(kIsWeb, isFalse);
  });
}
