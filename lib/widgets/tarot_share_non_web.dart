import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// 모바일·데스크톱(VM) — `dart:io` 사용. 웹은 [tarot_share_non_web_stub.dart].
Future<void> shareCaptureNonWeb({
  required BuildContext context,
  required Uint8List bytes,
  required String suggested,
  required XTypeGroup typePng,
  bool copiedToClipboard = false,
}) async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final loc = await getSaveLocation(
      suggestedName: suggested,
      acceptedTypeGroups: [typePng],
      confirmButtonText: '저장',
    );
    if (loc == null) {
      return;
    }
    await File(loc.path).writeAsBytes(bytes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copiedToClipboard
                ? '이미지를 저장했고 클립보드에도 복사했어요. '
                    '카톡·메일 등에 붙여넣거나 파일로 첨부할 수 있어요.'
                : '이미지를 저장했습니다. 카톡·메일 등은 해당 폴더에서 파일을 첨부하면 돼요.',
          ),
        ),
      );
    }
    return;
  }

  final dir = Directory.systemTemp;
  final f = File('${dir.path}${Platform.pathSeparator}$suggested');
  await f.writeAsBytes(bytes);
  if (context.mounted && copiedToClipboard) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '이미지를 클립보드에 복사했어요. 카톡 등 채팅창에서 붙여넣기 할 수 있어요.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
  await Share.shareXFiles(
    [
      XFile(f.path, mimeType: 'image/png'),
    ],
    text: '🔮 공공곰타로덱 스프레드',
  );
}
