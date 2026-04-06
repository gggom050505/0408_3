import 'package:flutter/material.dart';

import '../config/emoticon_offline.dart';
import '../models/emoticon_models.dart';
import '../standalone/data_sources.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';

/// 채팅 하단용 — 보유 이모티콘만 표시 (`EmoticonPicker`와 동일 규칙).
class EmoticonPickerSheet extends StatefulWidget {
  const EmoticonPickerSheet({
    super.key,
    required this.repo,
    required this.userId,
    required this.onPick,
  });

  final EmoticonDataSource repo;
  final String userId;
  final ValueChanged<String> onPick;

  @override
  State<EmoticonPickerSheet> createState() => _EmoticonPickerSheetState();
}

class _EmoticonPickerSheetState extends State<EmoticonPickerSheet> {
  List<EmoticonRow> _all = [];
  List<String> _owned = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final a = await widget.repo.fetchAllEmoticons();
      final o = await widget.repo.fetchOwned(widget.userId);
      if (mounted) {
        setState(() {
          _all = dedupeEmoticonsForPicker(a);
          _owned = o;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownedEmo = _all.where((e) => _owned.contains(e.id)).toList();
    return Material(
      color: Colors.white.withValues(alpha: 0.97),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '이모티콘',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (ownedEmo.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '보유한 이모티콘이 없습니다.\n상점에서 구매해 보세요!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: ownedEmo.length,
                  itemBuilder: (context, i) {
                    final e = ownedEmo[i];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onPick(e.id);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, c) {
                                if (e.imageUrl.trim().isEmpty) {
                                  return Center(
                                    child: Text(
                                      e.name,
                                      style: const TextStyle(fontSize: 32),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                final src = resolveEmoticonImageSrc(
                                  remoteImageUrl: e.imageUrl,
                                  emoticonId: e.id,
                                );
                                return AdaptiveNetworkOrAssetImage(
                                  src: src,
                                  fit: BoxFit.contain,
                                  width: c.maxWidth,
                                  height: c.maxHeight,
                                  errorBuilder: (_, _, _) => Center(
                                    child: Text(
                                      e.name.isNotEmpty ? e.name : '😊',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (e.imageUrl.trim().isNotEmpty)
                            Text(
                              e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
