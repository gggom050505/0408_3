import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../services/local_account_store.dart';
import '../theme/app_colors.dart';

Future<void> _announceIfMounted(BuildContext context, String message) async {
  final d = Directionality.maybeOf(context);
  final view = View.maybeOf(context);
  if (d == null || view == null) {
    return;
  }
  await SemanticsService.sendAnnouncement(view, message, d);
}

class LocalLoginScreen extends StatefulWidget {
  const LocalLoginScreen({super.key});

  @override
  State<LocalLoginScreen> createState() => _LocalLoginScreenState();
}

class _LocalLoginScreenState extends State<LocalLoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  var _obscurePass = true;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _userFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
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
      const msg = '아이디 또는 비밀번호를 확인해 주세요.';
      setState(() => _error = msg);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _announceIfMounted(context, msg);
        }
      });
      return;
    }
    await LocalAccountStore.instance.saveSession(s);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(s);
  }

  Future<void> _openRegister() async {
    final s = await Navigator.of(context).push<LocalAccountSession>(
      MaterialPageRoute<LocalAccountSession>(
        builder: (c) => const RegisterAccountScreen(),
      ),
    );
    if (!mounted || s == null) {
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
          Semantics(
            container: true,
            child: Text(
              '기기에만 저장되는 자체 계정이에요. 다른 기기와 자동으로 동기화되지 않습니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _user,
                  focusNode: _userFocus,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    hintText: '가입 때 쓴 아이디',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _passFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pass,
                  focusNode: _passFocus,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: const OutlineInputBorder(),
                    suffixIcon: Semantics(
                      label: _obscurePass ? '비밀번호 표시' : '비밀번호 숨기기',
                      button: true,
                      child: IconButton(
                        onPressed: () {
                          setState(() => _obscurePass = !_obscurePass);
                        },
                        icon: Icon(
                          _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!_busy) {
                      _submit();
                    }
                  },
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Tooltip(
            message: '아이디와 비밀번호로 이 기기에만 저장된 계정에 로그인합니다',
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('로그인'),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: _busy ? null : _openRegister,
              child: const Text('회원 가입'),
            ),
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
  final _userFocus = FocusNode();
  final _nickFocus = FocusNode();
  final _passFocus = FocusNode();
  final _pass2Focus = FocusNode();
  var _obscurePass = true;
  var _obscurePass2 = true;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _userFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _pass2.dispose();
    _nick.dispose();
    _userFocus.dispose();
    _nickFocus.dispose();
    _passFocus.dispose();
    _pass2Focus.dispose();
    super.dispose();
  }

  void _setError(String message) {
    setState(() => _error = message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _announceIfMounted(context, message);
      }
    });
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    if (_pass.text != _pass2.text) {
      setState(() => _busy = false);
      _setError('비밀번호 확인이 일치하지 않아요.');
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
      setState(() => _busy = false);
      _setError(err);
      return;
    }
    final s = await LocalAccountStore.instance.login(_user.text, _pass.text);
    if (!mounted) {
      return;
    }
    if (s == null) {
      setState(() => _busy = false);
      _setError('가입 후 로그인에 실패했어요. 다시 시도해 주세요.');
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
        title: const Text('회원 가입'),
        backgroundColor: AppColors.bgMain,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Semantics(
            container: true,
            child: Text(
              '회원 가입 후 같은 아이디로 로그인해 별조각·상점·진행을 이어갈 수 있어요. '
              '아래 정보는 이 기기에만 저장됩니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            child: Text(
              '별도 서버 없이 이 앱이 설치된 기기에만 계정 정보가 저장됩니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _user,
                  focusNode: _userFocus,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    labelText: '아이디 (영문 소문자·숫자·_)',
                    hintText: '예: star_reader_01',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _nickFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nick,
                  focusNode: _nickFocus,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.nickname],
                  decoration: const InputDecoration(
                    labelText: '닉네임 (앱에서 표시)',
                    hintText: '다른 사람에게 보이는 이름',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _passFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                Semantics(
                  container: true,
                  child: Text(
                    '민감한 개인정보를 유출할 수 있는 비밀번호는 사용하지 말아주세요.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800,
                          height: 1.35,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  focusNode: _passFocus,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: '비밀번호 (6자 이상)',
                    border: const OutlineInputBorder(),
                    suffixIcon: Semantics(
                      label: _obscurePass ? '비밀번호 표시' : '비밀번호 숨기기',
                      button: true,
                      child: IconButton(
                        onPressed: () {
                          setState(() => _obscurePass = !_obscurePass);
                        },
                        icon: Icon(
                          _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _pass2Focus.requestFocus(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pass2,
                  focusNode: _pass2Focus,
                  obscureText: _obscurePass2,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    border: const OutlineInputBorder(),
                    suffixIcon: Semantics(
                      label: _obscurePass2 ? '비밀번호 확인란 표시' : '비밀번호 확인란 숨기기',
                      button: true,
                      child: IconButton(
                        onPressed: () {
                          setState(() => _obscurePass2 = !_obscurePass2);
                        },
                        icon: Icon(
                          _obscurePass2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!_busy) {
                      _submit();
                    }
                  },
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Tooltip(
            message: '이 기기에만 저장되는 아이디·비밀번호 계정을 만듭니다',
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('회원 가입'),
            ),
          ),
        ],
      ),
    );
  }
}
