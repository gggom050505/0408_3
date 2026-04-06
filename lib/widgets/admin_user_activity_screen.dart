import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/shop_admin_gate.dart';
import '../theme/app_colors.dart';

const _presenceTable = 'gggom_user_presence';
const _eventsTable = 'gggom_user_app_events';

class _PresenceRow {
  _PresenceRow({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.lastSeenAt,
  });

  factory _PresenceRow.fromJson(Map<String, dynamic> j) {
    final id = j['user_id'];
    return _PresenceRow(
      userId: id is String ? id : '$id',
      email: j['email'] as String? ?? '',
      displayName: j['display_name'] as String? ?? '',
      lastSeenAt: DateTime.tryParse(j['last_seen_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String userId;
  final String email;
  final String displayName;
  final DateTime lastSeenAt;
}

class _EventRow {
  _EventRow({
    required this.id,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.action,
    required this.detail,
    required this.createdAt,
  });

  factory _EventRow.fromJson(Map<String, dynamic> j) {
    final idRaw = j['id'];
    final uid = j['user_id'];
    return _EventRow(
      id: idRaw is int ? idRaw : (idRaw is num ? idRaw.toInt() : 0),
      userId: uid is String ? uid : '$uid',
      email: j['email'] as String? ?? '',
      displayName: j['display_name'] as String? ?? '',
      action: j['action'] as String? ?? '',
      detail: j['detail'] as String?,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final int id;
  final String userId;
  final String email;
  final String displayName;
  final String action;
  final String? detail;
  final DateTime createdAt;
}

/// 관리자 전용: 최근 접속 사용자 수·목록과 앱 내 활동 로그.
class AdminUserActivityScreen extends StatefulWidget {
  const AdminUserActivityScreen({
    super.key,
    this.enforceSupabaseAdminGate = true,
  });

  /// [ShopAdminScreen.enforceSupabaseAdminGate] 와 동일한 용도.
  final bool enforceSupabaseAdminGate;

  @override
  State<AdminUserActivityScreen> createState() => _AdminUserActivityScreenState();
}

class _AdminUserActivityScreenState extends State<AdminUserActivityScreen> {
  static const _onlineWindow = Duration(minutes: 5);

  List<_PresenceRow> _onlineUsers = [];
  List<_EventRow> _events = [];
  var _loading = true;
  String? _error;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _unsubscribe() {
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      unawaited(Supabase.instance.client.removeChannel(ch));
    }
  }

  void _subscribeRealtime() {
    if (widget.enforceSupabaseAdminGate && !shopAdminGateAllowsCurrentUser()) {
      return;
    }
    try {
      final ch = Supabase.instance.client.channel('admin_monitor_${DateTime.now().millisecondsSinceEpoch}');
      ch
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: _presenceTable,
            callback: (_) {
              if (mounted) {
                unawaited(_load());
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: _eventsTable,
            callback: (_) {
              if (mounted) {
                unawaited(_load());
              }
            },
          )
          .subscribe();
      _channel = ch;
    } catch (_) {}
  }

  Future<void> _load() async {
    if (widget.enforceSupabaseAdminGate && !shopAdminGateAllowsCurrentUser()) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final threshold = DateTime.now().toUtc().subtract(_onlineWindow).toIso8601String();
      final presRes = await client
          .from(_presenceTable)
          .select()
          .gte('last_seen_at', threshold)
          .order('last_seen_at', ascending: false);
      final evRes = await client.from(_eventsTable).select().order('created_at', ascending: false).limit(200);
      final presList = (presRes as List<dynamic>)
          .map((e) => _PresenceRow.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final evList = (evRes as List<dynamic>)
          .map((e) => _EventRow.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (mounted) {
        setState(() {
          _onlineUsers = presList;
          _events = evList;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  String _formatKo(DateTime utc) {
    final l = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}.${two(l.month)}.${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enforceSupabaseAdminGate && !shopAdminGateAllowsCurrentUser()) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: AppBar(title: const Text('접속·활동')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '이 화면은\n$kShopAdminGoogleEmail\n구글 계정으로 로그인한 경우에만 쓸 수 있어요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C2D12).withValues(alpha: 0.12),
        foregroundColor: AppColors.textPrimary,
        title: const Text('접속·활동 모니터'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      '데이터를 불러오지 못했어요.\n\n$_error\n\n'
                      'Supabase에 docs/supabase_admin_monitoring.sql 을 적용했는지 확인해 주세요.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('다시 시도')),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      Card(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '최근 ${_onlineWindow.inMinutes}분 안 접속',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_onlineUsers.length}명',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: const Color(0xFF9A3412),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Text(
                                '앱이 켜져 있고 하트비트가 온 사용자입니다. 설정은 user_monitoring_service 주기·$_onlineWindow 기준입니다.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '접속 중 사용자',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (_onlineUsers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            '표시할 사용자가 없어요. 다른 기기에서 앱을 켜두면 여기에 나타납니다.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ..._onlineUsers.map(
                          (u) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.white.withValues(alpha: 0.88),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              title: Text(
                                u.displayName.isNotEmpty ? u.displayName : '(이름 없음)',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${u.email.isNotEmpty ? u.email : '이메일 없음'}\n'
                                'ID: ${u.userId}\n'
                                '마지막: ${_formatKo(u.lastSeenAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        '최근 활동 (최대 200건)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (_events.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '기록된 활동이 없어요. 탭 이동·채팅·피드 등에서 로그가 쌓입니다.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ..._events.map(
                          (e) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.white.withValues(alpha: 0.88),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              title: Text(
                                e.action,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                [
                                  '${e.displayName} · ${e.email}',
                                  'ID: ${e.userId}',
                                  if (e.detail != null && e.detail!.isNotEmpty) e.detail!,
                                  _formatKo(e.createdAt),
                                ].join('\n'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
