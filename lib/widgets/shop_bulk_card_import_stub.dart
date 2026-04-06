import '../models/shop_models.dart';

/// 웹 등: IO 없음 — null 반환 (호출 측에서 안내).
Future<List<ShopItemRow>?> pickAndRegisterCardDeckImages({
  required List<ShopItemRow> existingItems,
}) async =>
    null;

Future<List<ShopItemRow>?> pickAndRegisterMatImages({
  required List<ShopItemRow> existingItems,
}) async =>
    null;

Future<List<ShopItemRow>?> pickAndRegisterCardBackImages({
  required List<ShopItemRow> existingItems,
}) async =>
    null;

Future<String?> pickAndCopyThumbnailForShopItem({required String itemId}) async =>
    null;
