import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gggom_tarot/services/local_account_store.dart';
import 'package:gggom_tarot/widgets/account_manage_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('LocalAccountStore: 탈퇴(deleteAccount) 후 동일 아이디로 로그인 불가', () async {
    final store = LocalAccountStore.instance;
    expect(
      await store.register(
        username: 'deluser',
        password: 'secret12',
        displayName: '탈퇴테',
      ),
      isNull,
    );
    final s = await store.login('deluser', 'secret12');
    expect(s, isNotNull);

    final err = await store.deleteAccount(
      loginKey: s!.loginKey,
      password: 'secret12',
    );
    expect(err, isNull);

    expect(await store.login('deluser', 'secret12'), isNull);
    expect(await store.loadSession(), isNull);
  });

  test('LocalAccountStore: 탈퇴 시 비밀번호 불일치면 계정 유지', () async {
    final store = LocalAccountStore.instance;
    await store.register(
      username: 'keepme',
      password: 'secret12',
      displayName: '유지',
    );
    final err = await store.deleteAccount(
      loginKey: 'keepme',
      password: 'wrongpassword',
    );
    expect(err, isNotNull);
    expect(await store.login('keepme', 'secret12'), isNotNull);
  });

  testWidgets('AccountManageScreen: 회원 탈퇴·계정 삭제 진입 UI', (tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(800, 1600));

    final store = LocalAccountStore.instance;
    expect(
      await store.register(
        username: 'screenuser',
        password: 'secret12',
        displayName: '스크린',
      ),
      isNull,
    );
    final session = await store.login('screenuser', 'secret12');
    expect(session, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        home: AccountManageScreen(session: session!),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('계정 관리'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '회원 탈퇴'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '계정 삭제'), findsOneWidget);
  });
}
