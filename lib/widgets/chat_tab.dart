import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/emoticon_offline.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../standalone/data_sources.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';
import 'chat_marquee_warning.dart';
import 'emoticon_picker_sheet.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({
    super.key,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.emoticonRepo,
    required this.onNeedLogin,
  });

  final String? userId;
  final String displayName;
  final String? avatarUrl;
  final EmoticonDataSource emoticonRepo;
  final VoidCallback onNeedLogin;

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  late ChatRepository _repo;
  List<ChatMessageRow> _messages = [];
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = true;
  Map<String, String> _emoticonUrlById = {};

  @override
  void initState() {
    super.initState();
    _repo = ChatRepository(Supabase.instance.client);
    _init();
  }

  Future<void> _init() async {
    if (widget.userId == null || !AppConfig.supabaseEnabled) {
      setState(() => _loading = false);
      return;
    }
    await _loadEmoticonMap();
    await _fetchRecent();
    _repo.subscribe(
      onInsert: (m) {
        if (_messages.any((x) => x.id == m.id)) {
          return;
        }
        setState(() => _messages = [..._messages, m]);
        _scrollToBottom();
      },
      onDelete: (id) {
        setState(() => _messages = _messages.where((m) => m.id != id).toList());
      },
    );
  }

  Future<void> _loadEmoticonMap() async {
    try {
      final all = await widget.emoticonRepo.fetchAllEmoticons();
      setState(() {
        _emoticonUrlById = {
          for (final e in all)
            e.id: resolveEmoticonImageSrc(
              remoteImageUrl: e.imageUrl,
              emoticonId: e.id,
            ),
        };
      });
    } catch (_) {}
  }

  Future<void> _fetchRecent() async {
    setState(() => _loading = true);
    try {
      final list = await _repo.fetchRecent();
      if (mounted) {
        setState(() {
          _messages = list;
          _hasMore = list.length >= 50;
          _loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadOlder() async {
    if (!_hasMore || _loadingMore || _messages.isEmpty) {
      return;
    }
    setState(() => _loadingMore = true);
    final oldest = _messages.first.id;
    final beforeScroll = _scroll.hasClients ? _scroll.position.pixels : 0.0;
    final beforeMax = _scroll.hasClients ? _scroll.position.maxScrollExtent : 0.0;
    try {
      final r = await _repo.fetchOlder(oldest);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = [...r.older, ..._messages];
        _hasMore = r.hasMore;
        _loadingMore = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) {
          return;
        }
        final delta = _scroll.position.maxScrollExtent - beforeMax;
        _scroll.jumpTo(beforeScroll + delta);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) {
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final uid = widget.userId;
    if (uid == null) {
      widget.onNeedLogin();
      return;
    }
    final t = _input.text.trim();
    if (t.isEmpty) {
      return;
    }
    _input.clear();
    final msg = await _repo.sendText(
      userId: uid,
      username: widget.displayName,
      avatarUrl: widget.avatarUrl,
      content: t,
    );
    if (msg != null && mounted && !_messages.any((m) => m.id == msg.id)) {
      setState(() => _messages = [..._messages, msg]);
      _scrollToBottom();
    }
  }

  Future<void> _sendEmo(String emoticonId) async {
    final uid = widget.userId;
    if (uid == null) {
      return;
    }
    final msg = await _repo.sendEmoticon(
      userId: uid,
      username: widget.displayName,
      avatarUrl: widget.avatarUrl,
      emoticonId: emoticonId,
    );
    if (msg != null && mounted && !_messages.any((m) => m.id == msg.id)) {
      setState(() => _messages = [..._messages, msg]);
      _scrollToBottom();
    }
  }

  Future<void> _maybeDelete(ChatMessageRow m) async {
    if (m.userId != widget.userId) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 메시지를 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    final prev = List<ChatMessageRow>.from(_messages);
    setState(() => _messages = _messages.where((x) => x.id != m.id).toList());
    try {
      await _repo.deleteMessage(m.id);
    } catch (_) {
      if (mounted) {
        setState(() => _messages = prev);
      }
    }
  }

  @override
  void dispose() {
    _repo.unsubscribe();
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  String _timeLabel(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) {
      return '';
    }
    return TimeOfDay.fromDateTime(d.toLocal()).format(context);
  }

  String _dateLabel(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) {
      return '';
    }
    return '${d.year}년 ${d.month}월 ${d.day}일';
  }

  bool _sameDay(String a, String b) {
    final da = DateTime.tryParse(a);
    final db = DateTime.tryParse(b);
    if (da == null || db == null) {
      return false;
    }
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.userId;

    if (uid == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4C8E8), Color(0xFFC0B0D8)],
                  ),
                ),
                child: const Center(child: Text('💬', style: TextStyle(fontSize: 32))),
              ),
              const SizedBox(height: 16),
              Text(
                '로그인 후 채팅에 참여할 수 있어요!',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💬 채팅',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '실시간으로 대화해보세요!',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const ChatMarqueeWarningBar(),
        Expanded(
          child: _loading && _messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _messages.isEmpty
                      ? 3
                      : _messages.length + 2,
                  itemBuilder: (context, idx) {
                    if (_messages.isEmpty) {
                      if (idx == 0) {
                        return const SizedBox.shrink();
                      }
                      if (idx == 1) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: Text(
                              '아직 메시지가 없습니다. 첫 메시지를 보내보세요!',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox(height: 8);
                    }
                    if (idx == 0) {
                      if (!_hasMore) {
                        return const SizedBox.shrink();
                      }
                      return Center(
                        child: TextButton(
                          onPressed: _loadingMore ? null : _loadOlder,
                          child: Text(_loadingMore ? '로딩…' : '이전 메시지 더 보기'),
                        ),
                      );
                    }
                    final i = idx - 1;
                    if (i >= _messages.length) {
                      return const SizedBox(height: 8);
                    }
                    final msg = _messages[i];
                    final isMe = msg.userId == uid;
                    final showDate = i == 0 || !_sameDay(_messages[i - 1].createdAt, msg.createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate)
                          Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _dateLabel(msg.createdAt),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment:
                              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              _smallAvatar(msg.avatarUrl),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Column(
                                crossAxisAlignment:
                                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      msg.username,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: GestureDetector(
                                          onLongPress: () => _maybeDelete(msg),
                                          child: msg.messageType == 'emoticon' &&
                                                  msg.emoticonId != null
                                              ? Padding(
                                                  padding: const EdgeInsets.all(4),
                                                  child: AdaptiveNetworkOrAssetImage(
                                                    src: resolveEmoticonImageSrc(
                                                      remoteImageUrl:
                                                          _emoticonUrlById[msg.emoticonId!] ?? '',
                                                      emoticonId: msg.emoticonId,
                                                    ),
                                                    width: 72,
                                                    height: 72,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, _, _) =>
                                                        const Text('😊', style: TextStyle(fontSize: 36)),
                                                  ),
                                                )
                                              : Container(
                                                  margin: const EdgeInsets.only(top: 4),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: isMe
                                                        ? const LinearGradient(
                                                            colors: [
                                                              Color(0xFFB89CD4),
                                                              Color(0xFFA088C2),
                                                            ],
                                                          )
                                                        : null,
                                                    color: isMe
                                                        ? null
                                                        : Colors.white.withValues(alpha: 0.65),
                                                    borderRadius: BorderRadius.only(
                                                      topLeft: const Radius.circular(18),
                                                      topRight: const Radius.circular(18),
                                                      bottomLeft: Radius.circular(isMe ? 18 : 6),
                                                      bottomRight: Radius.circular(isMe ? 6 : 18),
                                                    ),
                                                    border: isMe
                                                        ? null
                                                        : Border.all(
                                                            color: AppColors.cardBorder
                                                                .withValues(alpha: 0.08),
                                                          ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(
                                                          alpha: isMe ? 0.12 : 0.05,
                                                        ),
                                                        blurRadius: 8,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    msg.content,
                                                    style: TextStyle(
                                                      color: isMe ? Colors.white : AppColors.textPrimary,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _timeLabel(msg.createdAt),
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: AppColors.textSecondary.withValues(alpha: 0.6),
                                              fontSize: 9,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
        ),
        Material(
          color: Colors.white.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (c) => EmoticonPickerSheet(
                        repo: widget.emoticonRepo,
                        userId: uid,
                        onPick: _sendEmo,
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.6),
                  ),
                  icon: const Text('😊', style: TextStyle(fontSize: 18)),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    maxLength: 500,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '메시지 입력…',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(
                          color: AppColors.cardBorder.withValues(alpha: 0.1),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                  ),
                  onPressed: _sendText,
                  child: const Text('전송'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _smallAvatar(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: url != null && (url.startsWith('http') || url.startsWith('assets/'))
          ? AdaptiveNetworkOrAssetImage(src: url, width: 28, height: 28, fit: BoxFit.cover)
          : Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD4C8E8), Color(0xFFC0B0D8)],
                ),
              ),
              child: const Text('🔮', style: TextStyle(fontSize: 12)),
            ),
    );
  }
}
