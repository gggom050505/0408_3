import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/emoticon_offline.dart';
import '../standalone/data_sources.dart';
import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';

/// 와이드 화면·웹에서 출석 달력이 가로로 과도하게 커지지 않게 합니다.
const double _kAttendanceDialogMaxWidth = 400;

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
  late DateTime _month;
  Set<int> _checkedDays = <int>{};
  late int _year;
  final Map<int, Set<int>> _checkedDaysByMonth = <int, Set<int>>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = DateTime(now.year, now.month, 1);
    _loadYearAttendance();
  }

  Future<void> _loadYearAttendance() async {
    try {
      final loaded = <int, Set<int>>{};
      for (var m = 1; m <= 12; m++) {
        final days = await widget.repo.fetchCheckedInDaysOfMonth(
          widget.userId,
          year: _year,
          month: m,
        );
        loaded[m] = days;
      }
      if (!mounted) return;
      setState(() {
        _checkedDaysByMonth
          ..clear()
          ..addAll(loaded);
        _checkedDays = _checkedDaysByMonth[_month.month] ?? <int>{};
      });
    } catch (_) {}
  }

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
        final now = DateTime.now();
        if (now.year == _month.year && now.month == _month.month) {
          _checkedDays = {..._checkedDays, now.day};
        }
        if (now.year == _year) {
          final prev = _checkedDaysByMonth[now.month] ?? <int>{};
          _checkedDaysByMonth[now.month] = {...prev, now.day};
        }
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
      child: LayoutBuilder(
        builder: (context, c) {
          final maxW = math.min(
            c.maxWidth,
            _kAttendanceDialogMaxWidth,
          );
          return Align(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0E8F8), Color(0xFFE8DDF2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 2,
                  ),
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
                    _buildCalendarCard(context),
                    const SizedBox(height: 8),
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ] else if (r['reward_kind'] == 'attendance_star' ||
                          r['reward_kind'] == 'oracle_star') ...[
                        const Text('🎉', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text(
                          '출석 완료!',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '⭐ 별조각 +1과 출석 선물(무작위 1개)이 있으면 함께 지급됐어요. 하단 스낵바를 확인해 주세요.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '출석 보상으로 이모티콘을 받았어요!',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ] else ...[
                        const Text('🎉', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text(
                          '모든 이모티콘을 수집했습니다!',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '출석 완료!',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ] else if (widget.checkedInToday) ...[
                      const Text('✅', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text(
                        '오늘은 이미 출석했습니다!',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ] else
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB89CD4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '출석하기',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '닫기',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday; // 1=Mon..7=Sun
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <Widget>[];
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    for (final w in weekdays) {
      cells.add(
        Center(
          child: Text(
            w,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      );
    }
    final leadingBlanks = firstWeekday - 1;
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    final today = DateTime.now();
    for (var day = 1; day <= daysInMonth; day++) {
      final checked = _checkedDays.contains(day);
      final isToday =
          today.year == _month.year && today.month == _month.month && today.day == day;
      cells.add(
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: checked ? const Color(0xFFB89CD4).withValues(alpha: 0.24) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isToday ? const Color(0xFF7C5BB8) : const Color(0x20000000),
              width: isToday ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (checked)
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 2, bottom: 1),
                    child: Icon(Icons.check_circle, size: 11, color: Color(0xFF7C5BB8)),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_month.year}년 ${_month.month}월 출석 달력',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildYearMonthPreviewRow(context),
          const SizedBox(height: 6),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1.18,
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _buildYearMonthPreviewRow(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final month = i + 1;
          final selected = _month.month == month;
          final checkedCount = (_checkedDaysByMonth[month] ?? const <int>{}).length;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              setState(() {
                _month = DateTime(_year, month, 1);
                _checkedDays = _checkedDaysByMonth[month] ?? <int>{};
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFB89CD4).withValues(alpha: 0.24) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? const Color(0xFF7C5BB8) : const Color(0x20000000),
                ),
              ),
              child: Text(
                '$month월 ($checkedCount)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
