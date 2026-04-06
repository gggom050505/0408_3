import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 가방·상점 등에서 같은 별조각 보유 수를 동일한 스타일로 표시합니다.
class StarFragmentsBalancePanel extends StatelessWidget {
  const StarFragmentsBalancePanel({
    super.key,
    required this.starFragments,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final int? starFragments;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentLilac.withValues(alpha: 0.32),
              AppColors.accentPurple.withValues(alpha: 0.22),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.accentPurple.withValues(alpha: 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentViolet.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 22)),
            Text(
              starFragments?.toString() ?? '—',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '별조각 보유',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
