import 'dart:typed_data';

import 'package:super_clipboard/super_clipboard.dart';

/// PNG를 시스템 클립보드에 넣습니다. (카카오톡 등 이미지 붙여넣기)
/// [SystemClipboard]를 쓸 수 없는 환경(일부 웹·브라우저)에서는 `false`를 반환합니다.
Future<bool> copyTarotCapturePngToClipboard(Uint8List pngBytes) async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    return false;
  }
  final item = DataWriterItem(suggestedName: 'gggom_taro.png');
  item.add(Formats.png(pngBytes));
  await clipboard.write([item]);
  return true;
}
