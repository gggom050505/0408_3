import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 로그인 랜딩·GNB 등 — 큰 배너 대신 한 줄로 별조각 보유를 표시합니다.
class StarFragmentsBalanceCompact extends StatelessWidget {
  const StarFragmentsBalanceCompact({
    super.key,
    required this.starFragments,
  });

  /// `null`이면 `—`(아직 불러오지 않음·랜딩 등).
  final int? starFragments;

  @override
  Widget build(BuildContext context) {
    return Text(
      '⭐ 별조각 ${starFragments?.toString() ?? '—'}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.92),
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.3,
          ),
    );
  }
}
