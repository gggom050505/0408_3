import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/bundled_event_guides.dart';
import '../models/event_item.dart';
import '../standalone/data_sources.dart';

class EventRepository implements EventDataSource {
  EventRepository(this._client);

  final SupabaseClient _client;

  /// 웹 `EventTab`과 동일: 활성 이벤트 조회 후 날짜 필터.
  @override
  Future<List<EventItemRow>> fetchActiveEvents() async {
    final res = await _client
        .from('events')
        .select()
        .eq('is_active', true)
        .order('sort_order')
        .order('created_at', ascending: false);
    final list = res as List<dynamic>;
    final rows = list.map((e) => EventItemRow.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final fromDb = rows.where((ev) {
      final start = DateTime.tryParse(ev.startDate);
      if (start == null) {
        return false;
      }
      final startDay = DateTime(start.year, start.month, start.day);
      if (startDay.isAfter(today)) {
        return false;
      }
      final endStr = ev.endDate;
      if (endStr != null && endStr.isNotEmpty) {
        final end = DateTime.tryParse(endStr);
        if (end != null) {
          final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
          if (endDay.isBefore(today)) {
            return false;
          }
        }
      }
      return true;
    }).toList();

    /// 앱에 포함된 이용 가이드(타로·별조각·오라클·채팅 등) — DB 공지 앞에 붙임.
    final guides = bundledAppGuideEventCards();
    final dbIds = fromDb.map((e) => e.id).toSet();
    final extraGuides = guides.where((g) => !dbIds.contains(g.id)).toList();
    return [...extraGuides, ...fromDb];
  }
}
