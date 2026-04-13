import '../data/mat_themes.dart';
import '../models/shop_models.dart';

/// [matThemes]와 동일한 타로 매트 상점 행 — 로컬 기본 카탈로그와 공통 사용.
List<ShopItemRow> bundledMatShopRows() {
  final mats = <ShopItemRow>[];
  for (var i = 0; i < matThemes.length; i++) {
    final m = matThemes[i];
    mats.add(
      ShopItemRow(
        id: m.id,
        name: m.name,
        type: 'mat',
        price: m.id == MatThemeData.defaultId ? 0 : 4 + ((i - 1) % 6),
        thumbnailUrl: null,
        isActive: true,
      ),
    );
  }
  return mats;
}
