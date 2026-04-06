import 'package:flutter/material.dart';

import '../services/local_account_store.dart';
import '../theme/app_colors.dart';

class LocalLoginScreen extends StatefulWidget {
  const LocalLoginScreen({super.key});

  @override
  State<LocalLoginScreen> createState() => _LocalLoginScreenState();
}

class _LocalLoginScreenState extends State<LocalLoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final s = await LocalAccountStore.instance.login(_user.text, _pass.text);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (s == null) {
      setState(() => _error = '아이디 또는 비밀번호를 확인해 주세요.');
      return;
    }
    await LocalAccountStore.instance.saveSession(s);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아이디로 로그인'),
        backgroundColor: AppColors.bgMain,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '기기에만 저장되는 자체 계정이에요. 다른 기기와 자동으로 동기화되지 않습니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _user,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: '아이디',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pass,
            obscureText: true,
            onSubmitted: (_) => _busy ? null : _submit(),
            decoration: const InputDecoration(
              labelText: '비밀번호',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('로그인'),
          ),
        ],
      ),
    );
  }
}

class RegisterAccountScreen extends StatefulWidget {
  const RegisterAccountScreen({super.key});

  @override
  State<RegisterAccountScreen> createState() => _RegisterAccountScreenState();
}

class _RegisterAccountScreenState extends State<RegisterAccountScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _nick = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _pass2.dispose();
    _nick.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    if (_pass.text != _pass2.text) {
      setState(() {
        _busy = false;
        _error = '비밀번호 확인이 일치하지 않아요.';
      });
      return;
    }
    final err = await LocalAccountStore.instance.register(
      username: _user.text,
      password: _pass.text,
      displayName: _nick.text,
    );
    if (!mounted) {
      return;
    }
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    final s = await LocalAccountStore.instance.login(_user.text, _pass.text);
    if (!mounted) {
      return;
    }
    if (s == null) {
      setState(() {
        _busy = false;
        _error = '가입 후 로그인에 실패했어요. 다시 시도해 주세요.';
      });
      return;
    }
    await LocalAccountStore.instance.saveSession(s);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    Navigator.of(context).pop(s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 만들기'),
        backgroundColor: AppColors.bgMain,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '별조각으로 상점·보상을 쓰려면 가입이 필요해요. '
            '아래에서 이 기기 전용 계정을 만든 뒤 같은 아이디로 로그인하면 돼요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '별도 서버 없이 이 앱이 설치된 기기에만 계정 정보가 저장됩니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _user,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: '아이디 (영문 소문자·숫자·_)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nick,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '닉네임 (앱에서 표시)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '민감한 개인정보를 유출할 수 있는 비밀번호는 사용하지 말아주세요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade800,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pass,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '비밀번호 (6자 이상)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pass2,
            obscureText: true,
            onSubmitted: (_) => _busy ? null : _submit(),
            decoration: const InputDecoration(
              labelText: '비밀번호 확인',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('가입하고 바로 시작'),
          ),
        ],
      ),
    );
  }
}
