import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gggom_tarot/data/card_back_shop_assets.dart';
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
    tempDir = await Directory.systemTemp.createTemp('gggom_card_back_shop_test_');
    PathProviderPlatform.instance = _TempSupportPathProvider(tempDir);
  });

  tearDownAll(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('empty catalog includes six bundled card backs and default back', () async {
    await saveLocalJsonFile('local_shop_catalog_v1.json', '[]');
    final repo = LocalShopRepository('card-back-empty');
    final items = await repo.fetchShopItems();
    final backs = items.where((e) => e.type == 'card_back').toList();
    expect(backs.any((e) => e.id == 'default-card-back'), isTrue);
    expect(
      backs.where((e) => e.id.startsWith('card-back-')).length,
      bundledCardBackShopRows().length,
    );
  });

  test('inactive bundled card_back row is reactivated', () async {
    final inactive = {
      'id': 'card-back-cat',
      'name': 'x',
      'type': 'card_back',
      'price': 5,
      'thumbnail_url': 'assets/card_back/back_cat.png',
      'is_active': false,
    };
    await saveLocalJsonFile('local_shop_catalog_v1.json', jsonEncode([inactive]));
    final repo = LocalShopRepository('card-back-inactive');
    final items = await repo.fetchShopItems();
    final cat = items.firstWhere((e) => e.id == 'card-back-cat');
    expect(cat.isActive, isTrue);
  });
}
