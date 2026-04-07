import '../models/emoticon_models.dart';
import 'shop_random_prices.dart';
import 'starter_gifts.dart';

/// 채팅·가방에서 쓰는 내장 이모티콘 팩 ID (DB 팩과 구분).
const String kBundleEmoticonPackId = 'assets_emoticon_bundle';

/// `assets/emoticon/emoticon(1).png` ~ `emoticon(61).png` (61장).
const int kBundleEmoticonCount = 61;

/// 상점 단품(별조각) — 품목마다 **1~3 별** 중 해시로 고정된 가격.
///
/// [dayUtc] 는 하위 호환용이며 가격 계산에 사용하지 않습니다.
int bundleEmoticonShopPriceFromId(String emoticonId, [DateTime? dayUtc]) =>
    gggomFixedStarPrice(emoticonId, min: 1, max: 3);

/// 실제 표시·구매 가격 — 서비스 조합 5개는 0.
int bundleEmoticonPriceForUser(
  String emoticonId,
  String? userId, [
  DateTime? dayUtc,
]) {
  if (starterEmoticonIdsForUser(userId).contains(emoticonId)) {
    return 0;
  }
  return bundleEmoticonShopPriceFromId(emoticonId, dayUtc);
}

/// 번들 PNG — [Image.asset] / [AdaptiveNetworkOrAssetImage] 가 그대로 로드.
String bundleEmoticonAssetPath(int index1Based) {
  assert(index1Based >= 1 && index1Based <= kBundleEmoticonCount);
  return 'assets/emoticon/emoticon($index1Based).png';
}

final List<EmoticonRow> kBundleEmoticonRows = List.unmodifiable([
  for (var i = 1; i <= kBundleEmoticonCount; i++)
    EmoticonRow(
      id: 'emo_asset_${i.toString().padLeft(2, '0')}',
      name: '이모티콘 $i',
      imageUrl: bundleEmoticonAssetPath(i),
      packId: kBundleEmoticonPackId,
      price: bundleEmoticonShopPriceFromId(
        'emo_asset_${i.toString().padLeft(2, '0')}',
      ),
      sortOrder: i - 1,
      isActive: true,
    ),
]);

final Set<String> kBundleEmoticonIds = kBundleEmoticonRows.map((e) => e.id).toSet();

bool isBundledEmoticonId(String id) => kBundleEmoticonIds.contains(id);

/// `emo_asset_01` 등 → `assets/emoticon/emoticon(1).png`
String? bundleEmoticonImagePathForId(String emoticonId) {
  final raw = emoticonId.trim();
  if (raw.isEmpty) {
    return null;
  }
  for (final e in kBundleEmoticonRows) {
    if (e.id == raw) {
      return e.imageUrl;
    }
  }
  final lower = raw.toLowerCase();
  for (final e in kBundleEmoticonRows) {
    if (e.id.toLowerCase() == lower) {
      return e.imageUrl;
    }
  }
  final m = RegExp(r'^emo_asset_(\d+)$', caseSensitive: false).firstMatch(raw);
  if (m != null) {
    final n = int.tryParse(m.group(1)!);
    if (n != null && n >= 1 && n <= kBundleEmoticonCount) {
      return bundleEmoticonAssetPath(n);
    }
  }
  return null;
}
