import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';

/// 웹 빌드 전용 스텁. `_shareCaptureBytes`는 `kIsWeb` 분기에서 이미 return 하므로 호출되지 않습니다.
Future<void> shareCaptureNonWeb({
  required BuildContext context,
  required Uint8List bytes,
  required String suggested,
  required XTypeGroup typePng,
  bool copiedToClipboard = false,
}) async {}
