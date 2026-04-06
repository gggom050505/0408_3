import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WindowGeometryStore {
  WindowGeometryStore._();

  static const _fileName = 'window_geometry.json';
  static const _minW = 360.0;
  static const _minH = 320.0;

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static Future<Rect?> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final map = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final left = (map['left'] as num).toDouble();
      final top = (map['top'] as num).toDouble();
      final w = (map['width'] as num).toDouble();
      final h = (map['height'] as num).toDouble();
      if (w < _minW || h < _minH) return null;
      return Rect.fromLTWH(left, top, w, h);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(Rect rect) async {
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      await f.writeAsString(
        jsonEncode({
          'left': rect.left,
          'top': rect.top,
          'width': rect.width,
          'height': rect.height,
        }),
      );
    } catch (_) {}
  }
}
