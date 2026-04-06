import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/models/feed_post.dart';
import 'package:gggom_tarot/widgets/feed_tab.dart';

void main() {
  test('FeedPost JSON 직렬화·복원', () {
    final p = FeedPost(
      id: 7,
      userId: 'u1',
      username: '나',
      avatar: '🔮',
      timeAgo: '4월 1일, 12:00',
      content: '본문',
      imageUrl: 'data:image/png;base64,abc',
      heartCount: 2,
      tags: const ['a', 'b'],
      comments: [
        FeedComment(
          id: 1,
          postId: 7,
          userId: 'u2',
          username: '상대',
          avatar: '🌙',
          content: '댓',
          createdAt: '2026-01-01T00:00:00Z',
        ),
      ],
      likes: const ['u1', 'u3'],
    );
    final json = jsonEncode(p.toJson());
    final back = FeedPost.fromJson(jsonDecode(json) as Map<String, dynamic>);
    expect(back.id, p.id);
    expect(back.content, p.content);
    expect(back.imageUrl, p.imageUrl);
    expect(back.comments.length, 1);
    expect(back.likes.length, 2);
  });

  test('orderedFeedPosts: 최신순·오래된순·인기순', () {
    final posts = [
      FeedPost(
        id: 1,
        username: 'a',
        avatar: '🔮',
        timeAgo: '1월 1일',
        content: 'old',
        heartCount: 1,
        tags: const [],
        comments: const [],
        likes: const [],
      ),
      FeedPost(
        id: 3,
        username: 'b',
        avatar: '🔮',
        timeAgo: '1월 3일',
        content: 'new',
        heartCount: 10,
        tags: const [],
        comments: const [],
        likes: const [],
      ),
      FeedPost(
        id: 2,
        username: 'c',
        avatar: '🔮',
        timeAgo: '1월 2일',
        content: 'mid',
        heartCount: 5,
        tags: const [],
        comments: const [],
        likes: const [],
      ),
    ];

    expect(
      orderedFeedPosts(posts, FeedSortMode.newest).map((e) => e.id).toList(),
      [3, 2, 1],
    );
    expect(
      orderedFeedPosts(posts, FeedSortMode.oldest).map((e) => e.id).toList(),
      [1, 2, 3],
    );
    expect(
      orderedFeedPosts(posts, FeedSortMode.popular).map((e) => e.id).toList(),
      [3, 2, 1],
    );
  });
}
