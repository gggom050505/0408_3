import 'dart:convert';

import '../models/feed_post.dart';
import 'data_sources.dart';
import 'local_json_store.dart';

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

/// 설치형 단독 실행용 — 피드·댓글·좋아요를 기기에 저장해 앱을 껐다 켜도 유지됩니다.
class LocalFeedRepository implements FeedDataSource {
  LocalFeedRepository();

  static const _fileName = 'local_feed_v1.json';

  final _posts = <FeedPost>[];
  var _nextPostId = 1;
  var _nextCommentId = 1;
  Future<void>? _hydrateFuture;

  Future<void> _ensureHydrated() {
    _hydrateFuture ??= _hydrateImpl();
    return _hydrateFuture!;
  }

  /// `jsonDecode` 후 `version`이 int가 아니면(예: double) 예전 코드는 복원에 실패해 환영 글만 남는 문제가 있었음.
  static int? _readVersion(Map<String, dynamic> map) {
    final v = map['version'];
    if (v == null) {
      return map.containsKey('posts') ? 1 : null;
    }
    if (v is int) {
      return v;
    }
    if (v is num) {
      return v.toInt();
    }
    return null;
  }

  Future<void> _hydrateImpl() async {
    try {
      final raw = await loadLocalJsonFile(_fileName);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final version = _readVersion(map);
        if (version == 1) {
          final list = map['posts'] as List<dynamic>? ?? [];
          _posts.clear();
          for (final e in list) {
            try {
              _posts.add(FeedPost.fromJson(Map<String, dynamic>.from(e as Map)));
            } catch (_) {}
          }
          _nextPostId = (map['next_post_id'] as num?)?.toInt() ?? _inferNextPostId();
          _nextCommentId = (map['next_comment_id'] as num?)?.toInt() ?? _inferNextCommentId();
          return;
        }
      }
    } catch (_) {}
    _posts.clear();
    _seedWelcomePost();
    _nextPostId = _inferNextPostId();
    _nextCommentId = _inferNextCommentId();
    await _persist();
  }

  void _seedWelcomePost() {
    final now = DateTime.now().toUtc().toIso8601String();
    _posts.add(
      FeedPost(
        id: 1,
        userId: 'local-beta',
        username: '공공곰타로덱(베타·오프라인)',
        avatar: '🔮',
        timeAgo: _formatTimeKo(now),
        content: '베타·오프라인 번들입니다. 여기서 올린 글은 이 기기에 저장되어 앱을 다시 실행해도 남아요.',
        imageUrl: null,
        heartCount: 3,
        tags: const ['베타', '오프라인'],
        comments: [],
        likes: [],
      ),
    );
    _nextPostId = 2;
    _nextCommentId = 1;
  }

  int _inferNextPostId() {
    if (_posts.isEmpty) {
      return 1;
    }
    return _posts.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  int _inferNextCommentId() {
    var m = 0;
    for (final p in _posts) {
      for (final c in p.comments) {
        if (c.id > m) {
          m = c.id;
        }
      }
    }
    return m + 1;
  }

  Future<void> _persist() async {
    final payload = <String, dynamic>{
      'version': 1,
      'next_post_id': _nextPostId,
      'next_comment_id': _nextCommentId,
      'posts': _posts.map((e) => e.toJson()).toList(),
    };
    await saveLocalJsonFile(_fileName, jsonEncode(payload));
  }

  @override
  Future<List<FeedPost>> fetchPosts() async {
    await _ensureHydrated();
    return List<FeedPost>.from(_posts.reversed);
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
    await _ensureHydrated();
    String? imageUrl;
    if (imagePngBytes != null && imagePngBytes.isNotEmpty) {
      imageUrl = 'data:image/png;base64,${base64Encode(imagePngBytes)}';
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final post = FeedPost(
      id: _nextPostId++,
      userId: userId,
      username: username,
      avatar: avatar,
      timeAgo: _formatTimeKo(now),
      content: content,
      imageUrl: imageUrl,
      heartCount: 0,
      tags: tags,
      comments: [],
      likes: [],
    );
    _posts.add(post);
    await _persist();
    return post;
  }

  @override
  Future<void> toggleHeart({
    required int postId,
    required String userId,
    required FeedPost post,
  }) async {
    await _ensureHydrated();
    final i = _posts.indexWhere((e) => e.id == postId);
    if (i < 0) {
      return;
    }
    final p0 = _posts[i];
    final liked = p0.likes.contains(userId);
    final nextLikes =
        liked ? p0.likes.where((id) => id != userId).toList() : [...p0.likes, userId];
    final nextCount = (liked ? p0.heartCount - 1 : p0.heartCount + 1).clamp(0, 1 << 30);
    _posts[i] = p0.copyWith(likes: nextLikes, heartCount: nextCount);
    await _persist();
  }

  @override
  Future<void> deletePost(int postId) async {
    await _ensureHydrated();
    _posts.removeWhere((e) => e.id == postId);
    await _persist();
  }

  @override
  Future<void> updatePost(int postId, String newContent) async {
    await _ensureHydrated();
    final i = _posts.indexWhere((e) => e.id == postId);
    if (i < 0) {
      return;
    }
    final p0 = _posts[i];
    _posts[i] = p0.copyWith(
      content: newContent,
      timeAgo: _formatTimeKo(DateTime.now().toUtc().toIso8601String()),
    );
    await _persist();
  }

  @override
  Future<FeedComment> addComment({
    required int postId,
    required String? userId,
    required String username,
    required String avatar,
    required String content,
  }) async {
    await _ensureHydrated();
    final c = FeedComment(
      id: _nextCommentId++,
      postId: postId,
      userId: userId,
      username: username,
      avatar: avatar,
      content: content,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    final pi = _posts.indexWhere((e) => e.id == postId);
    if (pi >= 0) {
      final p0 = _posts[pi];
      _posts[pi] = p0.copyWith(comments: [...p0.comments, c]);
    }
    await _persist();
    return c;
  }

  @override
  Future<void> deleteComment(int commentId) async {
    await _ensureHydrated();
    for (var i = 0; i < _posts.length; i++) {
      final p0 = _posts[i];
      final next = p0.comments.where((c) => c.id != commentId).toList();
      if (next.length != p0.comments.length) {
        _posts[i] = p0.copyWith(comments: next);
        await _persist();
        return;
      }
    }
  }

  @override
  Future<void> updateComment(int commentId, String newContent) async {
    await _ensureHydrated();
    for (var i = 0; i < _posts.length; i++) {
      final p0 = _posts[i];
      final next = p0.comments
          .map((c) => c.id == commentId ? c.copyWith(content: newContent) : c)
          .toList();
      if (next.any((c) => c.id == commentId && c.content == newContent)) {
        _posts[i] = p0.copyWith(comments: next);
        await _persist();
        return;
      }
    }
  }
}
