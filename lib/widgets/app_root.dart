import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/gggom_runtime_site_config.dart';
import '../config/web_exit_confirm_guard.dart';
import '../services/local_account_store.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  static const _sharedGoogleUserId = 'supabase:google-shared';
  var _showSplash = true;
  var _guestMode = false;
  LocalAccountSession? _localSession;
  User? _supabaseUser;

  @override
  void initState() {
    super.initState();
    if (AppConfig.skipLoginScreen) {
      _guestMode = true;
    }
    WidgetsBinding.instance.addObserver(this);
    installWebExitConfirmGuard();
    unawaited(_bootstrapSession());
  }

  Future<void> _bootstrapSession() async {
    // Google(Supabase) 세션을 먼저 복원 — 예전 로컬 ID 세션이 있어도 구글 계정이 우선입니다.
    if (AppConfig.supabaseEnabled) {
      await _restoreSupabaseSession();
    }
    if (!mounted) {
      return;
    }
    if (_supabaseUser != null) {
      try {
        await LocalAccountStore.instance.clearSession();
      } catch (_) {}
      return;
    }
    await _restoreLocalAppSession();
    if (!mounted) {
      return;
    }
    if (AppConfig.devWebSeedLocalAccountEnabled) {
      await _maybeDevWebSeedLocalAccount();
    }
  }

  Future<void> _restoreSupabaseSession() async {
    if (!AppConfig.supabaseEnabled) {
      return;
    }
    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;
    if (!mounted || user == null) {
      return;
    }
    setState(() {
      _supabaseUser = user;
      _guestMode = false;
    });
  }

  Future<void> _maybeDevWebSeedLocalAccount() async {
    if (_localSession != null || _guestMode || _supabaseUser != null) {
      return;
    }
    final login = AppConfig.devWebSeedLogin;
    final pass = AppConfig.devWebSeedPassword;
    if (LocalAccountStore.instance.normalizeUsername(login) == null) {
      debugPrint('GGGOM_DEV_WEB_SEED: login id 규칙에 맞지 않아요.');
      return;
    }
    var s = await LocalAccountStore.instance.login(login, pass);
    if (s == null) {
      final err = await LocalAccountStore.instance.register(
        username: login,
        password: pass,
        displayName: '동글아저씨',
      );
      if (err != null) {
        debugPrint('GGGOM_DEV_WEB_SEED: register: $err');
        return;
      }
      s = await LocalAccountStore.instance.login(login, pass);
    }
    if (s == null || !mounted) {
      return;
    }
    await LocalAccountStore.instance.setContinueAsGuest(false);
    await LocalAccountStore.instance.saveSession(s);
    if (!mounted) {
      return;
    }
    setState(() {
      _localSession = s;
      _guestMode = false;
    });
  }

  Future<void> _restoreLocalAppSession() async {
    final s = await LocalAccountStore.instance.loadSession();
    if (!mounted) {
      return;
    }
    if (s != null) {
      await LocalAccountStore.instance.setContinueAsGuest(false);
      if (!mounted) {
        return;
      }
      setState(() {
        _localSession = s;
        _guestMode = false;
      });
      return;
    }
    final guest = await LocalAccountStore.instance.shouldContinueAsGuest();
    if (!mounted) {
      return;
    }
    if (guest) {
      setState(() => _guestMode = true);
    }
  }

  @override
  void dispose() {
    uninstallWebExitConfirmGuard();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !AppConfig.useOfflineBundleOnly) {
      unawaited(GggomRuntimeSiteConfig.instance.refreshFromServer());
    }
  }

  void _onSplashDone() => setState(() => _showSplash = false);

  Future<void> _signOut() async {
    if (_localSession != null) {
      await LocalAccountStore.instance.clearSession();
      await LocalAccountStore.instance.setContinueAsGuest(false);
      if (!mounted) {
        return;
      }
      setState(() => _localSession = null);
      return;
    }
    if (_guestMode) {
      await LocalAccountStore.instance.setContinueAsGuest(false);
      if (!mounted) {
        return;
      }
      setState(() => _guestMode = false);
      return;
    }
    if (_supabaseUser != null) {
      if (AppConfig.supabaseEnabled) {
        await Supabase.instance.client.auth.signOut();
      }
      if (!mounted) {
        return;
      }
      setState(() => _supabaseUser = null);
    }
  }

  Future<void> _reloadLocalSession() async {
    final next = await LocalAccountStore.instance.loadSession();
    if (!mounted || next == null) {
      return;
    }
    setState(() => _localSession = next);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashDone);
    }

    if (_supabaseUser != null) {
      return HomeScreen(
        userId: _sharedGoogleUserId,
        displayName: _displayNameFromSupabase(),
        onSignOut: _signOut,
      );
    }

    if (_localSession != null) {
      final s = _localSession!;
      return HomeScreen(
        userId: s.userId,
        displayName: s.displayName,
        onSignOut: _signOut,
        localAccountSession: s,
        onLocalSessionReload: _reloadLocalSession,
      );
    }

    if (_guestMode) {
      return HomeScreen(
        userId: 'local-guest',
        displayName: '게스트',
        onSignOut: _signOut,
      );
    }

    return LoginScreen(
      onContinueAsGuest: _continueAsGuest,
      onOpenGoogleLogin: _openGoogleLogin,
    );
  }

  Future<void> _openGoogleLogin() async {
    if (!AppConfig.googleLoginEnabled) {
      return;
    }
    try {
      // OAuth 리다이렉트 전 브라우저 이탈 확인 가드를 충분히 길게 우회한다.
      allowSingleNavigationWithoutConfirm(const Duration(seconds: 30));
      final redirectTo = kIsWeb
          ? Uri.base.replace(path: '/', query: '', fragment: '').toString()
          : AppConfig.supabaseNativeRedirectUri;
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('구글 로그인 실패: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('구글 로그인 실패: $e')),
      );
    }
  }

  String _displayNameFromSupabase() {
    return '공공곰';
  }

  Future<void> _continueAsGuest() async {
    await LocalAccountStore.instance.setContinueAsGuest(true);
    if (!mounted) {
      return;
    }
    setState(() => _guestMode = true);
  }
}
