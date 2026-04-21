import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lunar_calendar/main.dart';

void main() {
  testWidgets('앱 기본 화면 스모크 테스트', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(1440, 2200));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(const LunarCalendarApp());
    await tester.pumpAndSettle();

    expect(find.text('음력 달력'), findsOneWidget);
    expect(find.textContaining('오늘의 접속자수'), findsOneWidget);
  });
}
