import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'adaptive_network_asset_image.dart';
import 'star_fragments_balance_panel.dart';

enum MainTab {
  tarot,
  todayTarot,
  todayTarotFeed,
  ganjiCalendar,
  feed,
  chat,
  shop,
  bag,
  event,
}

class Gnb extends StatelessWidget {
  const Gnb({
    super.key,
    required this.active,
    required this.onTab,
    required this.displayName,
    this.avatarUrl,
    required this.onSignOut,
    this.checkedInToday,
    required this.onAttendance,

    /// 별조각 광고(영상 시청) — null이면 GNB 에서 숨김
    this.onAdReward,
    this.onSaveForCoding,

    /// 자체(로컬) 계정 등 — null이면 숨김
    this.onAccountSettings,

    /// 메이킹 노트(번들 문서) — null이면 숨김
    this.onMakingNotes,

    /// Supabase 일일 방문자 집계 라벨(예: `오늘 접속 12명`) — null이면 숨김
    this.visitorCountLabel,

    /// GNB 하단 한 줄 별조각 보유 — null이면 `—` 표시
    this.starFragmentBalance,
  });

  final MainTab active;
  final ValueChanged<MainTab> onTab;
  final String displayName;

  final String? avatarUrl;
  final VoidCallback onSignOut;

  /// null이면 뱃지 숨김
  final bool? checkedInToday;
  final VoidCallback onAttendance;
  final VoidCallback? onAdReward;

  /// 로컬 JSON → 프로젝트 `assets/local_dev_state/` (null이면 숨김)
  final VoidCallback? onSaveForCoding;
  final VoidCallback? onAccountSettings;
  final VoidCallback? onMakingNotes;

  final String? visitorCountLabel;

  final int? starFragmentBalance;

  /// 타로–게시물, 오늘의 타로–오늘의 게시 를 나란히 둡니다.
  static const _tabs = <(MainTab, String, String)>[
    (MainTab.tarot, '타로', '🃏'),
    (MainTab.ganjiCalendar, '간지\n달력', '🗓️'),
    (MainTab.feed, '게시물', '📝'),
    (MainTab.todayTarot, '오늘의\n타로', '🌅'),
    (MainTab.todayTarotFeed, '오늘의\n게시', '📿'),
    (MainTab.chat, '채팅', '💬'),
    (MainTab.shop, '상점', '🏪'),
    (MainTab.bag, '가방', '🎒'),
    (MainTab.event, '이벤트', '🎁'),
  ];

  /// 참조 UI: `July 17` 형태(영문 월 + 일).
  static String _attendanceDateLabel() {
    final d = DateTime.now();
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          '$displayName님',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (avatarUrl != null) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 14,
                            backgroundImage:
                                looksLikeNetworkImageUrl(avatarUrl!)
                                ? NetworkImage(avatarUrl!)
                                : AssetImage(avatarUrl!),
                          ),
                        ],
                        if (visitorCountLabel != null) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message:
                                '한국 날짜 기준으로, 오늘 이 사이트에 들어온 기기·브라우저 수예요.',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bgCard.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.cardBorder.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                              ),
                              child: Text(
                                visitorCountLabel!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ),
                        ],
                        if (onAccountSettings != null) ...[
                          const SizedBox(width: 2),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: '계정 관리',
                            onPressed: onAccountSettings,
                            icon: Icon(
                              Icons.manage_accounts_outlined,
                              size: 22,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        if (onAdReward != null) ...[
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: onAdReward,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFFFE8CC),
                              foregroundColor: Color(0xFFB45309),
                              padding: const EdgeInsets.all(8),
                            ),
                            icon: const Icon(
                              Icons.smart_display_outlined,
                              size: 20,
                            ),
                            tooltip: '별조각 광고 (시청 완료 시 3개)',
                          ),
                          const SizedBox(width: 2),
                        ],
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Material(
                              color: checkedInToday == true
                                  ? AppColors.accentMint.withValues(alpha: 0.35)
                                  : AppColors.accentPurple,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: onAttendance,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '📅',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      Text(
                                        _attendanceDateLabel(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: checkedInToday == true
                                                  ? AppColors.textSecondary
                                                  : AppColors.textLight,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (checkedInToday == false)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (onSaveForCoding != null) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: onSaveForCoding,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0x33A7F3D0),
                            ),
                            icon: const Icon(Icons.save_outlined, size: 20),
                            tooltip: '저장하기 — 로컬 기록을 프로젝트 JSON 으로',
                          ),
                        ],
                        if (onMakingNotes != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: onMakingNotes,
                            tooltip: '메이킹 노트',
                            icon: Icon(
                              Icons.menu_book_outlined,
                              size: 22,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSignOut,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    '로그아웃',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.gnbRailGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _tabs.map((t) {
                        final sel = active == t.$1;
                        return GestureDetector(
                          onTap: () => onTab(t.$1),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedScale(
                            scale: sel ? 1.05 : 1,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutBack,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                gradient: sel ? AppColors.gnbTabSelectedGradient : null,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: AppColors.accentLilac.withValues(alpha: 0.45),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                      color: sel ? AppColors.textPrimary : AppColors.textLight,
                                      fontWeight: FontWeight.bold,
                                      shadows: sel
                                          ? null
                                          : const [
                                              Shadow(color: Color(0x66000000), offset: Offset(0, 1)),
                                            ],
                                    ),
                                child: Text(
                                  t.$2,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.accentPurple.withValues(alpha: 0),
                            AppColors.accentPurple.withValues(alpha: 0.48),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            '...',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: AppColors.textLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
            child: StarFragmentsBalanceCompact(
              starFragments: starFragmentBalance,
            ),
          ),
        ],
      ),
    );
  }
}
