import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 앱 세션 모델: **일반 사용자**는 [LocalAccountSession](아이디·비밀번호·기기 로컬),
/// **운영자**만 Supabase 구글 [kShopAdminGoogleEmail]. 기능·데이터 소스는 로컬 계정 기준으로 맞춥니다.
import '../config/app_config.dart';
import '../config/gggom_runtime_site_config.dart';
import '../config/shop_admin_gate.dart';
import '../services/local_account_store.dart';
import 'app_scaffold_messenger.dart';
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
          unawaited(() async {
            final wasAdminOAuth = consumePendingAdminGoogleOAuth();
            if (wasAdminOAuth && !shopAdminGateAllowsCurrentUser()) {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                gggomScaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text(
                      '관리자 전용 로그인입니다. 지정된 gggom0505 구글 계정으로 '
                      '다시 시도해 주세요.',
                    ),
                    duration: Duration(seconds: 6),
                  ),
                );
              }
              return;
            }
            await LocalAccountStore.instance.clearSession();
            await LocalAccountStore.instance.setContinueAsGuest(false);
          }());
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

  Future<void> _signInGoogleAdmin() async {
    if (!AppConfig.supabaseEnabled) {
      return;
    }
    markPendingAdminGoogleOAuth();
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.oauthRedirectUrl,
      queryParams: {
        'prompt': 'select_account',
        'login_hint': kShopAdminGoogleEmail,
      },
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.externalApplication : LaunchMode.platformDefault,
    );
  }

  Future<void> _openLocalLogin() async {
    clearPendingAdminGoogleOAuth();
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
      supabaseConfigured: AppConfig.supabaseEnabled,
      onAdminGoogleLogin:
          AppConfig.supabaseEnabled ? _signInGoogleAdmin : null,
      onOpenLocalLogin: _openLocalLogin,
    );
  }
}
