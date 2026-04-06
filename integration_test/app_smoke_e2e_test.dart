import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:gggom_tarot/main.dart';
import 'package:gggom_tarot/widgets/home_screen.dart';
import 'package:gggom_tarot/widgets/login_screen.dart';

/// 실제 앱 위젯 트리 기준 스모크 테스트.
///
/// 실행 예:
/// - Windows: `flutter test integration_test/app_smoke_e2e_test.dart -d windows`
/// - 단일 기기만 있으면: `flutter test integration_test/app_smoke_e2e_test.dart`
///
/// 오프닝 캐러셀(이미지당 최대 수 초) 때문에 대기 상한을 넉넉히 둡니다.
Future<void> _pumpUntilLoginOrHome(
  WidgetTester tester, {
  int maxSeconds = 90,
}) async {
  final login = find.byType(LoginScreen);
  final home = find.byType(HomeScreen);
  for (var i = 0; i < maxSeconds; i++) {
    await tester.pump(const Duration(seconds: 1));
    if (login.evaluate().isNotEmpty || home.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TestFailure(
    '${maxSeconds}s 안에 LoginScreen 또는 HomeScreen 이 나타나지 않았습니다. '
    '(오프닝 이미지 개수·네트워크에 따라 더 길어질 수 있음)',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('앱 기동 → 로그인 또는 홈(세션)', (WidgetTester tester) async {
    await tester.pumpWidget(const GgomTarotApp());
    await tester.pump();

    await _pumpUntilLoginOrHome(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    final hasLogin = find.byType(LoginScreen).evaluate().isNotEmpty;
    final hasHome = find.byType(HomeScreen).evaluate().isNotEmpty;
    expect(hasLogin || hasHome, isTrue);
  });

  testWidgets('게스트 가능 시 진입 후 타로 탭(텍스트) 표시', (WidgetTester tester) async {
    await tester.pumpWidget(const GgomTarotApp());
    await tester.pump();

    await _pumpUntilLoginOrHome(tester);

    final guestBtn = find.widgetWithText(
      OutlinedButton,
      '회원가입 없이 둘러보기',
    );
    if (guestBtn.evaluate().isNotEmpty) {
      await tester.ensureVisible(guestBtn);
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      await tester.tap(guestBtn);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.byType(HomeScreen).evaluate().isNotEmpty) {
          break;
        }
      }
    }

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('타로'), findsWidgets);
    expect(find.text('로그아웃'), findsWidgets);
  });
}
