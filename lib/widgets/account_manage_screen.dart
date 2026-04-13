import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/local_account_store.dart';
import '../standalone/local_user_data_wipe.dart';
import '../theme/app_colors.dart';
import 'app_footer_notices.dart';

class AccountManageScreen extends StatefulWidget {
  const AccountManageScreen({super.key, required this.session});

  final LocalAccountSession session;

  @override
  State<AccountManageScreen> createState() => _AccountManageScreenState();
}

class _AccountManageScreenState extends State<AccountManageScreen> {
  late TextEditingController _nick;
  var _savingNick = false;
  String? _identityAuditLine;

  static const _ownerLoginKey = 'gggom050501';
  static const _ownerNickname = '동글아저씨';

  bool get _ownerIdMatched =>
      widget.session.loginKey.trim().toLowerCase() == _ownerLoginKey;
  bool get _ownerNicknameMatched => widget.session.displayName.trim() == _ownerNickname;
  bool get _showOwnerAudienceStats => _ownerIdMatched && _ownerNicknameMatched;

  @override
  void initState() {
    super.initState();
    _nick = TextEditingController(text: widget.session.displayName);
    if (_ownerIdMatched) {
      _loadOwnerIdentityAudit();
    }
  }

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    setState(() => _savingNick = true);
    final err = await LocalAccountStore.instance.updateDisplayName(
      loginKey: widget.session.loginKey,
      newDisplayName: _nick.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _savingNick = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('닉네임을 저장했어요.')));
    Navigator.of(context).pop(_nick.text.trim());
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final next2 = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('비밀번호 변경'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(labelText: '현재 비밀번호'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(labelText: '새 비밀번호'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: next2,
                obscureText: true,
                decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('변경'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      current.dispose();
      next.dispose();
      next2.dispose();
      return;
    }
    if (next.text != next2.text) {
      current.dispose();
      next.dispose();
      next2.dispose();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새 비밀번호 확인이 일치하지 않아요.')));
      return;
    }
    if (next.text == current.text) {
      current.dispose();
      next.dispose();
      next2.dispose();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새 비밀번호는 현재 비밀번호와 달라야 해요.')));
      return;
    }
    final err = await LocalAccountStore.instance.updatePassword(
      loginKey: widget.session.loginKey,
      currentPassword: current.text,
      newPassword: next.text,
    );
    current.dispose();
    next.dispose();
    next2.dispose();
    if (!mounted) {
      return;
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호를 변경했어요.')));
    }
  }

  Future<void> _withdrawMembership() async {
    await _runAccountRemoval(
      title: '회원 탈퇴',
      body:
          '회원에서 탈퇴하면 이 기기에 저장된 로그인 정보가 삭제되고, '
          '이 계정의 별조각·가방·타로 진행·채팅 등 기기 데이터도 함께 지워집니다.\n\n'
          '다시 이용하시려면 회원 가입을 새로 하셔야 합니다.',
      confirmLabel: '탈퇴하기',
    );
  }

  Future<void> _deleteAccountAndData() async {
    await _runAccountRemoval(
      title: '계정 삭제',
      body:
          '비밀번호 확인 후 이 계정 자체와 이 기기에 남아 있는 해당 계정 데이터를 '
          '모두 삭제합니다. 되돌릴 수 없습니다.',
      confirmLabel: '삭제하기',
    );
  }

  Future<void> _runAccountRemoval({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final pass = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(body),
              const SizedBox(height: 16),
              TextField(
                controller: pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호 확인'),
                autofocus: true,
              ),
            ],
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
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) {
      pass.dispose();
      return;
    }
    final pwd = pass.text;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    pass.dispose();

    final r = await LocalAccountStore.instance.deleteAccountWithRemovedUserId(
      loginKey: widget.session.loginKey,
      password: pwd,
    );
    if (!mounted) {
      return;
    }
    if (r.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(r.error!)));
      return;
    }

    final uid = r.removedUserId ?? widget.session.userId;
    final nav = Navigator.of(context, rootNavigator: true);
    try {
      await wipeStandaloneArtifactsForAppUserId(uid);
    } catch (_) {
      // 계정 삭제는 이미 완료됨. 기기 정리만 일부 실패한 경우에도 화면은 닫습니다.
    }
    nav.pop(const AccountDeletedResult());
  }

  Future<void> _loadOwnerIdentityAudit() async {
    final sameNick = await LocalAccountStore.instance.listAccountsByDisplayName(
      _ownerNickname,
    );
    if (!mounted) return;
    if (!_ownerNicknameMatched) {
      setState(() {
        _identityAuditLine = 'ID는 일치하지만 닉네임이 "$_ownerNickname" 과 다릅니다.';
      });
      return;
    }
    if (sameNick.isEmpty) {
      setState(() {
        _identityAuditLine = '동일 닉네임 계정을 찾지 못했어요.';
      });
      return;
    }
    final mine = sameNick.where((e) => e.loginKey == _ownerLoginKey).toList();
    if (mine.isEmpty) {
      setState(() {
        _identityAuditLine = '닉네임은 같지만 ID가 다른 계정만 있어요.';
      });
      return;
    }
    final isEarliest = sameNick.first.loginKey == _ownerLoginKey;
    final dupCount = sameNick.length - 1;
    final base = isEarliest ? '본인 계정을 선가입 계정으로 확인했어요.' : '동일 닉네임의 선가입 계정이 따로 있어요.';
    final dupNote = dupCount > 0 ? ' (동일 닉네임 추가 $dupCount개)' : ' (동일 닉네임 추가 없음)';
    setState(() {
      _identityAuditLine = '$base$dupNote';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 관리'),
        backgroundColor: AppColors.bgMain,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('아이디'),
            subtitle: Text(widget.session.loginKey),
          ),
          if (_ownerIdMatched) ...[
            const SizedBox(height: 8),
            Text(
              _identityAuditLine ?? '계정 확인 중…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _showOwnerAudienceStats
                    ? AppColors.textSecondary
                    : Colors.red.shade700,
                height: 1.35,
              ),
            ),
          ],
          if (_showOwnerAudienceStats) ...[
            const Divider(height: 32),
            Text(
              '운영 통계',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이 앱은 서버에 가입자 수를 올리지 않아요. '
                      '운영 통계는 별도 도구가 필요합니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Divider(height: 32),
          Text(
            '프로필',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nick,
            decoration: const InputDecoration(
              labelText: '닉네임',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _savingNick ? null : _saveNickname,
            child: _savingNick
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('닉네임 저장'),
          ),
          const SizedBox(height: 28),
          Text(
            '보안',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '비밀번호는 이 기기에만 저장돼요. 다른 기기와 맞지 않습니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x337C3AED),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF6B21A8),
                ),
              ),
              title: const Text('비밀번호 변경'),
              subtitle: const Text('현재 비밀번호 확인 후 새 비밀번호로 바꿔요.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _changePassword,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            '회원 · 계정',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '탈퇴와 계정 삭제 모두 이 기기에서 로그인 정보와 진행 데이터를 지웁니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _withdrawMembership,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade800,
            ),
            child: const Text('회원 탈퇴'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _deleteAccountAndData,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade800,
            ),
            child: const Text('계정 삭제'),
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
            AppConfig.localIdAccountInfoLine,
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

/// [AccountManageScreen]에서 계정 탈퇴 후 pop 될 때 반환됩니다.
class AccountDeletedResult {
  const AccountDeletedResult();
}
