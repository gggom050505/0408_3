import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:gggom_tarot/data/oracle_assets.dart'
    show kBundledOracleCardCount, kBundledOracleTitlesKo;
import 'package:gggom_tarot/standalone/local_json_store_io.dart';
import 'package:gggom_tarot/standalone/local_shop_repository.dart';

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
    tempDir = await Directory.systemTemp.createTemp('gggom_oracle_shop_test_');
    PathProviderPlatform.instance = _TempSupportPathProvider(tempDir);
  });

  tearDownAll(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {
      // Windows: 파일 잠금으로 전체 삭제가 실패할 수 있음.
    }
  });

  test('empty local_shop_catalog_v1 fills default deck, backs, and oracle cards', () async {
    await saveLocalJsonFile('local_shop_catalog_v1.json', '[]');
    final repo = LocalShopRepository('oracle-empty-catalog');
    final items = await repo.fetchShopItems();

    expect(items.any((e) => e.id == 'default' && e.type == 'card'), isTrue);
    expect(
      items.where((e) => e.type == 'card_back').length,
      greaterThanOrEqualTo(1),
    );
    expect(
      items.where((e) => e.type == 'oracle_card').length,
      kBundledOracleCardCount,
    );
  });

  test('bundled oracle titles list matches catalog count', () {
    expect(kBundledOracleTitlesKo.length, kBundledOracleCardCount);
  });

  test('inactive bundled oracle in catalog is reactivated for shop', () async {
    final inactiveOracle = {
      'id': 'oracle-card-01',
      'name': '01. 성운',
      'type': 'oracle_card',
      'price': 3,
      'thumbnail_url': 'oracle_cards/oracle(1).png',
      'is_active': false,
    };
    await saveLocalJsonFile(
      'local_shop_catalog_v1.json',
      jsonEncode([inactiveOracle]),
    );
    final repo = LocalShopRepository('oracle-inactive-row');
    final items = await repo.fetchShopItems();
    final o1 = items.firstWhere((e) => e.id == 'oracle-card-01');
    expect(o1.isActive, isTrue);
    expect(items.where((e) => e.type == 'oracle_card').length, kBundledOracleCardCount);
  });

  test('oracle row with wrong type is repaired and full oracle grid restored', () async {
    final corrupt = [
      {
        'id': 'oracle-card-01',
        'name': 'Bad type row',
        'type': 'card',
        'price': 1,
        'is_active': true,
      },
    ];
    await saveLocalJsonFile(
      'local_shop_catalog_v1.json',
      jsonEncode(corrupt),
    );
    final repo = LocalShopRepository('oracle-corrupt-type');
    final items = await repo.fetchShopItems();

    final o1 = items.firstWhere((e) => e.id == 'oracle-card-01');
    expect(o1.type, 'oracle_card');
    expect(
      items.where((e) => e.type == 'oracle_card').length,
      kBundledOracleCardCount,
    );
  });
}
