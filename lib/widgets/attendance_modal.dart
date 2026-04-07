import 'package:flutter/material.dart';

import '../config/emoticon_offline.dart';
import '../standalone/data_sources.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';

/// 웹 `AttendanceModal`과 동일한 흐름(출석 전/후·결과·이미지).
Future<void> showAttendanceModal(
  BuildContext context, {
  required bool checkedInToday,
  required String userId,
  required AttendanceDataSource repo,
  required Future<void> Function() onCheckedIn,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 360),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
    pageBuilder: (ctx, animation, secondaryAnimation) => _AttendanceDialog(
      checkedInToday: checkedInToday,
      userId: userId,
      repo: repo,
      onCheckedIn: onCheckedIn,
    ),
  );
}

class _AttendanceDialog extends StatefulWidget {
  const _AttendanceDialog({
    required this.checkedInToday,
    required this.userId,
    required this.repo,
    required this.onCheckedIn,
  });

  final bool checkedInToday;
  final String userId;
  final AttendanceDataSource repo;
  final Future<void> Function() onCheckedIn;

  @override
  State<_AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<_AttendanceDialog> {
  Map<String, dynamic>? _result;
  var _loading = false;

  Future<void> _doCheckIn() async {
    setState(() => _loading = true);
    try {
      final res = await widget.repo.doCheckIn(widget.userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _result = res;
        _loading = false;
      });
      if (res != null && res['already'] != true) {
        await widget.onCheckedIn();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출석 처리 중 오류: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final alreadyResult = r != null && r['already'] == true;
    final img = r?['emoticon_image']?.toString();
    final name = r?['emoticon_name']?.toString();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF0E8F8), Color(0xFFE8DDF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8C5AB4).withValues(alpha: 0.25),
              blurRadius: 50,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📅', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              '오늘의 출석',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '매일 첫 출석마다 ⭐ 별조각 1개와, 상점에서 별로 파는 품목 중 '
              '아직 없는 것을 무작위로 1개 더 드려요. (가방·이벤트 탭에서도 안내)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            if (r != null) ...[
              if (alreadyResult) ...[
                const Text('✅', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text(
                  '오늘은 이미 출석했습니다!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ] else if (r['reward_kind'] == 'attendance_star' ||
                  r['reward_kind'] == 'oracle_star') ...[
                const Text('🎉', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text(
                  '출석 완료!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '⭐ 별조각 +1과 출석 선물(무작위 1개)이 있으면 함께 지급됐어요. 하단 스낵바를 확인해 주세요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ] else if (img != null && img.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AdaptiveNetworkOrAssetImage(
                    src: resolveEmoticonImageSrc(remoteImageUrl: img),
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${name ?? '이모티콘'} 획득!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '출석 보상으로 이모티콘을 받았어요!',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ] else ...[
                const Text('🎉', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text(
                  '모든 이모티콘을 수집했습니다!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '출석 완료!',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ] else if (widget.checkedInToday) ...[
              const Text('✅', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                '오늘은 이미 출석했습니다!',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ] else
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB89CD4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: const BorderSide(color: Color(0xFFC9B8E0)),
                  ),
                ),
                onPressed: _loading ? null : _doCheckIn,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('출석하기', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
