import '../models/emoticon_models.dart';
import 'shop_random_prices.dart';
import 'starter_gifts.dart';

/// 채팅·가방에서 쓰는 내장 이모티콘 팩 ID (DB 팩과 구분).
const String kBundleEmoticonPackId = 'assets_emoticon_bundle';

/// `assets/emoticon/emo_01.png` ~ `emo_61.png` (61장). 괄호 파일명은 웹 에셋 URL에서 실패할 수 있어 제거함.
const int kBundleEmoticonCount = 61;

Map<String, int> _buildBundleEmoticonPriceMap() {
  final ids =
      [
        for (var i = 1; i <= kBundleEmoticonCount; i++)
          'emo_asset_${i.toString().padLeft(2, '0')}',
      ]..sort((a, b) {
        final ha = gggomStableStarPrice(
          'emo_price_bucket_v2|$a',
          min: 1,
          max: 1000000,
        );
        final hb = gggomStableStarPrice(
          'emo_price_bucket_v2|$b',
          min: 1,
          max: 1000000,
        );
        if (ha != hb) {
          return ha.compareTo(hb);
        }
        return a.compareTo(b);
      });

  final out = <String, int>{};
  for (var i = 0; i < ids.length; i++) {
    final id = ids[i];
    if (i < 5) {
      out[id] = 2;
      continue;
    }
    if (i < 10) {
      out[id] = 3;
      continue;
    }
    if (i < 15) {
      out[id] = 4;
      continue;
    }
    out[id] = 1;
  }
  return out;
}

final Map<String, int> _kBundleEmoticonPriceMap =
    _buildBundleEmoticonPriceMap();

/// 상점 단품(별조각) — 61개 분포를 고정합니다.
/// - ⭐2: 5개
/// - ⭐3: 5개
/// - ⭐4: 5개
/// - 나머지: ⭐1
///
/// [dayUtc] 는 하위 호환용이며 가격 계산에 사용하지 않습니다.
int bundleEmoticonShopPriceFromId(String emoticonId, [DateTime? dayUtc]) {
  return _kBundleEmoticonPriceMap[emoticonId] ?? 1;
}

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
  final n = index1Based.toString().padLeft(2, '0');
  return 'assets/emoticon/emo_$n.png';
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

final Set<String> kBundleEmoticonIds = kBundleEmoticonRows
    .map((e) => e.id)
    .toSet();

bool isBundledEmoticonId(String id) => kBundleEmoticonIds.contains(id);

/// `emo_asset_01` 등 → `assets/emoticon/emo_01.png`
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
