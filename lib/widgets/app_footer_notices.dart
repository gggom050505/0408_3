import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';

/// ID·구글 로그인 공통 하단 안내(보안·광고 문의·신고).
class AppFooterNotices extends StatelessWidget {
  const AppFooterNotices({
    super.key,
    this.includeSecurityReminder = true,
    this.compact = false,
  });

  final bool includeSecurityReminder;

  /// `true`면 GNB 등 좁은 영역용 작은 글자.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.labelSmall;
    final body = Theme.of(context).textTheme.bodySmall;
    final base = compact ? small : body;
    final fs = (base?.fontSize ?? 12) + (compact ? -1 : 0);

    TextStyle line(double alpha, {FontWeight? w}) =>
        (base ?? TextStyle(fontSize: fs)).copyWith(
          color: AppColors.textSecondary.withValues(alpha: alpha),
          height: 1.38,
          fontSize: fs,
          fontWeight: w,
        );

    final gap = compact ? 5.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (includeSecurityReminder) ...[
          Text(
            AppConfig.accountSecurityReminderLine,
            textAlign: TextAlign.center,
            style: line(compact ? 0.82 : 0.92, w: FontWeight.w500),
          ),
          SizedBox(height: gap),
        ],
        Text(
          AppConfig.adInquiryContactLine,
          textAlign: TextAlign.center,
          style: line(compact ? 0.78 : 0.85),
        ),
        SizedBox(height: gap),
        Text(
          AppConfig.communityMisconductReportLine,
          textAlign: TextAlign.center,
          style: line(compact ? 0.8 : 0.9, w: FontWeight.w600),
        ),
      ],
    );
  }
}
