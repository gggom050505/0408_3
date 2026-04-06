import '../models/emoticon_models.dart';
import 'shop_random_prices.dart';
import 'starter_gifts.dart';

/// 채팅·가방에서 쓰는 내장 이모티콘 팩 ID (DB 팩과 구분).
const String kBundleEmoticonPackId = 'assets_emoticon_bundle';

/// `assets/emoticon/emoticon(1).png` ~ `emoticon(61).png` (61장).
const int kBundleEmoticonCount = 61;

/// 상점 단품(별조각) — **UTC 일자마다** 바뀌는 난수형 가격.
///
/// [dayUtc] null이면 오늘 UTC.
int bundleEmoticonShopPriceFromId(String emoticonId, [DateTime? dayUtc]) =>
    gggomDailyStarPrice(emoticonId, dayUtc);

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
  for (final e in kBundleEmoticonRows) {
    if (e.id == emoticonId) {
      return e.imageUrl;
    }
  }
  return null;
}
