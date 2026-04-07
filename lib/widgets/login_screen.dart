import 'package:flutter/material.dart';

import '../config/shop_admin_gate.dart';
import '../theme/app_colors.dart';
import 'app_motion.dart';

/// 랜딩 로그인: **일반**은 [onOpenLocalLogin] 아이디·비밀번호만, **운영자**는 [onAdminGoogleLogin].
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.supabaseConfigured,
    this.onAdminGoogleLogin,
    required this.onOpenLocalLogin,
  });

  final bool supabaseConfigured;
  /// 지정 구글 계정([kShopAdminGoogleEmail])만 세션 유지. Supabase 미사용 빌드에서는 null.
  final VoidCallback? onAdminGoogleLogin;
  /// 이 기기 전용 아이디·비밀번호 로그인 화면
  final VoidCallback onOpenLocalLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.scaffoldGradient),
        child: Stack(
          children: [
            Positioned(
              top: 40,
              left: 24,
              child: ExcludeSemantics(
                child: Text(
                  '✨',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: 24,
              child: ExcludeSemantics(
                child: Text(
                  '🌙',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StaggerItem(
                      index: 0,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.elasticOut,
                        builder: (context, t, child) => Transform.scale(
                          scale: 0.75 + 0.25 * t,
                          child: child,
                        ),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.loginOrbGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentPurple.withValues(alpha: 0.42),
                                blurRadius: 20,
                                spreadRadius: 1,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: ExcludeSemantics(
                              child: Text('🔮', style: TextStyle(fontSize: 48)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    StaggerItem(
                      index: 1,
                      child: Text(
                        '오늘의 타로 운세',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StaggerItem(
                      index: 2,
                      child: Text(
                        '아이디로 로그인해 별조각·상점·진행 저장을 이어가세요.\n'
                        '데이터는 이 앱이 설치된 기기에 저장됩니다.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    StaggerItem(
                      index: 3,
                      child: Tooltip(
                        message: '이 기기 전용 아이디·비밀번호로 로그인합니다. '
                            '첫 사용이면 로그인 화면에서 가입할 수 있어요',
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          onPressed: onOpenLocalLogin,
                          child: const Text('아이디로 로그인'),
                        ),
                      ),
                    ),
                    if (onAdminGoogleLogin != null) ...[
                      const SizedBox(height: 16),
                      StaggerItem(
                        index: 4,
                        child: _AdminGoogleLoginPanel(
                          supabaseConfigured: supabaseConfigured,
                          onAdminGoogleLogin: onAdminGoogleLogin!,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    StaggerItem(
                      index: 5,
                      child: Text(
                        '계정 보안은 본인이 지키세요. 해킹으로부터 보호해 드리지 못합니다.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.92),
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 운영자 전용: [kShopAdminGoogleEmail] 구글 로그인만 세션을 유지합니다 (실패 시 [AppRoot]에서 로그아웃).
class _AdminGoogleLoginPanel extends StatelessWidget {
  const _AdminGoogleLoginPanel({
    required this.supabaseConfigured,
    required this.onAdminGoogleLogin,
  });

  final bool supabaseConfigured;
  final VoidCallback onAdminGoogleLogin;

  void _onPressed(BuildContext context) {
    if (!supabaseConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '관리자 로그인은 Supabase·구글 연동이 켜진 빌드에서만 사용할 수 있어요.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    onAdminGoogleLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentPurple.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.accentPurple.withValues(alpha: 0.95),
                  size: 32,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '사이트 관리자',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '구글 계정 $kShopAdminGoogleEmail 만 입장합니다. '
                      '다른 계정이면 로그인 후 바로 해제돼요.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Tooltip(
              message:
                  '관리자 전용 구글 로그인. $kShopAdminGoogleEmail 이 아니면 거부됩니다',
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(
                    color: AppColors.accentPurple.withValues(alpha: 0.65),
                  ),
                ),
                onPressed: () => _onPressed(context),
                icon: const Icon(Icons.login, size: 20),
                label: const Text('관리자로 구글 로그인'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
