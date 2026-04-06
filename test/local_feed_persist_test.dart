import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/standalone/local_feed_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportRoot;

  setUpAll(() {
    supportRoot = Directory.systemTemp.createTempSync('gggom_feed_persist_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async {
        switch (call.method) {
          case 'getApplicationSupportDirectory':
          case 'getTemporaryDirectory':
            return supportRoot.path;
          default:
            return null;
        }
      },
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (supportRoot.existsSync()) {
      supportRoot.deleteSync(recursive: true);
    }
  });

  test('LocalFeedRepository 게시물·댓글은 앱 재실행 후에도 유지', () async {
    final a = LocalFeedRepository();
    final posts0 = await a.fetchPosts();
    final baseline = posts0.length;

    await a.addPost(
      userId: 'u-test',
      username: '테스트',
      avatar: '🔮',
      content: 'persist-check-${DateTime.now().microsecondsSinceEpoch}',
      tags: const ['단위테스트'],
    );
    final withNew = await a.fetchPosts();
    expect(withNew.length, greaterThanOrEqualTo(baseline));

    final b = LocalFeedRepository();
    final afterRestart = await b.fetchPosts();
    expect(
      afterRestart.any((p) => p.content.startsWith('persist-check-')),
      isTrue,
    );
  });
}
