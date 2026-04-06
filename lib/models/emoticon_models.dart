class EmoticonRow {
  EmoticonRow({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.packId,
    required this.price,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String? packId;
  final int price;
  final int sortOrder;
  final bool isActive;

  factory EmoticonRow.fromJson(Map<String, dynamic> j) {
    return EmoticonRow(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      imageUrl: j['image_url'] as String? ?? '',
      packId: j['pack_id'] as String?,
      price: (j['price'] as num?)?.toInt() ?? 0,
      sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      isActive: j['is_active'] as bool? ?? true,
    );
  }
}

class EmoticonPackRow {
  EmoticonPackRow({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnailUrl,
    required this.price,
    required this.isActive,
    required this.sortOrder,
    required this.emoticons,
  });

  final String id;
  final String name;
  final String description;
  final String? thumbnailUrl;
  final int price;
  final bool isActive;
  final int sortOrder;
  final List<EmoticonRow> emoticons;

  factory EmoticonPackRow.fromJson(Map<String, dynamic> j, List<EmoticonRow> emoticons) {
    return EmoticonPackRow(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      description: j['description'] as String? ?? '',
      thumbnailUrl: j['thumbnail_url'] as String?,
      price: (j['price'] as num?)?.toInt() ?? 0,
      isActive: j['is_active'] as bool? ?? true,
      sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      emoticons: emoticons,
    );
  }
}
