import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';

const _pageSize = 50;

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;

  /// 최신순으로 가져온 뒤 **오래된 순**으로 정렬 (웹 `chatStore`와 동일).
  Future<List<ChatMessageRow>> fetchRecent() async {
    final res = await _client
        .from('chat_messages')
        .select()
        .order('created_at', ascending: false)
        .limit(_pageSize);
    final list = (res as List<dynamic>).map((e) => ChatMessageRow.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    return list.reversed.toList();
  }

  Future<({List<ChatMessageRow> older, bool hasMore})> fetchOlder(int oldestId) async {
    final res = await _client
        .from('chat_messages')
        .select()
        .lt('id', oldestId)
        .order('created_at', ascending: false)
        .limit(_pageSize);
    final raw = res as List<dynamic>;
    final list = raw.map((e) => ChatMessageRow.fromJson(Map<String, dynamic>.from(e as Map))).toList().reversed.toList();
    return (older: list, hasMore: raw.length >= _pageSize);
  }

  Future<ChatMessageRow?> sendText({
    required String userId,
    required String username,
    String? avatarUrl,
    required String content,
  }) async {
    final row = await _client.from('chat_messages').insert({
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'content': content,
    }).select().single();
    return ChatMessageRow.fromJson(Map<String, dynamic>.from(row));
  }

  Future<ChatMessageRow?> sendEmoticon({
    required String userId,
    required String username,
    String? avatarUrl,
    required String emoticonId,
  }) async {
    final row = await _client.from('chat_messages').insert({
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'content': '',
      'message_type': 'emoticon',
      'emoticon_id': emoticonId,
    }).select().single();
    return ChatMessageRow.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteMessage(int id) async {
    await _client.from('chat_messages').delete().eq('id', id);
  }

  void subscribe({
    required void Function(ChatMessageRow msg) onInsert,
    required void Function(int id) onDelete,
  }) {
    _channel = _client.channel('chat_messages_realtime');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            if (payload.newRecord.isEmpty) {
              return;
            }
            final id = payload.newRecord['id'];
            if (id == null) {
              return;
            }
            onInsert(ChatMessageRow.fromJson(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final id = payload.oldRecord['id'];
            if (id is int) {
              onDelete(id);
            } else if (id is num) {
              onDelete(id.toInt());
            }
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    final ch = _channel;
    if (ch != null) {
      _client.removeChannel(ch);
      _channel = null;
    }
  }
}
