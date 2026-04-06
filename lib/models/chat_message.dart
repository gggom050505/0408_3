class ChatMessageRow {
  ChatMessageRow({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.messageType,
    this.emoticonId,
    required this.createdAt,
  });

  final int id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final String messageType;
  final String? emoticonId;
  final String createdAt;

  factory ChatMessageRow.fromJson(Map<String, dynamic> j) {
    return ChatMessageRow(
      id: (j['id'] as num).toInt(),
      userId: j['user_id'] as String,
      username: j['username'] as String? ?? '',
      avatarUrl: j['avatar_url'] as String?,
      content: j['content'] as String? ?? '',
      messageType: j['message_type'] as String? ?? 'text',
      emoticonId: j['emoticon_id'] as String?,
      createdAt: j['created_at'] as String? ?? '',
    );
  }
}
