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
    SharedPreferences.setMockInitialValues(<String, Object>{});
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

  testWidgets('AccountManageScreen: 계정 탈퇴 플로우로 삭제·화면 닫힘', (tester) async {
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
    await store.saveSession(session!);

    Object? popResult;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  popResult = await Navigator.of(context).push<Object?>(
                    MaterialPageRoute<Object?>(
                      builder: (_) => AccountManageScreen(session: session),
                    ),
                  );
                },
                child: const Text('open_manage'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open_manage'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('계정 관리'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, '계정 탈퇴'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'secret12',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, '탈퇴'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(popResult, isA<AccountDeletedResult>());
    expect(await store.login('screenuser', 'secret12'), isNull);
    expect(await store.loadSession(), isNull);
  });
}
