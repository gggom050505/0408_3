import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/feed_tags.dart';
import '../models/feed_post.dart';
import '../standalone/data_sources.dart';
import '../standalone/local_app_preferences.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';
import 'feed_post_capture.dart';

String _formatTimeKoFromDate(DateTime d) {
  const months = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${months[d.month - 1]} ${d.day}일, $h:$m';
}

enum FeedSortMode {
  newest,
  oldest,
  popular,
  /// 본문 `합계 N점` 파싱(오늘의 타로 게시). 없으면 맨 아래.
  tarotScore,
}

/// 오늘의 타로 게시 본문에서 합계 점수만 추출. 없으기 null.
int? parseTodayTarotTotalScoreFromPostContent(String content) {
  final m = RegExp(r'합계\s*(\d+)\s*점').firstMatch(content);
  if (m == null) {
    return null;
  }
  return int.tryParse(m.group(1)!);
}

List<FeedPost> orderedFeedPosts(List<FeedPost> posts, FeedSortMode sort) {
  final copy = List<FeedPost>.from(posts);
  switch (sort) {
    case FeedSortMode.newest:
      copy.sort((a, b) => b.id.compareTo(a.id));
    case FeedSortMode.oldest:
      copy.sort((a, b) => a.id.compareTo(b.id));
    case FeedSortMode.popular:
      copy.sort((a, b) {
        final h = b.heartCount.compareTo(a.heartCount);
        if (h != 0) {
          return h;
        }
        return b.id.compareTo(a.id);
      });
    case FeedSortMode.tarotScore:
      copy.sort((a, b) {
        final sa = parseTodayTarotTotalScoreFromPostContent(a.content);
        final sb = parseTodayTarotTotalScoreFromPostContent(b.content);
        if (sa != null || sb != null) {
          final va = sa ?? -1;
          final vb = sb ?? -1;
          if (va != vb) {
            return vb.compareTo(va);
          }
        }
        return b.id.compareTo(a.id);
      });
  }
  return copy;
}

/// 게시물 `tags`와 매칭(앞의 `#` 무시).
String _normalizeFeedTag(String raw) {
  var s = raw.trim();
  if (s.startsWith('#')) {
    s = s.substring(1);
  }
  return s;
}

bool _feedPostMatchesTagFilter(FeedPost post, String? filterKey) {
  if (filterKey == null || filterKey.isEmpty) {
    return true;
  }
  final needle = filterKey.trim();
  for (final t in post.tags) {
    final n = _normalizeFeedTag(t);
    if (n == needle || n.contains(needle) || needle.contains(n)) {
      return true;
    }
  }
  return false;
}

bool _isHiddenSystemTag(String raw) {
  final n = _normalizeFeedTag(raw);
  return n == kFeedTagTarotSpreadMatchKey || n == kFeedTagTodayTarotMatchKey;
}

class FeedTab extends StatefulWidget {
  const FeedTab({
    super.key,
    required this.feed,
    required this.currentUserId,
    required this.displayName,
    required this.avatar,
    required this.onNeedLogin,

    /// 설정 시 태그 필터가 고정되고, 아래 칩 행은 숨깁니다. (GNB «오늘의 게시» 전용)
    this.fixedTagFilterKey,
    this.listHeaderTitle,
  });

  final FeedDataSource feed;
  final String? currentUserId;
  final String displayName;
  final String avatar;
  final VoidCallback onNeedLogin;

  /// 예: `'오늘의타로'`
  final String? fixedTagFilterKey;

  /// 목록 위 안내 한 줄(고정 필터 탭용)
  final String? listHeaderTitle;

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  List<FeedPost> _posts = [];
  var _loading = true;
  String? _error;
  FeedSortMode _sort = FeedSortMode.newest;
  /// `null`이면 태그 필터 «전체».
  String? _selectedTagKey;

  bool get _tagFilterLocked => widget.fixedTagFilterKey != null;

  @override
  void initState() {
    super.initState();
    if (widget.fixedTagFilterKey != null) {
      _selectedTagKey = widget.fixedTagFilterKey;
      // 고정 태그 탭(예: 오늘의 게시) 기본 정렬은 항상 최신순으로 시작한다.
      _sort = FeedSortMode.newest;
    } else {
      unawaited(_restoreFeedSort());
    }
    _load();
  }

