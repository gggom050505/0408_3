import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../config/app_config.dart';
import '../services/local_account_store.dart';
import '../standalone/local_user_data_wipe.dart';
import '../theme/app_colors.dart';
import 'app_scaffold_messenger.dart';

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
    if (AppConfig.devWebPrefillLoginId) {
      _user.text = AppConfig.devWebSeedLogin;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (AppConfig.devWebPrefillLoginId) {
        _passFocus.requestFocus();
      } else {
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
      const msg = '아이디 또는 비밀번호를 확인해 주세요.\n'
          '이 브라우저(기기)에 해당 아이디 계정이 없을 수도 있어요.';
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
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    unawaited(
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (c) => const LocalForgotPasswordReuseScreen(),
                        ),
                      ),
                    );
                  },
            child: const Text('비밀번호를 잊었어요 · 같은 아이디로 다시 가입'),
          ),
        ],
      ),
    );
  }
}

/// 비밀번호 분실 시 이 기기에서만 계정을 지워 같은 아이디로 재가입할 수 있게 합니다.
class LocalForgotPasswordReuseScreen extends StatefulWidget {
  const LocalForgotPasswordReuseScreen({super.key});

  @override
  State<LocalForgotPasswordReuseScreen> createState() =>
      _LocalForgotPasswordReuseScreenState();
}

class _LocalForgotPasswordReuseScreenState
    extends State<LocalForgotPasswordReuseScreen> {
  final _user = TextEditingController();
  final _confirmUser = TextEditingController();
  var _understand = false;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _confirmUser.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final key = LocalAccountStore.instance.normalizeUsername(_user.text);
    final key2 = LocalAccountStore.instance.normalizeUsername(_confirmUser.text);
    if (key == null || key2 == null) {
      setState(
        () => _error =
            '아이디는 3~24자, 영문 소문자·숫자·밑줄(_)만 사용할 수 있어요.',
      );
      return;
    }
    if (key != key2) {
      setState(() => _error = '아이디 확인 칸이 위와 같아야 해요.');
      return;
    }
    if (!_understand) {
      setState(() => _error = '안내에 동의해 주세요.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('계정 삭제 후 재가입'),
        content: const Text(
          '이 아이디의 로그인 정보와 이 기기에 묶인 진행 데이터가 '
          '모두 지워집니다. 되돌릴 수 없습니다. 계속할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제 후 재가입'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final r =
        await LocalAccountStore.instance.deleteAccountWithoutPasswordForReuse(
      loginKey: key,
    );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (r.error != null) {
      setState(() => _error = r.error);
      return;
    }
    final uid = r.removedUserId;
    if (uid != null) {
      await wipeStandaloneArtifactsForAppUserId(uid);
    }
    if (!mounted) {
      return;
    }
    gggomScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text(
          '이 기기에서 계정을 지웠어요. 랜딩에서 「회원 가입」으로 같은 아이디를 다시 만들 수 있어요.',
        ),
      ),
    );
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호를 잊었어요'),
        backgroundColor: AppColors.bgMain,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '비밀번호는 이 기기에만 저장돼 이메일·문자로 찾을 수 없어요. '
            '같은 아이디로 새 비밀번호를 쓰려면, 아래에서 이 기기의 해당 계정을 지운 뒤 '
            '랜딩 화면의 「회원 가입」을 다시 진행해 주세요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _user,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: const InputDecoration(
              labelText: '아이디',
              hintText: '지우려는 계정의 아이디',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmUser,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: const InputDecoration(
              labelText: '아이디 확인',
              hintText: '위와 똑같이 입력',
              border: OutlineInputBorder(),
            ),
          ),
          CheckboxListTile(
            value: _understand,
            onChanged: (v) => setState(() => _understand = v ?? false),
            title: Text(
              '이 계정의 진행 데이터가 이 기기에서 모두 삭제됨을 이해했습니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('이 기기에서 계정 지우기'),
          ),
        ],
      ),
    );
  }
}

/// 로그인 전 랜딩에서 진입 — 아이디·비밀번호 확인 후 탈퇴 및 기기 데이터 정리.
class LocalWithdrawScreen extends StatefulWidget {
  const LocalWithdrawScreen({super.key});

  @override
  State<LocalWithdrawScreen> createState() => _LocalWithdrawScreenState();
}

class _LocalWithdrawScreenState extends State<LocalWithdrawScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  var _obscurePass = true;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final key = LocalAccountStore.instance.normalizeUsername(_user.text);
    if (key == null) {
      setState(() => _error = '아이디는 3~24자, 영문 소문자·숫자·밑줄(_)만 사용할 수 있어요.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '이 계정과 이 기기에 저장된 진행 데이터가 삭제됩니다. '
          '되돌릴 수 없습니다. 계속할까요?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await LocalAccountStore.instance.deleteAccountWithRemovedUserId(
      loginKey: key,
      password: _pass.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (r.error != null) {
      setState(() => _error = r.error);
      return;
    }
    final uid = r.removedUserId;
    if (uid != null) {
      await wipeStandaloneArtifactsForAppUserId(uid);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원 탈퇴가 완료되었어요.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 탈퇴'),
        backgroundColor: AppColors.bgMain,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '가입하신 아이디와 비밀번호를 입력해 주세요. '
            '확인되면 계정이 이 기기에서 삭제됩니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _user,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: const InputDecoration(
              labelText: '아이디',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pass,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: '비밀번호',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                icon: Icon(
                  _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('탈퇴 진행'),
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
    if (AppConfig.devWebPrefillLoginId) {
      _user.text = AppConfig.devWebSeedLogin;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (AppConfig.devWebPrefillLoginId) {
        _nickFocus.requestFocus();
      } else {
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
