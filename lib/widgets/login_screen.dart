import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_motion.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.supabaseConfigured,
    required this.onGoogleLogin,
    this.onContinueAsGuest,
    this.onOpenLocalLogin,
    this.onOpenRegister,
  });

  final bool supabaseConfigured;
  final VoidCallback onGoogleLogin;
  /// 게스트로 홈 진입 (Supabase 유무와 관계없이 제공 가능).
  final VoidCallback? onContinueAsGuest;
  /// 자체 계정 — 아이디·비밀번호 로그인 화면으로 이동
  final VoidCallback? onOpenLocalLogin;
  final VoidCallback? onOpenRegister;

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
            child: Text('✨',
                style: TextStyle(
                    fontSize: 40, color: Colors.white.withValues(alpha: 0.2))),
          ),
          Positioned(
            bottom: 100,
            right: 24,
            child: Text('🌙',
                style: TextStyle(
                    fontSize: 40, color: Colors.white.withValues(alpha: 0.2))),
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
                          child: Text('🔮', style: TextStyle(fontSize: 48)),
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
                      '나만의 타로 결과를 캡처하고\n다른 친구들과 함께 이야기를 나눠보세요!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StaggerItem(
                    index: 3,
                    child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.cardBorder.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '가볍게만 쓰기 · 라이트 이용',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '회원가입·로그인 없이도 타로 화면 둘러보기 등을 시작할 수 있어요.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '⭐ 별조각·상점·출석·게시물 등',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '별조각으로 살 것을 모으거나, 온라인에 기록을 남기려면 아래에서 '
                          '구글 로그인 또는 계정 만들기(이 기기 전용)로 가입·로그인해 주세요.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (onContinueAsGuest != null) ...[
                    StaggerItem(
                      index: 4,
                      child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(
                            color: AppColors.accentPurple.withValues(alpha: 0.65),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: onContinueAsGuest,
                        child: const Text('회원가입 없이 둘러보기'),
                      ),
                    ),
                    ),
                    const SizedBox(height: 20),
                    StaggerItem(
                      index: 5,
                      child: Text(
                      '별조각·연동 기능',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                    ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  StaggerItem(
                    index: 6,
                    child: _GoogleLoginMenu(
                      supabaseConfigured: supabaseConfigured,
                      onGoogleLogin: onGoogleLogin,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (onOpenRegister != null)
                    StaggerItem(
                      index: 7,
                      child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onOpenRegister,
                        child: const Text('계정 만들기 (이 기기 전용)'),
                      ),
                    ),
                    ),
                  if (onOpenLocalLogin != null) ...[
                    const SizedBox(height: 12),
                    StaggerItem(
                      index: 8,
                      child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onOpenLocalLogin,
                        child: const Text('아이디로 로그인'),
                      ),
                    ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  StaggerItem(
                    index: 9,
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

/// 로그인 화면에서 구글 OAuth 진입을 메뉴 형태로 구분해 표시합니다.
/// Supabase 미설정 빌드에서도 항상 보이며, 누르면 설정 안내를 띄웁니다.
class _GoogleLoginMenu extends StatelessWidget {
  const _GoogleLoginMenu({
    required this.supabaseConfigured,
    required this.onGoogleLogin,
  });

  final bool supabaseConfigured;
  final VoidCallback onGoogleLogin;

  void _onPressed(BuildContext context) {
    if (!supabaseConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '이 빌드는 Supabase 연동이 꺼져 있어요 (예: GGGOM_OFFLINE_BUNDLE). '
            'www.gggom0505.kr 연동 빌드는 해당 플래그 없이 실행하거나, '
            '스테이징이면 SUPABASE_URL·SUPABASE_ANON_KEY 를 dart-define 으로 넣어 주세요.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }
    onGoogleLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.22),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '구글 계정으로 로그인',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      supabaseConfigured
                          ? '별조각·상점·게시물 등 온라인 기능'
                          : '오프라인 번들이거나 Supabase 초기화가 꺼진 빌드예요.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.25,
                          ),
                    ),
                    if (!supabaseConfigured) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Supabase 켜기: GGGOM_OFFLINE_BUNDLE 없이 빌드 · 스테이징은 SUPABASE_* dart-define',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.85),
                              fontSize: 11,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.95),
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: AppColors.cardBorder.withValues(alpha: 0.15),
                  ),
                ),
              ),
              onPressed: () => _onPressed(context),
              child: const Text('구글 계정으로 로그인'),
            ),
          ),
        ],
      ),
    );
  }
}
