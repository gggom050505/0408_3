import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'local_device_economy_secret.dart';

/// 로컬 `local_shop_user_state` 무결성 — JSON 직접 수정 시 로드 시 거부·초기화.
class LocalEconomyIntegrity {
  LocalEconomyIntegrity._();

  static dynamic _normalize(dynamic v) {
    if (v is Map) {
      final m = <String, dynamic>{};
      for (final e in v.entries) {
        m[e.key.toString()] = _normalize(e.value);
      }
      final keys = m.keys.toList()..sort();
      return <String, dynamic>{for (final k in keys) k: m[k]};
    }
    if (v is List) {
      final list = v.map(_normalize).toList();
      if (list.isNotEmpty &&
          list.first is Map &&
          (list.first as Map).containsKey('item_id')) {
        final sorted = List<Map<String, dynamic>>.from(
          list.map((e) => Map<String, dynamic>.from(e as Map)),
        );
        sorted.sort((a, b) {
          final ta = '${a['item_type']}';
          final tb = '${b['item_type']}';
          final c = ta.compareTo(tb);
          if (c != 0) {
            return c;
          }
          return '${a['item_id']}'.compareTo('${b['item_id']}');
        });
        return sorted;
      }
      return list;
    }
    return v;
  }

  static String canonicalJsonForSigning(Map<String, dynamic> payload) {
    return jsonEncode(_normalize(payload));
  }
}

Future<String> signLocalEconomyPayload(
  String userId,
  Map<String, dynamic> payloadWithoutIntegrity,
) async {
  final canonical = LocalEconomyIntegrity.canonicalJsonForSigning(
    payloadWithoutIntegrity,
  );
  final deviceSecret = await economyDeviceSecretBytes();
  final keyMaterial = <int>[...utf8.encode(userId), ...deviceSecret];
  final hmacKey = sha256.convert(keyMaterial).bytes;
  final h = Hmac(sha256, hmacKey);
  return h.convert(utf8.encode(canonical)).toString();
}

Future<bool> verifyLocalEconomyPayload(
  String userId,
  Map<String, dynamic> payloadWithoutIntegrity,
  String sigHex,
) async {
  final next = await signLocalEconomyPayload(userId, payloadWithoutIntegrity);
  return next.toLowerCase() == sigHex.trim().toLowerCase();
}
