class FeedComment {
  FeedComment({
    required this.id,
    required this.postId,
    this.userId,
    required this.username,
    required this.avatar,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final int postId;
  final String? userId;
  final String username;
  final String avatar;
  final String content;
  final String createdAt;

  factory FeedComment.fromJson(Map<String, dynamic> j) {
    return FeedComment(
      id: (j['id'] as num).toInt(),
      postId: (j['post_id'] as num).toInt(),
      userId: j['user_id'] as String?,
      username: j['username'] as String? ?? '',
      avatar: j['avatar'] as String? ?? '🔮',
      content: j['content'] as String? ?? '',
      createdAt: j['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'user_id': userId,
        'username': username,
        'avatar': avatar,
        'content': content,
        'created_at': createdAt,
      };

  FeedComment copyWith({String? content}) {
    return FeedComment(
      id: id,
      postId: postId,
      userId: userId,
      username: username,
      avatar: avatar,
      content: content ?? this.content,
      createdAt: createdAt,
    );
  }
}

class FeedPost {
  FeedPost({
    required this.id,
    this.userId,
    required this.username,
    required this.avatar,
    required this.timeAgo,
    required this.content,
    this.imageUrl,
    required this.heartCount,
    required this.tags,
    required this.comments,
    required this.likes,
  });

  final int id;
  final String? userId;
  final String username;
  final String avatar;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  final int heartCount;
  final List<String> tags;
  final List<FeedComment> comments;
  final List<String> likes;

  factory FeedPost.fromJson(Map<String, dynamic> j) {
    final commentsRaw = j['comments'] as List<dynamic>? ?? [];
    return FeedPost(
      id: (j['id'] as num).toInt(),
      userId: j['user_id'] as String?,
      username: j['username'] as String? ?? '',
      avatar: j['avatar'] as String? ?? '🔮',
      timeAgo: j['time_ago'] as String? ?? '',
      content: j['content'] as String? ?? '',
      imageUrl: j['image_url'] as String?,
      heartCount: (j['heart_count'] as num?)?.toInt() ?? 0,
      tags: (j['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      comments: commentsRaw
          .map((e) => FeedComment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      likes: (j['likes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'username': username,
        'avatar': avatar,
        'time_ago': timeAgo,
        'content': content,
        'image_url': imageUrl,
        'heart_count': heartCount,
        'tags': tags,
        'comments': comments.map((c) => c.toJson()).toList(),
        'likes': likes,
      };

  FeedPost copyWith({
    int? heartCount,
    List<String>? likes,
    List<FeedComment>? comments,
    String? content,
    String? timeAgo,
  }) {
    return FeedPost(
      id: id,
      userId: userId,
      username: username,
      avatar: avatar,
      timeAgo: timeAgo ?? this.timeAgo,
      content: content ?? this.content,
      imageUrl: imageUrl,
      heartCount: heartCount ?? this.heartCount,
      tags: tags,
      comments: comments ?? this.comments,
      likes: likes ?? this.likes,
    );
  }
}
