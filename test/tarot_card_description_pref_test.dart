import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/standalone/local_app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportRoot;

  setUp(() {
    supportRoot = Directory.systemTemp.createTempSync(
      'gggom_tarot_desc_pref_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => supportRoot.path,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (supportRoot.existsSync()) {
      supportRoot.deleteSync(recursive: true);
    }
  });

  test('카드 설명 보기 설정이 계정별로 저장/복원된다', () async {
    expect(
      await LocalAppPreferences.getShowCardDescriptionOnFlip('user-a'),
      isTrue,
    );

    await LocalAppPreferences.setShowCardDescriptionOnFlip('user-a', false);
    expect(
      await LocalAppPreferences.getShowCardDescriptionOnFlip('user-a'),
      isFalse,
    );

    await LocalAppPreferences.setShowCardDescriptionOnFlip('user-a', true);
    expect(
      await LocalAppPreferences.getShowCardDescriptionOnFlip('user-a'),
      isTrue,
    );
  });

  test('guest에서 끈 설정이 로그인 사용자 기본값으로 이어진다', () async {
    await LocalAppPreferences.setShowCardDescriptionOnFlip(null, false);

    // user-b에는 아직 전용 키가 없으므로 global fallback(false) 사용
    expect(
      await LocalAppPreferences.getShowCardDescriptionOnFlip('user-b'),
      isFalse,
    );

    // user-b가 직접 true로 바꾸면 이후에는 user-b 전용 값이 우선
    await LocalAppPreferences.setShowCardDescriptionOnFlip('user-b', true);
    expect(
      await LocalAppPreferences.getShowCardDescriptionOnFlip('user-b'),
      isTrue,
    );
  });
}
