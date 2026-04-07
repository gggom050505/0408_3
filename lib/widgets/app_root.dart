import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 앱 세션: **일반 사용자**는 [LocalAccountSession](ID·비밀번호·기기 로컬).
import '../config/app_config.dart';
import '../config/gggom_runtime_site_config.dart';
import '../services/local_account_store.dart';
import '../services/user_monitoring_service.dart';
import 'app_scaffold_messenger.dart';
import 'home_screen.dart';
import 'local_account_auth_screens.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

String _displayNameFromUser(User? user) {
  final m = user?.userMetadata;
  if (m == null) return '게스트';
  final a = m['full_name'] ?? m['name'];
  if (a is String && a.isNotEmpty) return a;
  return '게스트';
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  var _showSplash = true;
  var _guestMode = false;
  StreamSubscription<AuthState>? _authSub;
  Session? _session;
  LocalAccountSession? _localSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (AppConfig.supabaseEnabled) {
      _session = Supabase.instance.client.auth.currentSession;
      UserMonitoringService.instance.syncWithSession(_session);
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        setState(() {
          _session = data.session;
          if (data.session != null) {
            _guestMode = false;
            _localSession = null;
          }
        });
        UserMonitoringService.instance.syncWithSession(data.session);
        if (data.session != null) {
          unawaited(() async {
            await LocalAccountStore.instance.clearSession();
            await LocalAccountStore.instance.setContinueAsGuest(false);
          }());
        }
      });
    }
    unawaited(_restoreLocalAppSession());
  }

  Future<void> _restoreLocalAppSession() async {
    if (AppConfig.supabaseEnabled &&
        Supabase.instance.client.auth.currentSession != null) {
      return;
    }
    final s = await LocalAccountStore.instance.loadSession();
    if (!mounted) {
      return;
    }
    if (_session != null) {
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
    if (!mounted || _session != null) {
      return;
    }
    if (guest) {
      setState(() => _guestMode = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    UserMonitoringService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !AppConfig.useOfflineBundleOnly) {
      unawaited(GggomRuntimeSiteConfig.instance.refreshFromServer());
    }
    if (state == AppLifecycleState.resumed) {
      UserMonitoringService.instance.onAppResumed();
    }
  }

  void _onSplashDone() => setState(() => _showSplash = false);

  Future<void> _openLocalLogin() async {
    final s = await Navigator.of(context).push<LocalAccountSession>(
      MaterialPageRoute<LocalAccountSession>(
        builder: (c) => const LocalLoginScreen(),
      ),
    );
    if (s == null || !mounted) {
      return;
    }
    await LocalAccountStore.instance.setContinueAsGuest(false);
    if (!mounted) {
      return;
    }
    setState(() {
      _localSession = s;
      _guestMode = false;
    });
  }

  Future<void> _openRegister() async {
    final s = await Navigator.of(context).push<LocalAccountSession>(
      MaterialPageRoute<LocalAccountSession>(
        builder: (c) => const RegisterAccountScreen(),
      ),
    );
    if (s == null || !mounted) {
      return;
    }
    await LocalAccountStore.instance.setContinueAsGuest(false);
    if (!mounted) {
      return;
    }
    setState(() {
      _localSession = s;
      _guestMode = false;
    });
  }

  Future<void> _openWithdraw() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (c) => const LocalWithdrawScreen()),
    );
  }

  Future<void> _openGoogleLogin() async {
    if (!AppConfig.supabaseEnabled) {
      return;
    }
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.oauthRedirectUrl,
      );
    } catch (e, st) {
      debugPrint('Google OAuth: $e\n$st');
      gggomScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('구글 로그인을 시작하지 못했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

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
    if (!AppConfig.supabaseEnabled) return;
    await Supabase.instance.client.auth.signOut();
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

    if (_session != null) {
      final user = _session!.user;
      return HomeScreen(
        userId: user.id,
        displayName: _displayNameFromUser(user),
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
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
      onOpenLocalLogin: _openLocalLogin,
      onOpenRegister: _openRegister,
      onOpenWithdraw: _openWithdraw,
      onOpenGoogleLogin: AppConfig.supabaseEnabled ? _openGoogleLogin : null,
    );
  }
}
