import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gggom_tarot/config/korea_major_card_catalog.dart';
import 'package:gggom_tarot/standalone/local_json_store_io.dart';
import 'package:gggom_tarot/standalone/local_shop_repository.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _TempSupportPathProvider extends PathProviderPlatform {
  _TempSupportPathProvider(this.root);

  final Directory root;

  @override
  Future<String?> getApplicationSupportPath() async => root.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('gggom_korea_major_shop_test_');
    PathProviderPlatform.instance = _TempSupportPathProvider(tempDir);
  });

  tearDownAll(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('empty local_shop_catalog_v1 includes 22 korea_major_card rows', () async {
    await saveLocalJsonFile('local_shop_catalog_v1.json', '[]');
    final repo = LocalShopRepository('korea-major-empty-catalog');
    final items = await repo.fetchShopItems();
    final majors = items.where((e) => e.type == 'korea_major_card').toList();
    expect(majors.length, 22);
    for (var i = 0; i < 22; i++) {
      expect(majors.any((e) => e.id == koreaMajorCardShopItemId(i)), isTrue);
    }
  });

  test('inactive korea_major_card in catalog is reactivated for shop', () async {
    final inactive = {
      'id': koreaMajorCardShopItemId(0),
      'name': 'hidden',
      'type': 'korea_major_card',
      'price': 5,
      'thumbnail_url': 'assets/koreacard/majors(0).png',
      'is_active': false,
    };
    await saveLocalJsonFile(
      'local_shop_catalog_v1.json',
      jsonEncode([inactive]),
    );
    final repo = LocalShopRepository('korea-major-inactive');
    final items = await repo.fetchShopItems();
    final m0 = items.firstWhere((e) => e.id == koreaMajorCardShopItemId(0));
    expect(m0.isActive, isTrue);
    expect(items.where((e) => e.type == 'korea_major_card').length, 22);
  });
}
