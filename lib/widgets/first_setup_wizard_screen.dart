import 'package:flutter/material.dart';

import '../config/starter_gifts.dart'
    show
        kFirstSetupEmoticonGiftCount,
        kFirstSetupOracleGiftCount,
        kStarterWelcomeStarFragments;
import '../standalone/data_sources.dart';
import '../standalone/local_app_preferences.dart';
import '../theme/app_colors.dart';

/// 첫 가입 후 1회 — 확인 시 ⭐·이모·오라클을 가방·채팅에 반영, 기본 뒷면·슬롯 장착.
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
  var _step = 0;

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
                if (_step == 0) ...[
                  Text(
                    '서비스로 아래를 드려요.\n\n'
                    '• ⭐ 별조각 $kStarterWelcomeStarFragments개\n'
                    '• 이모티콘 $kFirstSetupEmoticonGiftCount개 (무작위)\n'
                    '• 오라클 카드 $kFirstSetupOracleGiftCount장 (무작위)\n\n'
                    '다음 화면에서 「확인」을 누르면 가방과 채팅 이모에 반영돼요.\n'
                    '카드 뒷면·슬롯은 기본 스타일로 맞춥니다.\n\n'
                    '한국전통 메이저 조각 1장·무료 덱 등은 이미 가방에 들어 있을 수 있어요.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ] else ...[
                  Text(
                    '지급 내용을 확인했어요.\n\n'
                    '「확인하고 가방에 받기」를 누르면 ⭐·이모·오라클이 저장되고 '
                    '가방 탭에서 바로 볼 수 있어요.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
                const Spacer(),
                if (_step == 0)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _step = 1),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.accentPurple,
                    ),
                    child: const Text('다음'),
                  )
                else ...[
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
                        : const Text('확인하고 가방에 받기'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _busy ? null : () => setState(() => _step = 0),
                    child: const Text('이전'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
