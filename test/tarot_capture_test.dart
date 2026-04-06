import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/widgets/tarot_tab.dart';

/// 1/2/3열 범위 캡처용 [RepaintBoundary]가 붙고 유효한 크기로 레이아웃되는지 검증합니다.
/// (단위 테스트 VM에서 [RenderRepaintBoundary.toImage]는 환경에 따라 매우 느리거나
/// 멈출 수 있어, 통합/실기기에서 PNG 생성을 확인하는 것이 안전합니다.)
void main() {
  testWidgets('타로: 캡처용 RepaintBoundary 3개·유효 크기', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 844,
            child: TarotTab(
              userId: 'local-guest',
              feedRepository: null,
              onNeedLogin: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    final finder = find.descendant(
      of: find.byType(TarotTab),
      matching: find.byType(RepaintBoundary),
    );
    expect(finder, findsNWidgets(3));

    final elems = finder.evaluate().toList();
    for (var i = 0; i < 3; i++) {
      final ro = elems[i].renderObject!;
      expect(ro, isA<RenderRepaintBoundary>(), reason: '슬롯 #$i');
      final b = ro as RenderRepaintBoundary;
      expect(b.hasSize, isTrue, reason: '슬롯 #$i hasSize');
      expect(b.size.width, greaterThan(1), reason: '슬롯 #$i width');
      expect(b.size.height, greaterThan(1), reason: '슬롯 #$i height');
    }

    expect(tester.takeException(), isNull);
  });
}
