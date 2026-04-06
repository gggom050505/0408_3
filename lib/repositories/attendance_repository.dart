import 'package:supabase_flutter/supabase_flutter.dart';

import '../standalone/data_sources.dart';

class AttendanceRepository implements AttendanceDataSource {
  AttendanceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> checkToday(String userId) async {
    final d = DateTime.now();
    final today =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final row = await _client
        .from('user_check_ins')
        .select('id')
        .eq('user_id', userId)
        .eq('check_in_date', today)
        .maybeSingle();
    return row != null;
  }

  /// `daily_check_in` RPC. 반환 형식은 웹과 동일하게 맵으로 옴.
  @override
  Future<Map<String, dynamic>?> doCheckIn(String userId) async {
    final res = await _client.rpc('daily_check_in', params: {'p_user_id': userId});
    if (res == null) {
      return null;
    }
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return null;
  }
}
