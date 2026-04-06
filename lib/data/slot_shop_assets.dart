import '../models/shop_models.dart';

/// 가방·타로 기본 장착 슬롯 테두리.
const String kDefaultEquippedSlotId = 'slot-decor-1';

/// `(id, 이름, assets/slot/… png)` — 상점 `type: slot`, 빈 슬롯 배경으로 동일 에셋 사용.
const List<(String, String, String)> kBundledSlotShopAssetTuples = [
  (
    'slot-decor-1',
    '카드 슬롯 · 아이보리 레이스',
    'assets/slot/Gemini_Generated_Image_6s11ca6s11ca6s11.png',
  ),
  (
    'slot-decor-2',
    '카드 슬롯 · 로즈 프레임',
    'assets/slot/Gemini_Generated_Image_tmnkxgtmnkxgtmnk.png',
  ),
  (
    'slot-decor-3',
    '카드 슬롯 · 바이오렛',
    'assets/slot/Gemini_Generated_Image_riq4lfriq4lfriq4.png',
  ),
  (
    'slot-decor-4',
    '카드 슬롯 · 딥 퍼플',
    'assets/slot/Gemini_Generated_Image_9m9k839m9k839m9k.png',
  ),
];

int _slotStarPrice(String id) {
  if (id == kDefaultEquippedSlotId) {
    return 0;
  }
  final idx = kBundledSlotShopAssetTuples.indexWhere((e) => e.$1 == id);
  if (idx < 0) {
    return 4;
  }
  return 3 + idx;
}

List<ShopItemRow> bundledSlotShopRows() {
  return [
    for (final t in kBundledSlotShopAssetTuples)
      ShopItemRow(
        id: t.$1,
        name: t.$2,
        type: 'slot',
        price: _slotStarPrice(t.$1),
        thumbnailUrl: t.$3,
        isActive: true,
      ),
  ];
}

/// 번들 카탈로그 기준 PNG 경로 (장착 ID만 알 때).
String? bundledSlotAssetPathForShopId(String id) {
  for (final t in kBundledSlotShopAssetTuples) {
    if (t.$1 == id) {
      return t.$3;
    }
  }
  return null;
}
