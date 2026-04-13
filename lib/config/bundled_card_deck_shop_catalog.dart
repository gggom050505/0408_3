import '../data/card_themes.dart';
import '../models/shop_models.dart';

/// 무료 타로 덱 3종 — [MAKING_NOTES] 번들 카탈로그 병합용.
/// 로컬 `local_shop_catalog_v1.json` 등에서 빠지거나
/// `is_active: false` 로 막혀 있어도 상점·경제 로직이 같은 소스로 되돌립니다.
List<ShopItemRow> bundledCardDeckShopRows() {
  return [
    ShopItemRow(
      id: defaultThemeId,
      name: '기본 카드 덱',
      type: 'card',
      price: 0,
      thumbnailUrl: null,
      isActive: true,
    ),
    ShopItemRow(
      id: mixedMinorKoreaTraditionalMajorThemeId,
      name: '마이너 + 한국전통 메이저 (혼합)',
      type: 'card',
      price: 0,
      thumbnailUrl: 'cards/default/22_ace_wands.png',
      isActive: true,
    ),
    ShopItemRow(
      id: majorClayThemeId,
      name: '클레이 덱 (메이저 24 + 마이너 60)',
      type: 'card',
      price: 0,
      thumbnailUrl: 'assets/major/0 바보.png',
      isActive: true,
    ),
  ];
}
