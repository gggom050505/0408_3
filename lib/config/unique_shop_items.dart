import '../models/emoticon_models.dart';
import '../models/shop_models.dart';

const int kUniqueKoreaMajorCount = 7;
const int kUniqueOracleCount = 24;
const int kUniqueEmoticonCount = 12;

Set<String> _buildUniqueKoreaMajorIds() => {
  for (var i = 0; i < kUniqueKoreaMajorCount; i++)
    'korea-major-${i.toString().padLeft(2, '0')}',
};

Set<String> _buildUniqueOracleIds() => {
  for (var i = 1; i <= kUniqueOracleCount; i++)
    'oracle-card-${i.toString().padLeft(2, '0')}',
};

Set<String> _buildUniqueEmoticonIds() => {
  for (var i = 1; i <= kUniqueEmoticonCount; i++)
    'emo_asset_${i.toString().padLeft(2, '0')}',
};

final Set<String> kUniqueKoreaMajorItemIds = _buildUniqueKoreaMajorIds();
final Set<String> kUniqueOracleItemIds = _buildUniqueOracleIds();
final Set<String> kUniqueEmoticonIds = _buildUniqueEmoticonIds();

bool isUniqueShopItem(String itemId, String itemType) {
  final normalizedId = itemId.trim();
  if (normalizedId.isEmpty) {
    return false;
  }
  final type = itemType.trim().toLowerCase();
  if (type == 'korea_major_card') {
    final m = RegExp(r'^korea-major-(\d+)$').firstMatch(normalizedId);
    if (m != null) {
      final n = int.tryParse(m.group(1)!);
      if (n != null) {
        return kUniqueKoreaMajorItemIds.contains(
          'korea-major-${n.toString().padLeft(2, '0')}',
        );
      }
    }
    return kUniqueKoreaMajorItemIds.contains(normalizedId);
  }
  if (type == 'oracle_card' || type == 'oracle') {
    final m = RegExp(r'^oracle-card-(\d+)$').firstMatch(normalizedId);
    if (m != null) {
      final n = int.tryParse(m.group(1)!);
      if (n != null) {
        return kUniqueOracleItemIds.contains(
          'oracle-card-${n.toString().padLeft(2, '0')}',
        );
      }
    }
    return kUniqueOracleItemIds.contains(normalizedId);
  }
  if (type == 'emoticon') {
    return isUniqueEmoticonId(normalizedId);
  }
  return false;
}

bool isUniqueShopItemRow(ShopItemRow row) => isUniqueShopItem(row.id, row.type);

bool isUniqueEmoticonId(String emoticonId) =>
    kUniqueEmoticonIds.contains(emoticonId);

bool isUniqueEmoticonRow(EmoticonRow row) => isUniqueEmoticonId(row.id);

/// 상점 진열 순서 — **ID 번호순이 아니라** 고정 salt 해시로 섞인 것처럼 보이게.
int gggomShopShelfDisplayRank(String shelfKey, String itemId) =>
    Object.hashAll([shelfKey, itemId, 'gggom_shelf_shuffle_v1']);