  bool get _showTarotScoreSort =>
      widget.fixedTagFilterKey == null ||
      widget.fixedTagFilterKey == kFeedTagTodayTarotMatchKey;

  Future<void> _restoreFeedSort() async {
    final name = await LocalAppPreferences.getFeedSortName();
    if (!mounted || name == null || name.isEmpty) {
      return;
    }
    for (final m in FeedSortMode.values) {
      if (m.name == name) {
        setState(() => _sort = m);
        return;
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.feed.fetchPosts();
      if (mounted) {
        setState(() {
          _posts = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _heart(FeedPost post) async {
    final uid = widget.currentUserId;
    if (uid == null) {
      widget.onNeedLogin();
      return;
    }
    final isLiked = post.likes.contains(uid);
    final newCount = isLiked ? post.heartCount - 1 : post.heartCount + 1;
    final newLikes = isLiked
        ? post.likes.where((id) => id != uid).toList()
        : [...post.likes, uid];
    setState(() {
      _posts = _posts
          .map(
            (p) => p.id == post.id
                ? p.copyWith(heartCount: newCount, likes: newLikes)
                : p,
          )
          .toList();
    });
    try {
      await widget.feed.toggleHeart(postId: post.id, userId: uid, post: post);
    } catch (_) {
      await _load();
    }
  }

  Future<void> _delete(FeedPost post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('정말 이 게시물을 삭제하시겠습니까? (복구할 수 없습니다)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    try {
      await widget.feed.deletePost(post.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  Future<void> _updatePost(FeedPost post, String newContent) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final timeLabel = _formatTimeKoFromDate(now);
    setState(() {
      final updated = post.copyWith(content: trimmed, timeAgo: timeLabel);
      final rest = _posts.where((p) => p.id != post.id).toList();
      _posts = [updated, ...rest];
    });
    try {
      await widget.feed.updatePost(post.id, trimmed);
    } catch (e) {
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 실패: $e')),
      );
    }
  }

  Future<void> _addComment(FeedPost post, String text) async {
    final uid = widget.currentUserId;
    if (uid == null) {
      widget.onNeedLogin();
      return;
    }
    try {
      final c = await widget.feed.addComment(
        postId: post.id,
        userId: uid,
        username: widget.displayName,
        avatar: widget.avatar,
        content: text,
      );
      setState(() {
        _posts = _posts
            .map(
              (p) => p.id == post.id
                  ? p.copyWith(comments: [...p.comments, c])
                  : p,
            )
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteComment(FeedPost post, int commentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    setState(() {
      _posts = _posts
          .map(
            (p) => p.id == post.id
                ? p.copyWith(
                    comments: p.comments.where((c) => c.id != commentId).toList(),
                  )
                : p,
          )
          .toList();
    });
    try {
      await widget.feed.deleteComment(commentId);
    } catch (e) {
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 삭제 실패: $e')),
      );
    }
  }

  Future<void> _updateComment(FeedPost post, int commentId, String newContent) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty) {
      return;
    }
    setState(() {
      _posts = _posts
          .map(
            (p) => p.id == post.id
                ? p.copyWith(
                    comments: p.comments
                        .map((c) => c.id == commentId ? c.copyWith(content: trimmed) : c)
                        .toList(),
                  )
                : p,
          )
          .toList();
    });
    try {
      await widget.feed.updateComment(commentId, trimmed);
    } catch (e) {
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 수정 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }
    final effectiveTag = _tagFilterLocked ? widget.fixedTagFilterKey : _selectedTagKey;
    final effectiveSort =
        !_showTarotScoreSort && _sort == FeedSortMode.tarotScore
            ? FeedSortMode.newest
            : _sort;
    final ordered = orderedFeedPosts(_posts, effectiveSort);
    final filtered =
        ordered.where((p) => _feedPostMatchesTagFilter(p, effectiveTag)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.listHeaderTitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: AppColors.accentPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.listHeaderTitle!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '정렬',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<FeedSortMode>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  segments: [
                    const ButtonSegment(
                      value: FeedSortMode.newest,
                      label: Text('최신순'),
                      icon: Icon(Icons.schedule, size: 14),
                    ),
                    const ButtonSegment(
                      value: FeedSortMode.oldest,
                      label: Text('오래된순'),
                      icon: Icon(Icons.history, size: 14),
                    ),
                    const ButtonSegment(
                      value: FeedSortMode.popular,
                      label: Text('좋아요순'),
                      icon: Icon(Icons.favorite_outline, size: 14),
                    ),
                    if (_showTarotScoreSort)
                      const ButtonSegment(
                        value: FeedSortMode.tarotScore,
                        label: Text('타로점수순'),
                        icon: Icon(Icons.psychology_outlined, size: 14),
                      ),
                  ],
                  selected: {effectiveSort},
                  onSelectionChanged: (s) {
                    final mode = s.first;
                    setState(() => _sort = mode);
                    if (!_tagFilterLocked) {
                      unawaited(LocalAppPreferences.setFeedSortName(mode.name));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        if (!_tagFilterLocked)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final opt in kFeedTagChips)
                  _FeedTagPill(
                    label: opt.label,
                    selected: opt.matchKey == _selectedTagKey,
                    onTap: () => setState(() => _selectedTagKey = opt.matchKey),
                  ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
                    children: [
                      Center(
                        child: Text(
                          effectiveTag == null
                              ? '게시물이 없습니다'
                              : '이 태그의 게시물이 없습니다',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final p = filtered[i];
                return _PostTile(
                  key: ValueKey('post-${p.id}-${effectiveSort.name}-${effectiveTag ?? 'all'}'),
                  post: p,
                  assetOrigin: AppConfig.assetOrigin,
                  currentUserId: widget.currentUserId,
                  isMine: widget.currentUserId != null && widget.currentUserId == p.userId,
                  isLiked: widget.currentUserId != null && p.likes.contains(widget.currentUserId),
                  onHeart: () => _heart(p),
                  onDelete: () => _delete(p),
                  onComment: (t) => _addComment(p, t),
                  onUpdatePost: (content) => _updatePost(p, content),
                  onDeleteComment: (cid) => _deleteComment(p, cid),
                  onUpdateComment: (cid, text) => _updateComment(p, cid, text),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedTagPill extends StatelessWidget {
  const _FeedTagPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _selectedBg = Color(0xFFC4B5E0);
  static const _unselectedBg = Color(0xFFFAF8F4);
  static const _unselectedBorder = Color(0xFFE5DDD4);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? _selectedBg : _unselectedBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _selectedBg : _unselectedBorder,
              width: selected ? 1 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: selected ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostTile extends StatefulWidget {
  const _PostTile({
    super.key,
    required this.post,
    required this.assetOrigin,
    required this.currentUserId,
    required this.isMine,
    required this.isLiked,
    required this.onHeart,
    required this.onDelete,
    required this.onComment,
    required this.onUpdatePost,
    required this.onDeleteComment,
    required this.onUpdateComment,
  });

  final FeedPost post;
  final String assetOrigin;
  final String? currentUserId;
  final bool isMine;
  final bool isLiked;
  final VoidCallback onHeart;
  final VoidCallback onDelete;
  final ValueChanged<String> onComment;
  final ValueChanged<String> onUpdatePost;
  final ValueChanged<int> onDeleteComment;
  final void Function(int commentId, String text) onUpdateComment;

  @override
  State<_PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<_PostTile> {
  var _showComments = false;
  final _c = TextEditingController();
  var _editingPost = false;
  late final TextEditingController _editPostCtrl = TextEditingController(text: widget.post.content);
  int? _editingCommentId;
  final _editCommentCtrl = TextEditingController();

  @override
  void didUpdateWidget(covariant _PostTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id == widget.post.id &&
        oldWidget.post.content != widget.post.content &&
        !_editingPost) {
      _editPostCtrl.text = widget.post.content;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _editPostCtrl.dispose();
    _editCommentCtrl.dispose();
    super.dispose();
  }

  void _toggleEditPost() {
    if (_editingPost) {
      widget.onUpdatePost(_editPostCtrl.text);
      setState(() => _editingPost = false);
    } else {
      _editPostCtrl.text = widget.post.content;
      setState(() => _editingPost = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final visibleTags = p.tags.where((t) => !_isHiddenSystemTag(t)).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(avatar: p.avatar, size: 36),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.username,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        p.timeAgo,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (widget.isMine)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _toggleEditPost,
                        child: Text(_editingPost ? '저장' : '수정'),
                      ),
                      if (_editingPost)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _editingPost = false;
                              _editPostCtrl.text = widget.post.content;
                            });
                          },
                          child: const Text('취소'),
                        )
                      else
                        TextButton(
                          onPressed: widget.onDelete,
                          style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
                          child: const Text('삭제'),
                        ),
                    ],
                  ),
              ],
            ),
            if (p.imageUrl != null) ...[
              const SizedBox(height: 8),
              FeedPostCapture(imageUrl: p.imageUrl!),
            ],
            const SizedBox(height: 8),
            if (_editingPost)
              TextField(
                controller: _editPostCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else if (p.content.trim().isNotEmpty)
              Text(p.content, style: Theme.of(context).textTheme.bodyMedium),
            if (p.tags.isNotEmpty && !_editingPost && visibleTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: visibleTags
                    .map(
                      (t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.purple.shade50,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: widget.onHeart,
                  icon: Icon(
                    widget.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: widget.isLiked ? Colors.red : AppColors.textSecondary,
                  ),
                ),
                Text('${p.heartCount}'),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => setState(() => _showComments = !_showComments),
                  child: Text('댓글 ${p.comments.length}'),
                ),
              ],
            ),
            if (_showComments) ...[
              const Divider(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in p.comments) ...[
                      _CommentRow(
                        comment: c,
                        isMyComment: widget.currentUserId != null && widget.currentUserId == c.userId,
                        isEditing: _editingCommentId == c.id,
                        editController: _editCommentCtrl,
                        onStartEdit: () {
                          setState(() {
                            _editingCommentId = c.id;
                            _editCommentCtrl.text = c.content;
                          });
                        },
                        onSaveEdit: () {
                          final id = _editingCommentId;
                          if (id != null) {
                            widget.onUpdateComment(id, _editCommentCtrl.text);
                          }
                          setState(() => _editingCommentId = null);
                        },
                        onCancelEdit: () => setState(() => _editingCommentId = null),
                        onDelete: () => widget.onDeleteComment(c.id),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      decoration: const InputDecoration(
                        hintText: '댓글 입력',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final t = _c.text.trim();
                      if (t.isEmpty) {
                        return;
                      }
                      widget.onComment(t);
                      _c.clear();
                      setState(() => _showComments = true);
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.isMyComment,
    required this.isEditing,
    required this.editController,
    required this.onStartEdit,
    required this.onSaveEdit,
    required this.onCancelEdit,
    required this.onDelete,
  });

  final FeedComment comment;
  final bool isMyComment;
  final bool isEditing;
  final TextEditingController editController;
  final VoidCallback onStartEdit;
  final VoidCallback onSaveEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = comment;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(avatar: c.avatar, size: 26),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    if (isMyComment && !isEditing) ...[
                      const Spacer(),
                      TextButton(
                        onPressed: onStartEdit,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('수정', style: TextStyle(fontSize: 11)),
                      ),
                      TextButton(
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          foregroundColor: Colors.red.shade400,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('삭제', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ],
                ),
                if (isEditing)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: editController,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(isDense: true),
                      ),
                      Row(
                        children: [
                          TextButton(onPressed: onSaveEdit, child: const Text('저장', style: TextStyle(fontSize: 11))),
                          TextButton(onPressed: onCancelEdit, child: const Text('취소', style: TextStyle(fontSize: 11))),
                        ],
                      ),
                    ],
                  )
                else
                  Text(c.content, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar, required this.size});

  final String avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final showImage =
        avatar.startsWith('http') || avatar.startsWith('assets/');
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFE8DFF5), Color(0xFFD4C8EB)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: showImage
          ? AdaptiveNetworkOrAssetImage(src: avatar, fit: BoxFit.cover)
          : Text(avatar, style: TextStyle(fontSize: size * 0.45)),
    );
  }
}
