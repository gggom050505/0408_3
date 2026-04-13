import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gggom_tarot/config/bundled_card_deck_shop_catalog.dart';
import 'package:gggom_tarot/data/card_themes.dart';
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
    tempDir = await Directory.systemTemp.createTemp('gggom_card_deck_shop_test_');
    PathProviderPlatform.instance = _TempSupportPathProvider(tempDir);
  });

  tearDownAll(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('inactive bundled card deck row is reactivated (local catalog)', () async {
    final inactiveDefault = {
      'id': defaultThemeId,
      'name': 'x',
      'type': 'card',
      'price': 0,
      'thumbnail_url': null,
      'is_active': false,
    };
    await saveLocalJsonFile(
      'local_shop_catalog_v1.json',
      jsonEncode([inactiveDefault]),
    );
    final repo = LocalShopRepository('deck-inactive');
    final items = await repo.fetchShopItems();
    final d = items.firstWhere((e) => e.id == defaultThemeId);
    expect(d.isActive, isTrue);
    expect(d.name, '기본 카드 덱');
  });

  test('bundledCardDeckShopRows has three free decks', () {
    final rows = bundledCardDeckShopRows();
    expect(rows.length, 3);
    expect(rows.map((e) => e.id).toSet(), {
      defaultThemeId,
      mixedMinorKoreaTraditionalMajorThemeId,
      majorClayThemeId,
    });
  });
}
