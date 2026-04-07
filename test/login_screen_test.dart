import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/shop_admin_gate.dart';
import 'package:gggom_tarot/widgets/login_screen.dart';

void main() {
  testWidgets('아이디로 로그인·안내 문구 표시', (tester) async {
    var idTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          supabaseConfigured: false,
          onOpenLocalLogin: () => idTapped = true,
        ),
      ),
    );

    expect(find.widgetWithText(FilledButton, '아이디로 로그인'), findsOneWidget);
    expect(find.textContaining('기기에 저장'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '아이디로 로그인'));
    expect(idTapped, isTrue);
  });

  testWidgets('Supabase 켜짐이면 관리자 패널 노출', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          supabaseConfigured: true,
          onAdminGoogleLogin: () {},
          onOpenLocalLogin: () {},
        ),
      ),
    );

    expect(find.textContaining('사이트 관리자'), findsOneWidget);
    expect(find.text('관리자로 구글 로그인'), findsOneWidget);
    expect(find.textContaining(kShopAdminGoogleEmail), findsWidgets);
  });

  testWidgets('Supabase 꺼짐이면 관리자 패널 숨김', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          supabaseConfigured: false,
          onOpenLocalLogin: () {},
        ),
      ),
    );

    expect(find.textContaining('사이트 관리자'), findsNothing);
  });

  testWidgets('관리자 버튼은 Supabase 꺼진 빌드에서 스낵바 안내', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          supabaseConfigured: false,
          onAdminGoogleLogin: () {},
          onOpenLocalLogin: () {},
        ),
      ),
    );

    await tester.tap(find.text('관리자로 구글 로그인'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.textContaining('관리자 로그인은 Supabase'),
      findsOneWidget,
    );
  });
}
