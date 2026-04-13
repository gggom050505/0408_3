import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/standalone/local_app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportRoot;

  setUp(() {
    supportRoot = Directory.systemTemp.createTempSync('gggom_today_tarot_mark_');
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

  test('markTodayTarotCompletedToday completes', () async {
    await LocalAppPreferences.markTodayTarotCompletedToday('x-user');
    expect(await LocalAppPreferences.isTodayTarotCompletedToday('x-user'), isTrue);
  });

}
