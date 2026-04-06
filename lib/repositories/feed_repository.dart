import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/feed_post.dart';
import '../standalone/data_sources.dart';

String _formatTimeKo(String dateStr) {
  final d = DateTime.tryParse(dateStr);
  if (d == null) {
    return dateStr;
  }
  const months = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${months[d.month - 1]} ${d.day}일, $h:$m';
}

FeedPost _mapRow(Map<String, dynamic> row) {
  final likesRaw = row['post_likes'] as List<dynamic>?;
  final likes = likesRaw == null
      ? <String>[]
      : likesRaw
          .map((e) => (e as Map)['user_id'] as String?)
          .whereType<String>()
          .toList();

  final commentsRaw = row['comments'] as List<dynamic>?;
  final comments = commentsRaw == null
      ? <FeedComment>[]
      : commentsRaw
          .map((e) => FeedComment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

  return FeedPost(
    id: row['id'] as int,
    userId: row['user_id'] as String?,
    username: row['username'] as String? ?? '',
    avatar: row['avatar'] as String? ?? '🔮',
    timeAgo: _formatTimeKo(row['created_at'] as String? ?? ''),
    content: row['content'] as String? ?? '',
    imageUrl: row['image_url'] as String?,
    heartCount: (row['heart_count'] as num?)?.toInt() ?? 0,
    tags: (row['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    comments: comments,
    likes: likes,
  );
}

class FeedRepository implements FeedDataSource {
  FeedRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<FeedPost>> fetchPosts() async {
    final res = await _client
        .from('posts')
        .select('*, comments(*), post_likes(user_id)')
        .order('created_at', ascending: false);
    final list = res as List<dynamic>;
    return list.map((e) => _mapRow(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<FeedPost?> addPost({
    required String? userId,
    required String username,
    required String avatar,
    required String content,
    required List<String> tags,
    List<int>? imagePngBytes,
  }) async {
    String? imageUrl;
    if (imagePngBytes != null && imagePngBytes.isNotEmpty) {
      final fileName =
          'post_${DateTime.now().millisecondsSinceEpoch}_${userId ?? 'anon'}.png';
      await _client.storage.from('post-images').uploadBinary(
            fileName,
            Uint8List.fromList(imagePngBytes),
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: false,
            ),
          );
      imageUrl = _client.storage.from('post-images').getPublicUrl(fileName);
    }

    final inserted = await _client.from('posts').insert({
      'user_id': userId,
      'username': username,
      'avatar': avatar,
      'content': content,
      'image_url': imageUrl,
      'tags': tags,
    }).select().single();

    final map = Map<String, dynamic>.from(inserted);
    map['comments'] = <dynamic>[];
    map['post_likes'] = <dynamic>[];
    return _mapRow(map);
  }

  @override
  Future<void> toggleHeart({required int postId, required String userId, required FeedPost post}) async {
    final isLiked = post.likes.contains(userId);
    final newCount = (isLiked ? post.heartCount - 1 : post.heartCount + 1).clamp(0, 1 << 30);
    if (isLiked) {
      await _client.from('post_likes').delete().eq('post_id', postId).eq('user_id', userId);
    } else {
      await _client.from('post_likes').insert({'post_id': postId, 'user_id': userId});
    }
    await _client.from('posts').update({'heart_count': newCount}).eq('id', postId);
  }

  @override
  Future<FeedComment> addComment({
    required int postId,
    required String? userId,
    required String username,
    required String avatar,
    required String content,
  }) async {
    final row = await _client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'username': username,
      'avatar': avatar,
      'content': content,
    }).select().single();
    return FeedComment.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> deletePost(int postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }

  /// 웹 `updatePost`와 동일: `created_at`을 갱신해 목록 상단 정렬과 맞춤.
  @override
  Future<void> updatePost(int postId, String newContent) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('posts').update({
      'content': newContent,
      'created_at': now,
    }).eq('id', postId);
  }

  @override
  Future<void> deleteComment(int commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  @override
  Future<void> updateComment(int commentId, String newContent) async {
    await _client.from('comments').update({'content': newContent}).eq('id', commentId);
  }
}
