import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/bundle_emoticon_catalog.dart';
import 'package:gggom_tarot/main.dart';
import 'package:gggom_tarot/models/emoticon_models.dart';
import 'package:gggom_tarot/standalone/data_sources.dart';
import 'package:gggom_tarot/standalone/local_emoticon_repository.dart';
import 'package:gggom_tarot/widgets/standalone_chat_tab.dart';

/// [EmoticonPickerSheet]은 보유 ID가 있을 때만 그리드를 그립니다(시작 지급이 비어 있음).
class _TestEmoticonRepoWithOneOwned implements EmoticonDataSource {
  static final String _ownedId = kBundleEmoticonRows.first.id;

  @override
  Future<List<EmoticonPackRow>> fetchPacks() async => [];

  @override
  Future<List<EmoticonRow>> fetchAllEmoticons() async =>
      List<EmoticonRow>.from(kBundleEmoticonRows);

  @override
  Future<List<String>> fetchOwned(String userId) async => [_ownedId];

  @override
  Future<bool> buyEmoticon({
    required String userId,
    required String emoticonId,
    required int price,
    required List<String> ownedIds,
  }) async =>
      true;

  @override
  Future<({bool ok, String? error})> buyPack({
    required String userId,
    required String packId,
  }) async =>
      (ok: true, error: null);
}

void main() {
  testWidgets('앱이 MaterialApp으로 빌드됨', (WidgetTester tester) async {
    await tester.pumpWidget(const GgomTarotApp());
    await tester.pump();
    expect(find.byType(GgomTarotApp), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('로컬 채팅: 이모티콘 피커 열고 첫 스티커 선택 시 시트 닫힘', (WidgetTester tester) async {
    final emoRepo = _TestEmoticonRepoWithOneOwned();
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
    // ChatMarqueeWarningBar가 repeat 애니메이션을 써서 pumpAndSettle은 타임아웃됨.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('이모티콘'), findsOneWidget);
    final grid = find.byType(GridView);
    expect(grid, findsWidgets);
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
