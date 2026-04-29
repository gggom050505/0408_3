import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/widgets/feed_post_capture.dart';

/// 1×1 PNG (투명)
const kTinyPngB64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'FeedPostCapture는 data:image/png;base64 URL에서 이미지를 표시한다',
    (WidgetTester tester) async {
      final url = 'data:image/png;base64,$kTinyPngB64';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedPostCapture(imageUrl: url),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(base64Decode(url.split(',').last), isNotEmpty);
      expect(find.byType(Image), findsOneWidget);
      final img = tester.widget<Image>(find.byType(Image));
      expect(img.image, isA<MemoryImage>());
    },
  );

  testWidgets('피드 저장 형식과 동일한 data URL이 디코드된다', (WidgetTester tester) async {
    final bytes = base64Decode(kTinyPngB64);
    final fromRepo = 'data:image/png;base64,${base64Encode(bytes)}';
    expect(fromRepo.startsWith('data:image/png;base64,'), isTrue);
    final decoded = base64Decode(fromRepo.substring(fromRepo.indexOf(',') + 1));
    expect(decoded, bytes);
  });
}
