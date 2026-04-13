import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/widgets/login_screen.dart';

void main() {
  testWidgets('Google 로그인·게스트 둘러보기 메뉴', (tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(800, 1600));

    var googleTapped = false;
    var guestTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onOpenGoogleLogin: () => googleTapped = true,
          onContinueAsGuest: () => guestTapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final googleLoginButton = find.text('Google로 로그인');
    final googleSetupButton = find.text('Google 설정 필요');
    expect(
      googleLoginButton.evaluate().isNotEmpty || googleSetupButton.evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.text('로그인 없이 둘러보기'), findsWidgets);
    expect(find.text('Google 계정'), findsOneWidget);
    expect(find.textContaining('로그인'), findsWidgets);

    if (googleLoginButton.evaluate().isNotEmpty) {
      await tester.tap(googleLoginButton);
      expect(googleTapped, isTrue);
    }

    await tester.tap(find.text('로그인 없이 둘러보기').first);
    expect(guestTapped, isTrue);
  });
}
