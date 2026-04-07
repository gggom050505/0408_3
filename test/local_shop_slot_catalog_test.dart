import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gggom_tarot/data/slot_shop_assets.dart';
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
    tempDir = await Directory.systemTemp.createTemp('gggom_slot_shop_test_');
    PathProviderPlatform.instance = _TempSupportPathProvider(tempDir);
  });

  tearDownAll(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('empty local_shop_catalog_v1 includes all bundled slot rows', () async {
    await saveLocalJsonFile('local_shop_catalog_v1.json', '[]');
    final repo = LocalShopRepository('slot-empty-catalog');
    final items = await repo.fetchShopItems();
    final slots = items.where((e) => e.type == 'slot').toList();
    expect(slots.length, kBundledSlotShopAssetTuples.length);
    for (final t in kBundledSlotShopAssetTuples) {
      expect(slots.any((e) => e.id == t.$1), isTrue);
    }
  });

  test('inactive bundled slot in catalog is reactivated for shop', () async {
    final inactive = {
      'id': kDefaultEquippedSlotId,
      'name': 'hidden slot',
      'type': 'slot',
      'price': 0,
      'thumbnail_url': 'assets/slot/Gemini_Generated_Image_6s11ca6s11ca6s11.png',
      'is_active': false,
    };
    await saveLocalJsonFile(
      'local_shop_catalog_v1.json',
      jsonEncode([inactive]),
    );
    final repo = LocalShopRepository('slot-inactive-row');
    final items = await repo.fetchShopItems();
    final s1 = items.firstWhere((e) => e.id == kDefaultEquippedSlotId);
    expect(s1.isActive, isTrue);
    expect(
      items.where((e) => e.type == 'slot').length,
      kBundledSlotShopAssetTuples.length,
    );
  });
}
