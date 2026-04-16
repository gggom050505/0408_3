import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gggom_tarot/config/korea_major_card_catalog.dart';
import 'package:gggom_tarot/data/card_themes.dart';
import 'package:gggom_tarot/models/shop_models.dart';
import 'package:gggom_tarot/standalone/data_sources.dart';
import 'package:gggom_tarot/widgets/bag_tab.dart';

class _FakeBagShopRepo implements ShopDataSource {
  @override
  Future<List<ShopItemRow>> fetchShopItems() async => const [];

  @override
  Future<UserProfileRow?> fetchProfile(String userId) async => null;

  @override
  Future<List<UserItemRow>> fetchOwnedItems(String userId) async => const [];

  @override
  Future<void> ensureDefaultUserItems(String userId) async {}

  @override
  Future<bool> buyItem({
    required String userId,
    required String itemId,
    required int price,
    required String type,
    required UserProfileRow profile,
    required List<UserItemRow> owned,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserProfileRow?> equipItem({
    required String userId,
    required String itemId,
    required String type,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AttendanceDailyRewardResult?> grantAttendanceDailyReward(
    String userId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<UserProfileRow?> grantAdRewardStars(
    String userId, {
    int amount = 3,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> completeFirstSetupWizard(String userId) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('한국전통 메이저 덱 장착 시 조각 그리드 버튼에 「장착」 표시', (tester) async {
    const uid = 'u1';
    final ownedPieceId = koreaMajorCardShopItemId(0);
    final profile = UserProfileRow(
      id: uid,
      starFragments: 0,
      equippedCard: koreaTraditionalMajorThemeId,
      equippedMat: 'default-mint',
      equippedCardBack: 'default-card-back',
    );
    final owned = [
      UserItemRow(
        itemId: ownedPieceId,
        itemType: 'korea_major_card',
        purchasedAt: '',
      ),
    ];
    final shopRows = koreaMajorCardShopCatalogRows();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BagTab(
            repo: _FakeBagShopRepo(),
            userId: uid,
            shopItems: shopRows,
            profile: profile,
            ownedItems: owned,
            onRefresh: () async {},
            onNeedLogin: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('가방'), findsOneWidget);

    expect(find.textContaining('한국전통'), findsWidgets);

    await tester.scrollUntilVisible(
      find.textContaining('🇰🇷 한국전통 메이저'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final pieceBaseName = shopRows.first.name;
    final pieceTitle = '$pieceBaseName · 유니크';
    expect(find.text(pieceTitle), findsOneWidget);

    final equippedPieceButton = find.descendant(
      of: find.ancestor(
        of: find.text(pieceTitle),
        matching: find.byType(Card),
      ),
      matching: find.widgetWithText(FilledButton, '장착'),
    );
    expect(equippedPieceButton, findsOneWidget);
    final btn = tester.widget<FilledButton>(equippedPieceButton);
    expect(btn.onPressed, isNull);

    await tester.scrollUntilVisible(
      find.textContaining('🃏 카드 덱'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('한국전통 메이저카드 (장착)'), findsOneWidget);
  });
}
