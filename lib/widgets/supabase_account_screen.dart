import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../services/supabase_account_withdrawal.dart';
import '../theme/app_colors.dart';
import 'app_footer_notices.dart';

/// 구글·Supabase 로그인 사용자용 — 계정 탈퇴(데이터 삭제 후 로그아웃).
class SupabaseAccountScreen extends StatefulWidget {
  const SupabaseAccountScreen({super.key});

  @override
  State<SupabaseAccountScreen> createState() => _SupabaseAccountScreenState();
}

class _SupabaseAccountScreenState extends State<SupabaseAccountScreen> {
  var _busy = false;

  Future<void> _confirmWithdraw() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴 · 계정 삭제'),
        content: SingleChildScrollView(
          child: Text(
            '프로필·가방·출석·채팅·게시물 등 이 앱에 연결된 서버 데이터를 삭제한 뒤 '
            '로그아웃합니다(서버에 저장된 계정 이용 데이터 삭제).\n\n'
            '구글 로그인 자체는 구글 계정 설정에서 연결을 끊을 수 있어요. '
            '인증 계정까지 서버에서 완전히 없애는 절차는 운영 정책에 따라 별도일 수 있어요.',
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('탈퇴 진행'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    final err = await SupabaseAccountWithdrawal.withdrawAndSignOut(
      Supabase.instance.client,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('탈퇴 처리했어요. 로그인 화면으로 돌아갑니다.')));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email;
    final metaName = user?.userMetadata;
    final name = metaName == null
        ? null
        : (metaName['full_name'] ?? metaName['name']) as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 · 회원 탈퇴'),
        backgroundColor: AppColors.bgMain,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('로그인'),
            subtitle: Text(
              name != null && name.isNotEmpty ? name : (email ?? '연동 계정'),
            ),
          ),
          if (email != null && email.isNotEmpty) ...[
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('이메일'),
              subtitle: Text(email),
            ),
          ],
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            '회원 탈퇴 / 계정 삭제',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '서버에 저장된 회원 데이터를 삭제한 뒤 로그아웃합니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _confirmWithdraw,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.person_off_outlined, color: Colors.red.shade800),
            label: Text(
              _busy ? '처리 중…' : '탈퇴 · 데이터 삭제',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade800,
              side: BorderSide(
                color: Colors.red.shade700.withValues(alpha: 0.65),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(height: 32),
          Text(
            '안내',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppConfig.oauthAccountSeparateFromLocalIdLine,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const AppFooterNotices(),
        ],
      ),
    );
  }
}
