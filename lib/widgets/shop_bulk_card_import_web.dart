// 브라우저 전용 — `dart:html` 파일 선택 (조건부 import로 VM 빌드에 포함되지 않음).
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import '../models/shop_models.dart';

Future<List<ShopItemRow>?> pickAndRegisterCardDeckImages({
  required List<ShopItemRow> existingItems,
}) async =>
    null;

Future<List<ShopItemRow>?> pickAndRegisterMatImages({
  required List<ShopItemRow> existingItems,
}) async =>
    null;

Future<List<ShopItemRow>?> pickAndRegisterCardBackImages({
  required List<ShopItemRow> existingItems,
}) async =>
    null;

/// 브라우저: 숨은 `<input type="file">` 로 이미지 선택 → `data:image/...;base64,...` 로 저장(JSON에 함께 보관).
Future<String?> pickAndCopyThumbnailForShopItem({required String itemId}) async {
  if (itemId.trim().isEmpty) {
    return null;
  }
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/jpg,image/webp,image/gif'
    ..style.display = 'none';

  html.document.body?.append(input);
  void cleanup() {
    input.remove();
  }

  void oneShot(void Function() fn) {
    fn();
    cleanup();
  }

  late final void Function(html.Event) onChange;
  onChange = (html.Event e) {
    input.removeEventListener('change', onChange);
    final files = input.files;
    if (files == null || files.isEmpty) {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.onError.listen((_) {
      oneShot(() {
        if (!completer.isCompleted) completer.complete(null);
      });
    });
    reader.onLoadEnd.listen((_) {
      oneShot(() {
        final result = reader.result;
        if (!completer.isCompleted) {
          if (result is String && result.startsWith('data:image/')) {
            completer.complete(result);
          } else {
            completer.complete(null);
          }
        }
      });
    });
    reader.readAsDataUrl(file);
  };

  input.addEventListener('change', onChange);
  input.click();

  try {
    return await completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        input.removeEventListener('change', onChange);
        cleanup();
        if (!completer.isCompleted) completer.complete(null);
        return null;
      },
    );
  } catch (_) {
    input.removeEventListener('change', onChange);
    cleanup();
    return null;
  }
}
