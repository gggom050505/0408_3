import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import 'app_motion.dart';

/// 랜딩: **ID 계정** 로그인·회원 가입·회원 탈퇴만 제공합니다.
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onOpenLocalLogin,
    required this.onOpenRegister,
    required this.onOpenWithdraw,
  });

  final VoidCallback onOpenLocalLogin;
  final VoidCallback onOpenRegister;
  final VoidCallback onOpenWithdraw;

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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    StaggerItem(
                      index: 4,
                      child: Text(
                        '계정 보안은 본인이 지키세요. 해킹으로부터 보호해 드리지 못합니다.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.92,
                          ),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    StaggerItem(
                      index: 5,
                      child: Text(
                        AppConfig.adInquiryContactLine,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.85,
                          ),
                          height: 1.35,
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
