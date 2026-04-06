import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/main.dart';
import 'package:gggom_tarot/standalone/local_emoticon_repository.dart';
import 'package:gggom_tarot/widgets/standalone_chat_tab.dart';

void main() {
  testWidgets('앱이 MaterialApp으로 빌드됨', (WidgetTester tester) async {
    await tester.pumpWidget(const GgomTarotApp());
    await tester.pump();
    expect(find.byType(GgomTarotApp), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('로컬 채팅: 이모티콘 피커 열고 첫 스티커 선택 시 시트 닫힘', (WidgetTester tester) async {
    final emoRepo = LocalEmoticonRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StandaloneChatTab(
            displayName: '게스트',
            userId: 'widget-test-emo-${tester.binding.hashCode}',
            emoticonRepo: emoRepo,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byTooltip('이모티콘'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('이모티콘'), findsOneWidget);
    final grid = find.byType(GridView);
    expect(grid, findsOneWidget);
    await tester.tap(find.descendant(of: grid, matching: find.byType(InkWell)).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(GridView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('로컬 채팅: 텍스트 전송', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StandaloneChatTab(
            displayName: '게스트',
            userId: 'local-guest',
            emoticonRepo: LocalEmoticonRepository(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField), '테스트 메시지');
    await tester.tap(find.text('보내기'));
    await tester.pump();
    await tester.pump();

    expect(find.text('테스트 메시지'), findsOneWidget);
  });

  testWidgets('좁은 너비에서도 입력줄이 오버플로우 없음', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StandaloneChatTab(
            displayName: '게스트',
            userId: 'local-guest',
            emoticonRepo: LocalEmoticonRepository(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
