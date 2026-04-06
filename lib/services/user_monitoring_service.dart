import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Supabase 로그인 사용자의「최근 접속」갱신 및 앱 내 활동 로그 적재.
/// [docs/supabase_admin_monitoring.sql] 스키마가 있어야 동작합니다.
class UserMonitoringService {
  UserMonitoringService._();
  static final UserMonitoringService instance = UserMonitoringService._();

  static const _presenceTable = 'gggom_user_presence';
  static const _eventsTable = 'gggom_user_app_events';

  Timer? _timer;
  var _started = false;

  void syncWithSession(Session? session) {
    if (!AppConfig.supabaseEnabled || session == null) {
      stop();
      return;
    }
    if (_started) {
      unawaited(_touchPresence());
      return;
    }
    _started = true;
    unawaited(_touchPresence());
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(_touchPresence());
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  void onAppResumed() {
    if (!_started) {
      return;
    }
    unawaited(_touchPresence());
  }

  String _displayNameFromUser(User user) {
    final m = user.userMetadata;
    if (m == null) {
      return '사용자';
    }
    final a = m['full_name'] ?? m['name'];
    if (a is String && a.isNotEmpty) {
      return a;
    }
    return user.email ?? '사용자';
  }

  Future<void> _touchPresence() async {
    if (!AppConfig.supabaseEnabled) {
      return;
    }
    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      if (session == null) {
        return;
      }
      final user = session.user;
      final now = DateTime.now().toUtc().toIso8601String();
      await client.from(_presenceTable).upsert(
        {
          'user_id': user.id,
          'email': user.email,
          'display_name': _displayNameFromUser(user),
          'last_seen_at': now,
        },
        onConflict: 'user_id',
      );
    } catch (e, st) {
      assert(() {
        debugPrint('UserMonitoringService._touchPresence: $e\n$st');
        return true;
      }());
    }
  }

  /// 관리자 모니터링용. 실패해도 UX를 막지 않음.
  Future<void> logAppEvent(String action, {String? detail}) async {
    if (!AppConfig.supabaseEnabled) {
      return;
    }
    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      if (session == null) {
        return;
      }
      final user = session.user;
      final d = detail?.trim();
      await client.from(_eventsTable).insert({
        'user_id': user.id,
        'email': user.email,
        'display_name': _displayNameFromUser(user),
        'action': action,
        if (d != null && d.isNotEmpty) 'detail': d.length > 500 ? d.substring(0, 500) : d,
      });
    } catch (e, st) {
      assert(() {
        debugPrint('UserMonitoringService.logAppEvent: $e\n$st');
        return true;
      }());
    }
  }

  @visibleForTesting
  void debugResetForTest() {
    stop();
  }
}
