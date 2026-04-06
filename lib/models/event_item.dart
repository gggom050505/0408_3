class EventItemRow {
  EventItemRow({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.gradient,
    this.badgeText,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.sortOrder,
  });

  final int id;
  final String title;
  final String description;
  final String type;
  final String? gradient;
  final String? badgeText;
  final String startDate;
  final String? endDate;
  final bool isActive;
  final int sortOrder;

  factory EventItemRow.fromJson(Map<String, dynamic> j) {
    return EventItemRow(
      id: (j['id'] as num).toInt(),
      title: j['title'] as String? ?? '',
      description: j['description'] as String? ?? '',
      type: j['type'] as String? ?? '',
      gradient: j['gradient'] as String?,
      badgeText: j['badge_text'] as String?,
      startDate: j['start_date'] as String? ?? '',
      endDate: j['end_date'] as String?,
      isActive: j['is_active'] as bool? ?? true,
      sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
