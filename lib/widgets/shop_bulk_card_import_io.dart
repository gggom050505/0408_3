import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/shop_models.dart';

const _imageGroups = <XTypeGroup>[
  XTypeGroup(label: 'PNG', extensions: ['png']),
  XTypeGroup(label: 'JPEG', extensions: ['jpg', 'jpeg']),
  XTypeGroup(label: 'WebP', extensions: ['webp']),
  XTypeGroup(label: 'GIF', extensions: ['gif']),
];

const _extOk = {'.png', '.jpg', '.jpeg', '.webp', '.gif'};

String _makeUniqueItemId(String basenameNoExt, Set<String> used, String emptyFallback) {
  var base = basenameNoExt
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (base.isEmpty) {
    base = emptyFallback;
  }
  if (base.length > 40) {
    base = base.substring(0, 40);
  }
  var candidate = base;
  var n = 2;
  while (used.contains(candidate)) {
    final suffix = '_$n';
    candidate = base.length + suffix.length > 48
        ? '${base.substring(0, 48 - suffix.length)}$suffix'
        : '$base$suffix';
    n++;
  }
  used.add(candidate);
  return candidate;
}

Future<List<ShopItemRow>?> _pickAndRegisterImages({
  required List<ShopItemRow> existingItems,
  required String shopType,
  required String storageSubdir,
  required int defaultPrice,
  required String idFallback,
}) async {
  final files = await openFiles(acceptedTypeGroups: _imageGroups);
  if (files.isEmpty) {
    return null;
  }

  final support = await getApplicationSupportDirectory();
  final dir = Directory(
    p.join(support.path, 'gggom_standalone', 'shop_uploads', storageSubdir),
  );
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final used = {for (final e in existingItems) e.id};
  final out = <ShopItemRow>[];

  for (final xf in files) {
    final srcPath = xf.path;
    if (srcPath.isEmpty) {
      continue;
    }
    final ext = p.extension(srcPath).toLowerCase();
    if (!_extOk.contains(ext)) {
      continue;
    }
    final baseName = p.basenameWithoutExtension(xf.name.isNotEmpty ? xf.name : srcPath);
    final id = _makeUniqueItemId(baseName, used, idFallback);
    final destPath = p.join(dir.path, '$id$ext');
    await File(srcPath).copy(destPath);
    final fileUri = Uri.file(destPath).toString();
    final displayName =
        baseName.replaceAll(RegExp(r'[_-]+'), ' ').trim().isEmpty ? id : baseName.replaceAll('_', ' ');
    out.add(
      ShopItemRow(
        id: id,
        name: displayName,
        type: shopType,
        price: defaultPrice < 0 ? 0 : defaultPrice,
        thumbnailUrl: fileUri,
        isActive: true,
      ),
    );
  }
  return out.isEmpty ? null : out;
}

/// PC/설치형: 카드 덱 — 가격 0, `shop_uploads/card_decks`
Future<List<ShopItemRow>?> pickAndRegisterCardDeckImages({
  required List<ShopItemRow> existingItems,
}) =>
    _pickAndRegisterImages(
      existingItems: existingItems,
      shopType: 'card',
      storageSubdir: 'card_decks',
      defaultPrice: 0,
      idFallback: 'imported-deck',
    );

/// PC/설치형: 매트 — 기본 가격 500(기존 유료 매트와 동일), `shop_uploads/mats`
Future<List<ShopItemRow>?> pickAndRegisterMatImages({
  required List<ShopItemRow> existingItems,
}) =>
    _pickAndRegisterImages(
      existingItems: existingItems,
      shopType: 'mat',
      storageSubdir: 'mats',
      defaultPrice: 500,
      idFallback: 'imported-mat',
    );

/// PC/설치형: 카드 뒷면 — 기본 가격 500, `shop_uploads/card_backs`
Future<List<ShopItemRow>?> pickAndRegisterCardBackImages({
  required List<ShopItemRow> existingItems,
}) =>
    _pickAndRegisterImages(
      existingItems: existingItems,
      shopType: 'card_back',
      storageSubdir: 'card_backs',
      defaultPrice: 500,
      idFallback: 'imported-card-back',
    );

/// 상품 편집 다이얼로그: 이미지 한 장 선택 → `shop_uploads/thumbnails/{itemId}.(png|…)` 에 복사 후 `file://` URI 반환.
/// `path`가 비어 있거나 content URI 등으로 [File.copy]가 안 되면 [XFile.readAsBytes] 로 저장합니다.
Future<String?> pickAndCopyThumbnailForShopItem({required String itemId}) async {
  final xf = await openFile(acceptedTypeGroups: _imageGroups);
  if (xf == null) {
    return null;
  }

  var ext = p.extension(xf.path).toLowerCase();
  if (ext.isEmpty) {
    ext = p.extension(xf.name).toLowerCase();
  }
  if (!_extOk.contains(ext)) {
    return null;
  }

  final support = await getApplicationSupportDirectory();
  final dir = Directory(
    p.join(support.path, 'gggom_standalone', 'shop_uploads', 'thumbnails'),
  );
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final safeId = itemId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final destPath = p.join(dir.path, '$safeId$ext');

  final srcPath = xf.path;
  if (srcPath.isNotEmpty) {
    try {
      final f = File(srcPath);
      if (await f.exists()) {
        await f.copy(destPath);
        return Uri.file(destPath).toString();
      }
    } catch (_) {}
  }

  try {
    final bytes = await xf.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }
    await File(destPath).writeAsBytes(bytes);
    return Uri.file(destPath).toString();
  } catch (_) {
    return null;
  }
}
