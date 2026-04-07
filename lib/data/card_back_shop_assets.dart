import '../config/shop_random_prices.dart';
import '../models/shop_models.dart';

/// `assets/card_back/` 6종 — 상점 `type: card_back`. 품목별 **4~6 별** 고정가.
List<ShopItemRow> bundledCardBackShopRows() => [
      ShopItemRow(
        id: 'card-back-cat',
        name: '카드 뒷면 (고양이)',
        type: 'card_back',
        price: gggomFixedStarPrice('card-back-cat', min: 4, max: 6),
        thumbnailUrl: 'assets/card_back/back_cat.png',
        isActive: true,
      ),
      ShopItemRow(
        id: 'card-back-dog',
        name: '카드 뒷면 (강아지)',
        type: 'card_back',
        price: gggomFixedStarPrice('card-back-dog', min: 4, max: 6),
        thumbnailUrl: 'assets/card_back/back_dog.png',
        isActive: true,
      ),
      ShopItemRow(
        id: 'card-back-moon',
        name: '카드 뒷면 (달)',
        type: 'card_back',
        price: gggomFixedStarPrice('card-back-moon', min: 4, max: 6),
        thumbnailUrl: 'assets/card_back/back_moon.png',
        isActive: true,
      ),
      ShopItemRow(
        id: 'card-back-tiger',
        name: '카드 뒷면 (호랑이)',
        type: 'card_back',
        price: gggomFixedStarPrice('card-back-tiger', min: 4, max: 6),
        thumbnailUrl: 'assets/card_back/back_tiger.png',
        isActive: true,
      ),
      ShopItemRow(
        id: 'card-back-wonyeos',
        name: '카드 뒷면 (워녀스)',
        type: 'card_back',
        price: gggomFixedStarPrice('card-back-wonyeos', min: 4, max: 6),
        thumbnailUrl: 'assets/card_back/back_wonyeos.png',
        isActive: true,
      ),
      ShopItemRow(
        id: 'card-back-owl',
        name: '카드 뒷면 (부엉이)',
        type: 'card_back',
        price: gggomFixedStarPrice('card-back-owl', min: 4, max: 6),
        thumbnailUrl: 'assets/card_back/back_owl.png',
        isActive: true,
      ),
    ];
