import 'package:flutter/material.dart';

import '../standalone/data_sources.dart';
import '../standalone/local_app_preferences.dart';
import '../theme/app_colors.dart';

/// 첫 가입 후 1회 — 기본 카드 뒷면·슬롯, 오라클 7장·이모티콘 8개(무작위) 지급.
class FirstSetupWizardScreen extends StatefulWidget {
  const FirstSetupWizardScreen({
    super.key,
    required this.shopRepo,
    required this.userId,
  });

  final ShopDataSource shopRepo;
  final String userId;

  @override
  State<FirstSetupWizardScreen> createState() => _FirstSetupWizardScreenState();
}

class _FirstSetupWizardScreenState extends State<FirstSetupWizardScreen> {
  var _busy = false;

  Future<void> _complete() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final ok = await widget.shopRepo.completeFirstSetupWizard(widget.userId);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (ok) {
      await LocalAppPreferences.markFirstSetupWizardV1Done(widget.userId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정 적용에 실패했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('첫 설정'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '환영해요!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '아래를 누르면 이렇게 맞춰 드려요.\n\n'
                  '• 카드 뒷면·슬롯 테두리 → 기본 스타일로 장착\n'
                  '• 오라클 카드 7장 → 계정마다 다른 무작위\n'
                  '• 이모티콘 8개 → 무작위\n\n'
                  '언제든 가방·상점에서 바꿀 수 있어요.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _complete,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.accentPurple,
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('시작하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
