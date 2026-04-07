import '../config/app_config.dart';
import '../data/card_themes.dart'
    show normalizeFlutterBundledAssetKey, resolvePublicAssetUrl;
import '../models/emoticon_models.dart';
import 'bundle_emoticon_catalog.dart';
import 'emoticon_offline_manifest.g.dart';
import 'gggom_site_public_catalog.dart';

String _normalizeImageUrlKey(String u) {
  final t = u.trim();
  final stripped = t.replaceFirst(RegExp(r'^/+'), '');
  if (stripped.startsWith('assets/')) {
    return stripped;
  }
  final uri = Uri.tryParse(t);
  if (uri == null) {
    return t;
  }
  return '${uri.scheme}://${uri.host}${uri.path}';
}

bool _looksAbsoluteHttp(String s) =>
    s.startsWith('http://') || s.startsWith('https://');

/// 웹 `public/emoticon` 에 2·3번팩 PNG가 아직 없을 때(404) **배포된 1번팩** 파일로 대체합니다.
/// 같은 슬롯 번호(예: _05)가 세 팩에서 동일 그림이 되지 않도록, 팩마다 1번팩 슬롯을 어긋나게 골라 씁니다.
/// (진짜 2·3번 이미지는 CDN 배포 또는 `sync_emoticons` 번들 후 원본 경로 사용)
String _remapUndeployedPackEmoticonPath(String path) {
  final p = path.trim();
  final re = RegExp(
    r'^/emoticon/(2|3)번팩/emo_0(2|3)_(\d+)\.(png|jpe?g|webp|gif)$',
    caseSensitive: false,
  );
  final m = re.firstMatch(p);
  if (m == null) {
    return p;
  }
  final packNum = int.parse(m.group(1)!);
  final idx = int.parse(m.group(3)!);
  final ext = m.group(4)!;
  final mapped = ((idx - 1) + (packNum - 1) * 5) % 15 + 1;
  final padded = mapped.toString().padLeft(2, '0');
  return '/emoticon/1번팩/emo_01_$padded.$ext';
}

/// DB `image_url` / 출석 보상 URL 등 — 로컬에 복제됐으면 에셋 경로로 바꿉니다.
/// 상대 경로(`/emoticon/...` 등)는 [AppConfig.assetOrigin] 또는 [GggomSitePublicCatalog.siteOrigin] 에 붙여 `Image.network` 가 로드하도록 합니다.
String resolveEmoticonImageSrc({
  required String remoteImageUrl,
  String? emoticonId,
}) {
  var trimmed = remoteImageUrl.trim();
  if (trimmed.isEmpty && emoticonId != null && emoticonId.isNotEmpty) {
    final bundlePath = bundleEmoticonImagePathForId(emoticonId);
    if (bundlePath != null && bundlePath.isNotEmpty) {
      trimmed = bundlePath;
    }
  }
  if (trimmed.isEmpty) {
    return trimmed;
  }
  trimmed = normalizeFlutterBundledAssetKey(trimmed);
  trimmed = _remapUndeployedPackEmoticonPath(trimmed);
  trimmed = normalizeFlutterBundledAssetKey(trimmed);

  if (emoticonId != null && emoticonId.isNotEmpty) {
    final byId = kEmoticonOfflineAssetById[emoticonId];
    if (byId != null && byId.isNotEmpty) {
      return normalizeFlutterBundledAssetKey(byId);
    }
  }
  final key = _normalizeImageUrlKey(trimmed);
  var resolved = kEmoticonOfflineAssetByImageUrl[key] ??
      kEmoticonOfflineAssetByImageUrl[trimmed] ??
      trimmed;
  resolved = normalizeFlutterBundledAssetKey(resolved);

  if (_looksAbsoluteHttp(resolved) || resolved.startsWith('data:image/')) {
    return resolved;
  }
  if (resolved.startsWith('assets/')) {
    return resolved;
  }

  final origin = AppConfig.assetOrigin.trim().isNotEmpty
      ? AppConfig.assetOrigin.trim().replaceAll(RegExp(r'/$'), '')
      : GggomSitePublicCatalog.siteOrigin;
  final path = resolved.startsWith('/') ? resolved : '/$resolved';
  final u = Uri.parse(origin).resolve(path);
  return u.toString();
}

/// 피커 전용: 최종 로드 URL([resolveEmoticonImageSrc])이 같은 행은 **앞선 하나만** 남깁니다.
///
/// 2·3번팩이 CDN에 없어 1번팩 PNG로 돌려쓰는 동안, 슬롯 조합에 따라 같은 파일이 여러 ID에
/// 매달릴 수 있어 **파일명만 다른 중복 썸네일**이 생깁니다. 채팅 맵 등 전체 목록은 그대로 두고
/// 선택 그리드에서만 걸러 냅니다.
List<EmoticonRow> dedupeEmoticonsForPicker(List<EmoticonRow> rows) {
  final seen = <String>{};
  final out = <EmoticonRow>[];
  for (final e in rows) {
    if (e.imageUrl.trim().isEmpty) {
      out.add(e);
      continue;
    }
    final src = resolveEmoticonImageSrc(
      remoteImageUrl: e.imageUrl,
      emoticonId: e.id,
    );
    if (src.isEmpty) {
      out.add(e);
      continue;
    }
    // 앱 번들 `emo_asset_*`는 순환 URL로 그림이 겹칠 수 있음 — 보유 슬롯은 모두 피커에 둠.
    if (e.id.isNotEmpty && isBundledEmoticonId(e.id)) {
      out.add(e);
      continue;
    }
    if (seen.contains(src)) {
      continue;
    }
    seen.add(src);
    out.add(e);
  }
  return out;
}

/// `thumbnail_url` (상대 경로 또는 절대 URL) + 오프라인 팩 썸네일.
String? resolveEmoticonPackThumbnailSrc({
  required String packId,
  required String? remoteThumbnailPath,
  required String assetOrigin,
}) {
  final local = kEmoticonPackThumbOfflineById[packId];
  if (local != null && local.isNotEmpty) return local;
  if (remoteThumbnailPath == null) return null;
  return resolvePublicAssetUrl(remoteThumbnailPath, assetOrigin);
}
