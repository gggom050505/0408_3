import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/site_access_session_stub.dart'
    if (dart.library.html) '../services/site_access_session_web.dart';
import '../theme/app_colors.dart';

/// 웹에서 `--dart-define=SITE_ACCESS_PIN=비밀번호` 가 있을 때만 표시.
/// **주의:** 번들 JS에 암호 문자열이 포함됩니다. 진짜 보안·기밀 보호용이 아니라,
/// 실수로 공개된 미리보기 URL·배포를 가리는 정도입니다.
class SiteAccessGate extends StatefulWidget {
  const SiteAccessGate({super.key, required this.child});

  final Widget child;

  @override
  State<SiteAccessGate> createState() => _SiteAccessGateState();
}

class _SiteAccessGateState extends State<SiteAccessGate> {
  var _checkedSession = false;
  var _sessionAllowed = false;
  final _pin = TextEditingController();
  var _error = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final ok = await isSiteAccessSessionOk();
    if (!mounted) return;
    setState(() {
      _checkedSession = true;
      _sessionAllowed = ok;
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final want = AppConfig.siteAccessPin;
    final got = _pin.text.trim();
    if (got != want) {
      setState(() {
        _error = true;
        _busy = false;
      });
      return;
    }
    setState(() => _busy = true);
    await setSiteAccessSessionOk();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sessionAllowed = true;
      _error = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedSession) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.bgMain,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_sessionAllowed) {
      return widget.child;
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColors.accentPurple,
          surface: AppColors.bgMain,
        ),
      ),
      home: Scaffold(
        backgroundColor: AppColors.bgMain,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '접근 확인',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '이 주소는 작업·미리보기용으로 암호가 필요합니다.\n'
                      '공개 서비스 빌드에서는 이 화면이 나오지 않아요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '암호',
                        errorText: _error ? '암호가 맞지 않아요.' : null,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) {
                        if (!_busy) _submit();
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : () => _submit(),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('들어가기'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
