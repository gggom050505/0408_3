import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/widgets/login_screen.dart';

void main() {
  testWidgets('Supabase 꺼져도 구글 계정으로 로그인 메뉴(카드·버튼)가 보인다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          supabaseConfigured: false,
          onGoogleLogin: () {},
          onContinueAsGuest: () {},
          onOpenLocalLogin: () {},
          onOpenRegister: () {},
        ),
      ),
    );

    expect(find.text('구글 계정으로 로그인'), findsNWidgets(2));
    expect(find.textContaining('dart-define'), findsWidgets);
    expect(find.textContaining('SUPABASE'), findsOneWidget);
  });

  testWidgets('Supabase 미설정 시 구글 버튼 탭하면 설정 안내 스낵바', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          supabaseConfigured: false,
          onGoogleLogin: () {},
          onContinueAsGuest: () {},
          onOpenLocalLogin: () {},
          onOpenRegister: () {},
        ),
      ),
    );

    final googleBtn = find.widgetWithText(FilledButton, '구글 계정으로 로그인');
    await tester.ensureVisible(googleBtn);
    await tester.tap(googleBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.textContaining('Supabase 연동이 꺼져 있어요'),
      findsOneWidget,
    );
  });

  testWidgets('Supabase 설정 시 구글 버튼이 onGoogleLogin을 호출한다', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          supabaseConfigured: true,
          onGoogleLogin: () => called = true,
          onContinueAsGuest: () {},
          onOpenLocalLogin: () {},
          onOpenRegister: () {},
        ),
      ),
    );

    final googleBtn = find.widgetWithText(FilledButton, '구글 계정으로 로그인');
    await tester.ensureVisible(googleBtn);
    await tester.tap(googleBtn);
    expect(called, isTrue);
  });
}
