import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<List<int>> economyDeviceSecretBytes() async {
  final dir = await getApplicationSupportDirectory();
  final sub = Directory(p.join(dir.path, 'gggom_standalone'));
  if (!await sub.exists()) {
    await sub.create(recursive: true);
  }
  final file = File(p.join(sub.path, '.economy_device_secret_v1'));
  if (await file.exists()) {
    final b = await file.readAsBytes();
    if (b.length == 32) {
      return b;
    }
  }
  final rnd = Random.secure();
  final key = List<int>.generate(32, (_) => rnd.nextInt(256));
  await file.writeAsBytes(key, flush: true);
  return key;
}
