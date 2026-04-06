import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/gggom_runtime_site_config.dart';
import '../services/local_account_store.dart';
import '../services/user_monitoring_service.dart';
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
          unawaited(LocalAccountStore.instance.clearSession());
        }
      });
    }
    unawaited(_restoreLocalAppSession());
  }

  Future<void> _restoreLocalAppSession() async {
    if (AppConfig.supabaseEnabled && Supabase.instance.client.auth.currentSession != null) {
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
      setState(() {
        _localSession = s;
        _guestMode = false;
      });
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

  void _continueAsGuest() {
    unawaited(LocalAccountStore.instance.clearSession());
    setState(() {
      _guestMode = true;
      _localSession = null;
    });
  }

  Future<void> _signInGoogle() async {
    if (!AppConfig.supabaseEnabled) return;
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.oauthRedirectUrl,
      // Google OAuth: 계정 선택창을 띄우도록 요청(Supabase authorize URL에 전달).
      queryParams: const {'prompt': 'select_account'},
      // 웹에서 같은 탭으로 열면 이미 로그인된 구글 계정으로 바로 붙는 경우가 있어
      // 새 창/외부 브라우저로 연다(모바일은 supabase_flutter가 구글 시 외부 브라우저 사용).
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.externalApplication : LaunchMode.platformDefault,
    );
  }

  Future<void> _openLocalLogin() async {
    final s = await Navigator.of(context).push<LocalAccountSession>(
      MaterialPageRoute<LocalAccountSession>(
        builder: (c) => const LocalLoginScreen(),
      ),
    );
    if (s == null || !mounted) {
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
    setState(() {
      _localSession = s;
      _guestMode = false;
    });
  }

  Future<void> _signOut() async {
    if (_localSession != null) {
      await LocalAccountStore.instance.clearSession();
      setState(() => _localSession = null);
      return;
    }
    if (_guestMode) {
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
      supabaseConfigured: AppConfig.supabaseEnabled,
      onGoogleLogin: _signInGoogle,
      onContinueAsGuest: _continueAsGuest,
      onOpenLocalLogin: _openLocalLogin,
      onOpenRegister: _openRegister,
    );
  }
}
