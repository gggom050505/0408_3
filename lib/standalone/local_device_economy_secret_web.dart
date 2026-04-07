import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

Future<List<int>> economyDeviceSecretBytes() async {
  final sp = await SharedPreferences.getInstance();
  const prefKey = 'gggom_economy_device_secret_v1';
  final existing = sp.getString(prefKey);
  if (existing != null && existing.isNotEmpty) {
    try {
      final b = base64Decode(existing);
      if (b.length == 32) {
        return b;
      }
    } catch (_) {}
  }
  final rnd = Random.secure();
  final key = List<int>.generate(32, (_) => rnd.nextInt(256));
  await sp.setString(prefKey, base64Encode(key));
  return key;
}
