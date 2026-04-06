import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'gggom_site_public_catalog.dart';

/// 사이트에 올려 둔 JSON으로 Supabase URL·anon 키·에셋 오리진 등을 **앱 재설치 없이** 바꿉니다.
/// `dart-define`으로 넣은 값은 [AppConfig]에서 항상 우선합니다.
///
/// **가비아·정적 호스팅**: `flutter build web` 결과의 `app/flutter_runtime_config.json`(본 저장소는 [web/app/flutter_runtime_config.json] 이 빌드에 포함됨).
/// **Next.js 등**: `public/app/flutter_runtime_config.json` 과 동일 경로로 배포해도 됨.
/// 원격이 404이면 앱은 번들 폴백 JSON을 쓰고, 사이트에 파일이 있으면 원격이 우선합니다.
///
/// 단일 URL만 쓰고 싶을 때: `--dart-define=RUNTIME_CONFIG_URL=https://.../x.json`
///
/// 서버 예시:
/// ```json
/// {
///   "supabase_url": "https://xxxx.supabase.co",
///   "supabase_anon_key": "eyJ...",
///   "asset_origin": "https://www.gggom0505.kr",
///   "web_auth_callback_path": "/auth/callback"
/// }
/// ```
class GggomRuntimeSiteConfig extends ChangeNotifier {
  GggomRuntimeSiteConfig._();
  static final GggomRuntimeSiteConfig instance = GggomRuntimeSiteConfig._();

  static const _runtimeConfigUrlEnv =
      String.fromEnvironment('RUNTIME_CONFIG_URL', defaultValue: '');

  static const _bundledAssetPath = 'assets/config/flutter_runtime_config.json';

  String? _supabaseUrl;
  String? _supabaseAnonKey;
  String? _assetOrigin;
  String? _webAuthCallbackPath;

  DateTime? _lastFetchUtc;
  Object? lastError;

  /// 마지막 응답이 **번들 폴백**이면 true (원격 200이 아님).
  bool lastLoadUsedBundledFallback = false;

  var _fetchCompletedOk = false;

  /// 마지막으로 설정이 확정된 시각(원격 200 또는 번들 적용).
  DateTime? get lastFetchUtc => _lastFetchUtc;

  String? get supabaseUrl => _nonEmpty(_supabaseUrl);
  String? get supabaseAnonKey => _nonEmpty(_supabaseAnonKey);
  String? get assetOrigin => _nonEmpty(_assetOrigin);
  String? get webAuthCallbackPath => _nonEmpty(_webAuthCallbackPath);

  static String? _nonEmpty(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) {
      return null;
    }
    return t;
  }

  /// 첫 번째 후보 URL(디버그·문서용). 실제 로드는 [_candidateUris] 전부를 순회합니다.
  Uri get configUri => _candidateUris().first;

  List<Uri> _candidateUris() {
    if (_runtimeConfigUrlEnv.isNotEmpty) {
      return [Uri.parse(_runtimeConfigUrlEnv)];
    }
    final base =
        GggomSitePublicCatalog.siteOrigin.replaceAll(RegExp(r'/$'), '');
    return [
      Uri.parse('$base/app/flutter_runtime_config.json'),
      Uri.parse('$base/flutter_runtime_config.json'),
    ];
  }

  /// [force]가 true이면 매번 다시 요청(앱 복귀 시 등). false면 첫 성공(원격 또는 번들) 전까지만 재시도.
  Future<void> load({bool force = false}) async {
    if (!force && _fetchCompletedOk) {
      return;
    }
    lastLoadUsedBundledFallback = false;
    try {
      Object? lastHttpErr;
      for (final uri in _candidateUris()) {
        try {
          final res = await http.get(uri).timeout(const Duration(seconds: 12));
          if (res.statusCode == 200) {
            final raw = jsonDecode(res.body);
            if (raw is! Map<String, dynamic>) {
              lastError = FormatException('not an object');
              return;
            }
            _applyJson(raw);
            _lastFetchUtc = DateTime.now().toUtc();
            _fetchCompletedOk = true;
            lastError = null;
            notifyListeners();
            return;
          }
          lastHttpErr = StateError('HTTP ${res.statusCode} for $uri');
        } catch (e) {
          lastHttpErr = e;
        }
      }

      final bundled = await _tryLoadBundledJson();
      if (bundled != null) {
        _applyJson(bundled);
        _lastFetchUtc = DateTime.now().toUtc();
        _fetchCompletedOk = true;
        lastLoadUsedBundledFallback = true;
        lastError = null;
        notifyListeners();
        return;
      }

      lastError = lastHttpErr;
      debugPrint('GggomRuntimeSiteConfig: remote failed and no bundled JSON: $lastHttpErr');
    } catch (e, st) {
      lastError = e;
      debugPrint('GggomRuntimeSiteConfig.load failed: $e\n$st');
    }
  }

  Future<Map<String, dynamic>?> _tryLoadBundledJson() async {
    try {
      final s = await rootBundle.loadString(_bundledAssetPath);
      final raw = jsonDecode(s);
      if (raw is Map<String, dynamic>) {
        return raw;
      }
    } catch (e) {
      debugPrint('GggomRuntimeSiteConfig: bundled $_bundledAssetPath: $e');
    }
    return null;
  }

  void _applyJson(Map<String, dynamic> j) {
    _supabaseUrl = null;
    _supabaseAnonKey = null;
    _assetOrigin = null;
    _webAuthCallbackPath = null;

    String? str(String k) {
      final v = j[k];
      if (v is String) {
        return v.trim().isEmpty ? null : v.trim();
      }
      return null;
    }

    _supabaseUrl = str('supabase_url') ?? str('supabaseUrl');
    _supabaseAnonKey =
        str('supabase_anon_key') ?? str('supabaseAnonKey') ?? str('anon_key');
    _assetOrigin = str('asset_origin') ?? str('assetOrigin') ?? str('site_origin');
    _webAuthCallbackPath =
        str('web_auth_callback_path') ?? str('webAuthCallbackPath');
  }

  /// 앱이 다시 포그라운드에 올 때 호출 — 사이트에서 URL을 바꾼 뒤 곧바로 반영.
  Future<void> refreshFromServer() => load(force: true);
}
