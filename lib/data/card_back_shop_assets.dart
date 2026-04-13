import '../models/shop_models.dart';

/// 카드 뒷면 가격표:
/// - 3 별: 2개
/// - 4 별: 2개
/// - 5 별: 2개
int cardBackShopStarPriceForId(String id) {
  return switch (id) {
    'card-back-cat' => 3,
    'card-back-owl' => 3,
    'card-back-moon' => 4,
    'card-back-wonyeos' => 4,
    'card-back-dog' => 5,
    'card-back-tiger' => 5,
    _ => 3,
  };
}

/// `assets/card_back/` 6종 — 상점 `type: card_back`.
List<ShopItemRow> bundledCardBackShopRows() => [
  ShopItemRow(
    id: 'card-back-cat',
    name: '카드 뒷면 (고양이)',
    type: 'card_back',
    price: cardBackShopStarPriceForId('card-back-cat'),
    thumbnailUrl: 'assets/card_back/back_cat.png',
    isActive: true,
  ),
  ShopItemRow(
    id: 'card-back-dog',
    name: '카드 뒷면 (강아지)',
    type: 'card_back',
    price: cardBackShopStarPriceForId('card-back-dog'),
    thumbnailUrl: 'assets/card_back/back_dog.png',
    isActive: true,
  ),
  ShopItemRow(
    id: 'card-back-moon',
    name: '카드 뒷면 (달)',
    type: 'card_back',
    price: cardBackShopStarPriceForId('card-back-moon'),
    thumbnailUrl: 'assets/card_back/back_moon.png',
    isActive: true,
  ),
  ShopItemRow(
    id: 'card-back-tiger',
    name: '카드 뒷면 (호랑이)',
    type: 'card_back',
    price: cardBackShopStarPriceForId('card-back-tiger'),
    thumbnailUrl: 'assets/card_back/back_tiger.png',
    isActive: true,
  ),
  ShopItemRow(
    id: 'card-back-wonyeos',
    name: '카드 뒷면 (워녀스)',
    type: 'card_back',
    price: cardBackShopStarPriceForId('card-back-wonyeos'),
    thumbnailUrl: 'assets/card_back/back_wonyeos.png',
    isActive: true,
  ),
  ShopItemRow(
    id: 'card-back-owl',
    name: '카드 뒷면 (부엉이)',
    type: 'card_back',
    price: cardBackShopStarPriceForId('card-back-owl'),
    thumbnailUrl: 'assets/card_back/back_owl.png',
    isActive: true,
  ),
];
