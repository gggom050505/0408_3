import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/feed_tags.dart';
import '../standalone/data_sources.dart';
import '../theme/app_colors.dart';

class PostCaptureSheet extends StatefulWidget {
  const PostCaptureSheet({
    super.key,
    required this.pngBytes,
    required this.feed,
    required this.userId,
    required this.username,
    required this.avatar,
    required this.onPosted,
    this.initialContent,
  });

  final Uint8List pngBytes;
  final FeedDataSource feed;
  final String? userId;
  final String username;
  final String avatar;
  final VoidCallback onPosted;
  /// 비어 있을 때만 보이는 안내 문구(입력 시작 시 자동으로 사라짐)
  final String? initialContent;

  @override
  State<PostCaptureSheet> createState() => _PostCaptureSheetState();
}

class _PostCaptureSheetState extends State<PostCaptureSheet> {
  final _content = TextEditingController();
  final Set<String> _selectedTagKeys = {};
  var _busy = false;
  String? _submitError;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    final text = _content.text.trim();
    if (text.isEmpty) {
      setState(() => _submitError = '내용을 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _submitError = null;
    });
    try {
      final tagList = <String>{
        ..._selectedTagKeys,
        kFeedTagTarotSpreadMatchKey,
      }.toList()
        ..sort();
      final post = await widget.feed.addPost(
        userId: widget.userId,
        username: widget.username,
        avatar: widget.avatar,
        content: text,
        tags: tagList,
        imagePngBytes: widget.pngBytes.toList(),
      );
      if (!mounted) {
        return;
      }
      if (post != null) {
        Navigator.pop(context, post);
        widget.onPosted();
      } else {
        setState(() => _submitError = '게시에 실패했어요. 잠시 후 다시 시도해 주세요.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitError = '업로드 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 모달 시트 안에서는 Scaffold를 쓰지 않음(웹 등에서 부모·자식 높이 제약이 꼬여 시트가 비어 보일 수 있음).
    return Material(
      color: AppColors.bgMain,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_submitError != null) ...[
                Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _submitError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '📸 타로 결과 게시',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _content,
                decoration: InputDecoration(
                  labelText: '내용',
                  hintText: widget.initialContent?.trim().isNotEmpty == true
                      ? widget.initialContent
                      : '타로 결과에 대한 설명을 적어 주세요',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.75),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.cardBorder.withValues(alpha: 0.2),
                    ),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '태그',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '「타로 탭 캡처」는 #타로스프레드가 자동으로 붙어요. '
                '#오늘의타로는 오늘의 타로 전용이라 여기서는 고를 수 없어요. '
                '아래는 부가 태그만 골라 주세요.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final chip in kFeedPostSelectableTags)
                    if (chip.matchKey != kFeedTagTodayTarotMatchKey &&
                        chip.matchKey != kFeedTagTarotSpreadMatchKey)
                    FilterChip(
                      label: Text(chip.label),
                      selected: _selectedTagKeys.contains(chip.matchKey),
                      onSelected: (v) {
                        final key = chip.matchKey!;
                        setState(() {
                          if (v) {
                            _selectedTagKeys.add(key);
                          } else {
                            _selectedTagKeys.remove(key);
                          }
                        });
                      },
                      selectedColor:
                          AppColors.accentPurple.withValues(alpha: 0.35),
                      checkmarkColor: AppColors.accentPurple,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: _selectedTagKeys.contains(chip.matchKey)
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: _selectedTagKeys.contains(chip.matchKey)
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: AppColors.cardBorder.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide(
                          color: AppColors.textSecondary.withValues(alpha: 0.35),
                        ),
                        foregroundColor: AppColors.textPrimary,
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                      ),
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        foregroundColor: AppColors.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('피드에 게시'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
