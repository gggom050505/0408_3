import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/widgets/login_screen.dart';

void main() {
  testWidgets('ID 계정 로그인·회원 가입·회원 탈퇴 메뉴', (tester) async {
    var loginTapped = false;
    var registerTapped = false;
    var withdrawTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onOpenLocalLogin: () => loginTapped = true,
          onOpenRegister: () => registerTapped = true,
          onOpenWithdraw: () => withdrawTapped = true,
        ),
      ),
    );

    expect(find.widgetWithText(FilledButton, 'ID 계정 로그인'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '회원 가입'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '회원 탈퇴'), findsOneWidget);
    expect(find.textContaining('기기에 저장'), findsOneWidget);
    expect(find.text('비밀번호 변경 안내'), findsOneWidget);
    expect(find.text('구글 계정으로 로그인'), findsNothing);

    await tester.tap(find.text('비밀번호 변경 안내'));
    await tester.pumpAndSettle();
    expect(find.text('비밀번호 변경'), findsWidgets);
    expect(find.textContaining('계정 관리'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'ID 계정 로그인'));
    expect(loginTapped, isTrue);

    await tester.tap(find.widgetWithText(OutlinedButton, '회원 가입'));
    expect(registerTapped, isTrue);

    await tester.tap(find.widgetWithText(TextButton, '회원 탈퇴'));
    expect(withdrawTapped, isTrue);
  });

  testWidgets('구글 로그인 메뉴·별도 운영 안내(콜백 있을 때)', (tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(800, 1800));

    var googleTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onOpenLocalLogin: () {},
          onOpenRegister: () {},
          onOpenWithdraw: () {},
          onOpenGoogleLogin: () => googleTapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('별도로 운영'), findsOneWidget);
    expect(find.textContaining('저장 공간'), findsOneWidget);
    final googleBtn = find.widgetWithText(
      OutlinedButton,
      '구글 계정으로 로그인',
    );
    expect(googleBtn, findsOneWidget);
    await tester.ensureVisible(googleBtn);
    await tester.pumpAndSettle();
    await tester.tap(googleBtn);
    expect(googleTapped, isTrue);
  });
}
