import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_footer_notices.dart';
import 'app_motion.dart';

/// 랜딩: **ID 계정**(기기 로컬) + Supabase 연동 시 **구글 로그인**.
/// 두 방식은 [onOpenGoogleLogin] 이 null 이면 구글 블록을 숨깁니다(오프라인 번들 등).
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onOpenLocalLogin,
    required this.onOpenRegister,
    required this.onOpenWithdraw,
    this.onOpenGoogleLogin,
  });

  final VoidCallback onOpenLocalLogin;
  final VoidCallback onOpenRegister;
  final VoidCallback onOpenWithdraw;

  /// Supabase 초기화 빌드에서만 전달. null 이면 구글 메뉴 미표시.
  final VoidCallback? onOpenGoogleLogin;

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
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
                                color: AppColors.accentPurple.withValues(
                                  alpha: 0.42,
                                ),
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
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StaggerItem(
                      index: 2,
                      child: Text(
                        'ID 계정으로 로그인하고 별조각·상점·진행을 이어가세요.\n'
                        '데이터는 이 기기에 저장됩니다.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    StaggerItem(
                      index: 3,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.cardBorder.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'ID 계정',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                              ),
                              onPressed: onOpenLocalLogin,
                              child: const Text('ID 계정 로그인'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                side: BorderSide(
                                  color: AppColors.accentPurple.withValues(
                                    alpha: 0.65,
                                  ),
                                ),
                              ),
                              onPressed: onOpenRegister,
                              child: const Text('회원 가입'),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: onOpenWithdraw,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade800,
                                minimumSize: const Size.fromHeight(44),
                              ),
                              child: const Text('회원 탈퇴'),
                            ),
                            TextButton(
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('비밀번호 변경'),
                                    content: const SingleChildScrollView(
                                      child: Text(
                                        '1) 먼저 「ID 계정 로그인」으로 들어가세요.\n\n'
                                        '2) 로그인 후 화면 상단 오른쪽의 사람 모양 아이콘을 눌러 '
                                        '「계정 관리」를 여세요.\n\n'
                                        '3) 「보안」란의 「비밀번호 변경」에서 '
                                        '현재 비밀번호·새 비밀번호를 입력하면 됩니다.\n\n'
                                        '비밀번호는 이 기기에만 저장됩니다. 잊어버리면 복구가 어려울 수 있어요.',
                                        style: TextStyle(height: 1.45),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                foregroundColor: AppColors.textPrimary
                                    .withValues(alpha: 0.9),
                              ),
                              child: const Text('비밀번호 변경 안내'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onOpenGoogleLogin != null) ...[
                      const SizedBox(height: 20),
                      StaggerItem(
                        index: 6,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.cardBorder.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '구글 계정',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '구글 로그인은 ID·비밀번호 계정과 별도로 운영됩니다. '
                                '별조각·가방·진행 데이터가 서로 이어지지 않습니다.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '같은 기기에서 두 방식을 함께 쓰면, '
                                '로컬에 쌓이는 데이터가 늘어나 저장 공간을 조금 더 쓸 수 있어요. '
                                '보통은 수~수십 MB 수준이며, 기기 저장 여유가 있다면 부담이 크지 않은 편입니다.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.88,
                                      ),
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  side: BorderSide(
                                    color: AppColors.accentPurple.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                  foregroundColor: AppColors.textPrimary,
                                ),
                                onPressed: onOpenGoogleLogin,
                                icon: const Icon(Icons.login_rounded, size: 22),
                                label: const Text('구글 계정으로 로그인'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    StaggerItem(index: 4, child: const AppFooterNotices()),
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
