import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import 'app_motion.dart';
import 'star_fragments_balance_panel.dart';

/// 랜딩: Google 로그인 + 게스트 둘러보기.
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onContinueAsGuest,
    required this.onOpenGoogleLogin,
  });

  /// 별도 계정 없이 `local-guest` 홈으로 — 웹·첫 방문 둘러보기용.
  final VoidCallback onContinueAsGuest;
  final VoidCallback onOpenGoogleLogin;

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
                      child: Column(
                        children: [
                          Text(
                            '오늘의 타로 운세',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '타로 · 오라클 · 수집 · 개인 상점 — 한 판의 리듬을 모아 보세요.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.accentPurple,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 12),
                          if (AppConfig.googleLoginEnabled) ...[
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(220, 48),
                                backgroundColor: AppColors.accentLilac
                                    .withValues(alpha: 0.72),
                                foregroundColor: AppColors.textPrimary,
                              ),
                              onPressed: onOpenGoogleLogin,
                              child: const Text('구글로 로그인'),
                            ),
                          ] else ...[
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(220, 48),
                              ),
                              onPressed: null,
                              child: const Text('구글 설정 필요'),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: onContinueAsGuest,
                            child: const Text(
                              '로그인 없이 둘러보기',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    StaggerItem(
                      index: 2,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accentPurple.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '이 앱에서 만나 보세요',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _LoginHighlightLine(
                              icon: '🌅',
                              text:
                                  '오늘의 타로 — 매일 바뀌는 키워드, 106장 덱에서 직감으로 10장. '
                                  '점수가 쌓이는 데일리 한 판이 기다려요.',
                            ),
                            _LoginHighlightLine(
                              icon: '🃏',
                              text:
                                  '스프레드·캡처·피드 — 매트와 덱을 바꿔 꾸미고, 한 판을 그림처럼 남겨 '
                                  '기록과 해석을 이어 갈 수 있어요.',
                            ),
                            _LoginHighlightLine(
                              icon: '⭐',
                              text:
                                  '별조각·출석 — 모으고 열리는 상점, '
                                  '게임처럼 박자 맞춰 컬렉션을 채워 보세요.',
                            ),
                            _LoginHighlightLine(
                              icon: '🏪',
                              text:
                                  '개인 상점 — 희귀 카드와 이모티콘을 거래·탐색하는 '
                                  '또 다른 재미가 있어요.',
                            ),
                            _LoginHighlightLine(
                              icon: '💬',
                              text:
                                  '채팅·이모티콘 — 타로만이 아니라 대화와 꾸미기까지, '
                                  '콘텐츠를 가볍게 즐길 수 있어요.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StaggerItem(
                      index: 3,
                      child: Text(
                        '위에서 로그인하면 별조각·가방·상점 이용 기록을 안전하게 이어 갈 수 있어요.\n'
                        '브라우저나 기기를 바꿔도 같은 계정으로 복구하기 쉬워요.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    StaggerItem(
                      index: 4,
                      child: const StarFragmentsBalanceCompact(
                        starFragments: null,
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

class _LoginHighlightLine extends StatelessWidget {
  const _LoginHighlightLine({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18, height: 1.35)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.92),
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
