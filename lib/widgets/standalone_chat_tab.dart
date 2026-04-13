import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/emoticon_offline.dart';
import '../models/emoticon_models.dart';
import '../standalone/data_sources.dart';
import '../standalone/local_json_store.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';
import 'chat_marquee_warning.dart';
import 'emoticon_picker_sheet.dart';

class _LocalMsg {
  _LocalMsg({
    required this.text,
    required this.fromMe,
    this.emoticonId,
  });

  final String text;
  final bool fromMe;
  final String? emoticonId;
}

/// 기기 저장 로컬 채팅(오프라인·베타 번들). 대화는 재실행 후에도 유지됩니다.
class StandaloneChatTab extends StatefulWidget {
  const StandaloneChatTab({
    super.key,
    required this.displayName,
    required this.userId,
    required this.emoticonRepo,
  });

  final String displayName;
  final String userId;
  final EmoticonDataSource emoticonRepo;

  @override
  State<StandaloneChatTab> createState() => _StandaloneChatTabState();
}

class _StandaloneChatTabState extends State<StandaloneChatTab> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_LocalMsg>[];

  Map<String, EmoticonRow> _emoById = {};

  static const _legacyWelcomeText = '채팅에 오신 걸 환영해요. 아래 😊 버튼으로 이모티콘을 보낼 수 있어요.';

  String _storageFileName() {
    final safe = widget.userId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return 'local_chat_${safe}_v1.json';
  }

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await _tryRestore();
    if (!mounted) {
      return;
    }
    await _loadEmoticonMap();
  }

  /// 저장된 대화가 있으면 `true`.
  Future<bool> _tryRestore() async {
    try {
      final raw = await loadLocalJsonFile(_storageFileName());
      if (raw == null || raw.isEmpty) {
        return false;
      }
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ver = map['version'];
      final v = ver is int ? ver : (ver is num ? ver.toInt() : null);
      if (v != 1) {
        return false;
      }
      final arr = map['messages'] as List<dynamic>? ?? [];
      if (arr.isEmpty) {
        return false;
      }
      if (!mounted) {
        return true;
      }
      final restored = arr.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return _LocalMsg(
          text: m['text'] as String? ?? '',
          fromMe: m['from_me'] as bool? ?? false,
          emoticonId: m['emoticon_id'] as String?,
        );
      }).where((m) {
        // 이전 버전에서 자동 삽입된 환영 말풍선은 복원 시 제거합니다.
        final text = m.text.trim();
        final isLegacyWelcome =
            !m.fromMe && m.emoticonId == null && text == _legacyWelcomeText;
        return !isLegacyWelcome;
      }).toList();
      setState(() {
        _messages
          ..clear()
          ..addAll(restored);
      });
      // 오래된 환영 말풍선이 제거된 상태를 즉시 저장해 재진입 시 다시 보이지 않게 합니다.
      unawaited(_persistMessages());
      _scrollToEnd();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistMessages() async {
    final list = _messages
        .map(
          (m) => {
            'text': m.text,
            'from_me': m.fromMe,
            'emoticon_id': m.emoticonId,
          },
        )
        .toList();
    await saveLocalJsonFile(
      _storageFileName(),
      jsonEncode({
        'version': 1,
        'messages': list,
      }),
    );
  }

  Future<void> _loadEmoticonMap() async {
    try {
      final all = await widget.emoticonRepo.fetchAllEmoticons();
      if (!mounted) {
        return;
      }
      setState(() {
        _emoById = {for (final e in all) e.id: e};
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    final t = _input.text.trim();
    if (t.isEmpty) {
      return;
    }
    setState(() {
      _messages.add(_LocalMsg(text: t, fromMe: true));
      _input.clear();
    });
    _scrollToEnd();
    unawaited(_persistMessages());
  }

  void _sendEmoticon(String emoticonId) {
    setState(() {
      _messages.add(_LocalMsg(text: '', fromMe: true, emoticonId: emoticonId));
    });
    _scrollToEnd();
    unawaited(_persistMessages());
  }

  Future<void> _openEmoticonPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => EmoticonPickerSheet(
        repo: widget.emoticonRepo,
        userId: widget.userId,
        onPick: _sendEmoticon,
      ),
    );
  }

  Future<void> _confirmDeleteOwnMessage(int index) async {
    if (index < 0 || index >= _messages.length) {
      return;
    }
    final msg = _messages[index];
    if (!msg.fromMe) {
      return;
    }
    final isEmoticon = msg.emoticonId != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('채팅 삭제'),
        content: Text(isEmoticon ? '내 이모티콘을 삭제할까요?' : '내 채팅을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() {
      _messages.removeAt(index);
    });
    unawaited(_persistMessages());
  }

  Widget _bubbleChild(_LocalMsg m) {
    if (m.emoticonId != null) {
      final row = _emoById[m.emoticonId!];
      final src = resolveEmoticonImageSrc(
        remoteImageUrl: row?.imageUrl ?? '',
        emoticonId: m.emoticonId,
      );
      if (src.isEmpty) {
        return Text(
          row?.name ?? '😊',
          style: const TextStyle(fontSize: 48),
        );
      }
      return AdaptiveNetworkOrAssetImage(
        src: src,
        width: 92,
        height: 92,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Text(
          row?.name ?? '😊',
          style: const TextStyle(fontSize: 48),
        ),
      );
    }
    return Text(
      m.text,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ChatMarqueeWarningBar(),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              final isEmoticon = m.emoticonId != null;
              final content = isEmoticon
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _bubbleChild(m),
                    )
                  : Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: m.fromMe
                            ? AppColors.accentPurple.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.cardBorder.withValues(alpha: 0.2),
                        ),
                      ),
                      child: _bubbleChild(m),
                    );
              return Align(
                alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                child: GestureDetector(
                  onLongPress: m.fromMe ? () => unawaited(_confirmDeleteOwnMessage(i)) : null,
                  child: content,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
            top: 8,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _openEmoticonPicker,
                tooltip: '이모티콘',
                icon: Icon(Icons.mood, color: AppColors.accentPurple),
              ),
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: const InputDecoration(
                    hintText: '메시지 (기기에 저장)',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: _send,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('보내기'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
