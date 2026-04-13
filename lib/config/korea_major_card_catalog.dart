import '../data/card_themes.dart';
import '../data/tarot_cards.dart';
import '../models/shop_models.dart';
import 'shop_random_prices.dart';

/// 한국전통 메이저 카드 한 장 단위 상점 ID (`korea-major-00` ~ `korea-major-21`).
String koreaMajorCardShopItemId(int cardIndex0to21) {
  assert(cardIndex0to21 >= 0 && cardIndex0to21 <= 21);
  return 'korea-major-${cardIndex0to21.toString().padLeft(2, '0')}';
}

int? koreaMajorCardIndexFromShopItemId(String id) {
  if (!id.startsWith('korea-major-')) {
    return null;
  }
  final tail = id.substring('korea-major-'.length);
  final n = int.tryParse(tail);
  if (n == null || n < 0 || n > 21) {
    return null;
  }
  return n;
}

/// 한국전통 메이저 조각 — **7~9 별** 고정가(품목별 해시 기반).
///
/// [dayUtc] 는 하위 호환용이며 가격 계산에 사용하지 않습니다.
int koreaMajorPieceShopStarPrice(int cardIndex0to21, [DateTime? dayUtc]) {
  final id = koreaMajorCardShopItemId(cardIndex0to21);
  return gggomFixedStarPrice(id, min: 7, max: 9);
}

/// 상점·로컬 카탈로그에 넣는 한국전통 메이저 22장 행.
List<ShopItemRow> koreaMajorCardShopCatalogRows([DateTime? dayUtc]) {
  return List<ShopItemRow>.generate(22, (i) {
    final card = tarotMajorArcanaOnly[i];
    return ShopItemRow(
      id: koreaMajorCardShopItemId(i),
      name: '한국전통 · ${card.nameKo}',
      type: 'korea_major_card',
      price: koreaMajorPieceShopStarPrice(i, dayUtc),
      thumbnailUrl: koreaTraditionalMajorAssetPath(i),
      isActive: true,
    );
  });
}
