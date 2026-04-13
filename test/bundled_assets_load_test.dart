import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/bundle_emoticon_catalog.dart';
import 'package:gggom_tarot/config/gggom_offline_landing.dart';
import 'package:gggom_tarot/data/card_themes.dart';
import 'package:gggom_tarot/data/slot_shop_assets.dart';
import 'package:gggom_tarot/data/tarot_cards.dart';

Future<void> _expectAssetLoads(String key) async {
  try {
    final data = await rootBundle.load(key);
    expect(
      data.lengthInBytes,
      greaterThan(0),
      reason: 'empty asset: $key',
    );
  } catch (e, st) {
    fail('Missing or unloadable asset: $key\n$e\n$st');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    '번들 카드·오라클·이모티콘·슬롯·뒷면·스플래시 등 에셋이 rootBundle에서 로드됨',
    () async {
      for (var i = 1; i <= 80; i++) {
        await _expectAssetLoads('assets/oracle/oracle($i).png');
      }

      for (var i = 1; i <= kBundleEmoticonCount; i++) {
        await _expectAssetLoads(bundleEmoticonAssetPath(i));
      }

      for (var i = 0; i <= 21; i++) {
        final p = koreaTraditionalMajorAssetPath(i);
        expect(p, isNotNull);
        await _expectAssetLoads(p!);
      }

      const themeIds = <String>[
        defaultThemeId,
        koreanClayThemeId,
        koreaTraditionalMajorThemeId,
        majorClayThemeId,
      ];
      final uniqueCardPaths = <String>{};
      for (final card in tarotDeck) {
        for (final themeId in themeIds) {
          final p = getBundledSiteCardAssetPath(
            themeId: themeId,
            cardId: card.id,
          );
          if (p != null) {
            uniqueCardPaths.add(p);
          }
        }
      }
      for (final p in uniqueCardPaths) {
        await _expectAssetLoads(p);
      }

      for (final t in kBundledSlotShopAssetTuples) {
        await _expectAssetLoads(t.$3);
      }

      const cardBacks = <String>[
        'assets/card_back/back_cat.png',
        'assets/card_back/back_dog.png',
        'assets/card_back/back_moon.png',
        'assets/card_back/back_tiger.png',
        'assets/card_back/back_wonyeos.png',
        'assets/card_back/back_owl.png',
      ];
      for (final b in cardBacks) {
        await _expectAssetLoads(b);
      }

      await _expectAssetLoads(kGggomSiteSplashPngAsset);
      await _expectAssetLoads('$kGggomBundledPublicRoot/favicon.ico');
      await _expectAssetLoads('docs/MAKING_NOTES.md');
      await _expectAssetLoads('assets/config/flutter_runtime_config.json');

      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final keys = manifest.listAssets();

      for (var i = 1; i <= 80; i++) {
        final logical = 'oracle_cards/oracle($i).png';
        final resolved = resolveGggomBundledSitePath(logical);
        expect(resolved, 'assets/oracle/oracle($i).png',
            reason: '상점·웹 논리 경로 $logical → 번들 PNG');
        await _expectAssetLoads(resolved!);
      }

      expect(
        keys.where((k) => k.startsWith('$kGggomBundledPublicRoot/oracle_cards/')),
        isEmpty,
        reason: '오라클 PNG는 assets/oracle/ 단일 폴더만 사용 (www 미러 불필요)',
      );

      final siteCardBacks = keys
          .where((k) => k.startsWith('$kGggomBundledPublicRoot/card_backs/'))
          .toList();
      expect(siteCardBacks, isNotEmpty);
      for (final k in siteCardBacks) {
        await _expectAssetLoads(k);
      }

      final openingImages = keys
          .where((k) => k.startsWith('assets/opening/'))
          .where(
            (k) => RegExp(
              r'\.(png|jpg|jpeg|webp|gif)$',
              caseSensitive: false,
            ).hasMatch(k),
          )
          .toList();
      expect(openingImages, isNotEmpty);
      for (final k in openingImages) {
        await _expectAssetLoads(k);
      }
    },
  );
}
