import 'package:flutter/material.dart';

import '../services/local_account_store.dart';
import '../theme/app_colors.dart';

class AccountManageScreen extends StatefulWidget {
  const AccountManageScreen({
    super.key,
    required this.session,
  });

  final LocalAccountSession session;

  @override
  State<AccountManageScreen> createState() => _AccountManageScreenState();
}

class _AccountManageScreenState extends State<AccountManageScreen> {
  late TextEditingController _nick;
  var _savingNick = false;

  @override
  void initState() {
    super.initState();
    _nick = TextEditingController(text: widget.session.displayName);
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('닉네임을 저장했어요.')),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새 비밀번호 확인이 일치하지 않아요.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 변경했어요.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final pass = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('계정 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '이 기기에 저장된 로그인 정보와 계정이 삭제됩니다. 상점·가방 데이터 파일은 그대로 남을 수 있어요.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호 확인'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) {
      pass.dispose();
      return;
    }
    final err = await LocalAccountStore.instance.deleteAccount(
      loginKey: widget.session.loginKey,
      password: pass.text,
    );
    pass.dispose();
    if (!mounted) {
      return;
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await LocalAccountStore.instance.clearSession();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(const AccountDeletedResult());
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
          const Divider(),
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
          OutlinedButton(
            onPressed: _changePassword,
            child: const Text('비밀번호 변경'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _deleteAccount,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade800),
            child: const Text('계정 삭제'),
          ),
        ],
      ),
    );
  }
}

/// [AccountManageScreen]에서 계정 삭제 후 pop 될 때 반환됩니다.
class AccountDeletedResult {
  const AccountDeletedResult();
}
