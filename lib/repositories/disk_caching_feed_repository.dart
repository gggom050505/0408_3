import 'dart:convert';

import '../models/feed_post.dart';
import '../standalone/data_sources.dart';
import '../standalone/local_json_store.dart';

/// 원격(Supabase) 피드 사용 시에도 **마지막으로 가져온 목록**을
/// `local_feed_remote_snapshot_v1.json`에 자동 저장합니다.
/// 재시작 직후나 일시적 네트워크 오류 시 캐시 목록을 돌려줍니다.
class DiskCachingFeedRepository implements FeedDataSource {
  DiskCachingFeedRepository(this._inner);

  final FeedDataSource _inner;

  /// `lib/standalone/local_user_data_wipe.dart` 의 `_kFeedRemoteSnapshotFile` 와 동일해야 합니다.
  static const _cacheFile = 'local_feed_remote_snapshot_v1.json';

  Future<void> _saveSnapshot(List<FeedPost> posts) async {
    final payload = <String, dynamic>{
      'version': 1,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'posts': posts.map((e) => e.toJson()).toList(),
    };
    await saveLocalJsonFile(_cacheFile, jsonEncode(payload));
  }

  Future<List<FeedPost>?> _loadSnapshot() async {
    try {
      final raw = await loadLocalJsonFile(_cacheFile);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if ((map['version'] as num?)?.toInt() != 1) {
        return null;
      }
      final list = map['posts'] as List<dynamic>? ?? [];
      final out = <FeedPost>[];
      for (final e in list) {
        try {
          out.add(FeedPost.fromJson(Map<String, dynamic>.from(e as Map)));
        } catch (_) {}
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshSnapshotBestEffort() async {
    try {
      final list = await _inner.fetchPosts();
      await _saveSnapshot(list);
    } catch (_) {}
  }

  @override
  Future<List<FeedPost>> fetchPosts() async {
    try {
      final list = await _inner.fetchPosts();
      await _saveSnapshot(list);
      return list;
    } catch (_) {
      final cached = await _loadSnapshot();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
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
    final p = await _inner.addPost(
      userId: userId,
      username: username,
      avatar: avatar,
      content: content,
      tags: tags,
      imagePngBytes: imagePngBytes,
    );
    await _refreshSnapshotBestEffort();
    return p;
  }

  @override
  Future<void> toggleHeart({
    required int postId,
    required String userId,
    required FeedPost post,
  }) async {
    await _inner.toggleHeart(postId: postId, userId: userId, post: post);
    await _refreshSnapshotBestEffort();
  }

  @override
  Future<void> deletePost(int postId) async {
    await _inner.deletePost(postId);
    await _refreshSnapshotBestEffort();
  }

  @override
  Future<void> updatePost(int postId, String newContent) async {
    await _inner.updatePost(postId, newContent);
    await _refreshSnapshotBestEffort();
  }

  @override
  Future<FeedComment> addComment({
    required int postId,
    required String? userId,
    required String username,
    required String avatar,
    required String content,
  }) async {
    final c = await _inner.addComment(
      postId: postId,
      userId: userId,
      username: username,
      avatar: avatar,
      content: content,
    );
    await _refreshSnapshotBestEffort();
    return c;
  }

  @override
  Future<void> deleteComment(int commentId) async {
    await _inner.deleteComment(commentId);
    await _refreshSnapshotBestEffort();
  }

  @override
  Future<void> updateComment(int commentId, String newContent) async {
    await _inner.updateComment(commentId, newContent);
    await _refreshSnapshotBestEffort();
  }
}
