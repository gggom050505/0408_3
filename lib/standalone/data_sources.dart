import '../models/emoticon_models.dart';
import '../models/event_item.dart';
import '../models/feed_post.dart';
import '../models/peer_shop_models.dart';
import '../models/shop_models.dart';
/// 피드 데이터 소스 계약(로컬 구현).
abstract class FeedDataSource {
  Future<List<FeedPost>> fetchPosts();

  Future<FeedPost?> addPost({
    required String? userId,
    required String username,
    required String avatar,
    required String content,
    required List<String> tags,
    List<int>? imagePngBytes,
  });

  Future<void> toggleHeart({
    required int postId,
    required String userId,
    required FeedPost post,
  });

  Future<void> deletePost(int postId);

  Future<void> updatePost(int postId, String newContent);

  Future<FeedComment> addComment({
    required int postId,
    required String? userId,
    required String username,
    required String avatar,
    required String content,
  });

  Future<void> deleteComment(int commentId);

  Future<void> updateComment(int commentId, String newContent);
}

abstract class ShopDataSource {
  Future<List<ShopItemRow>> fetchShopItems();

  Future<UserProfileRow?> fetchProfile(String userId);

  Future<List<UserItemRow>> fetchOwnedItems(String userId);

  Future<void> ensureDefaultUserItems(String userId);

  Future<bool> buyItem({
    required String userId,
    required String itemId,
    required int price,
    required String type,
    required UserProfileRow profile,
    required List<UserItemRow> owned,
  });

  Future<UserProfileRow?> equipItem({
    required String userId,
    required String itemId,
    required String type,
  });

  /// 출석 완료 시 별조각·미보유 오라클 카드 1장 지급.
  Future<AttendanceDailyRewardResult?> grantAttendanceDailyReward(
    String userId,
  );

  /// 광고 시청 보상(베타 시뮬)·프로모션 등 — 별조각만 [amount] 만큼 가산(안내 문구는 기본 3개 기준). 실패 시 null.
  Future<UserProfileRow?> grantAdRewardStars(String userId, {int amount = 3});

  /// 첫 가입 세팅: 기본 카드 뒷면·슬롯 장착 + 오라클·이모 지급·별조각(계정별 시드, 이미 있으면 건너뜀).
  Future<bool> completeFirstSetupWizard(String userId);
}

abstract class EmoticonDataSource {
  Future<List<EmoticonPackRow>> fetchPacks();

  Future<List<EmoticonRow>> fetchAllEmoticons();

  Future<List<String>> fetchOwned(String userId);

  Future<bool> buyEmoticon({
    required String userId,
    required String emoticonId,
    required int price,
    required List<String> ownedIds,
  });

  Future<({bool ok, String? error})> buyPack({
    required String userId,
    required String packId,
  });
}

abstract class EventDataSource {
  Future<List<EventItemRow>> fetchActiveEvents();
}

/// 유저 간 별조각 거래(개인 상점). 로컬 번들은 기기 공유 JSON.
abstract class PeerShopDataSource {
  /// 활성 진열 전체(본인 진열 포함). 구매는 [purchaseListing]·UI에서 본인 행 제외.
  Future<List<PeerShopListing>> fetchMarketplace(String currentUserId);

  Future<List<PeerShopListing>> fetchMyListings(String sellerId);

  Future<PeerShopListing?> createListing({
    required String sellerId,
    required String sellerDisplayName,
    required String itemId,
    required String itemType,
    required int priceStars,
  });

  Future<bool> cancelListing({
    required String listingId,
    required String sellerId,
  });

  Future<PeerShopPurchaseOutcome> purchaseListing({
    required String buyerId,
    required String listingId,
  });
}

abstract class AttendanceDataSource {
  Future<bool> checkToday(String userId);

  /// 지정 월(로컬 기준 년/월)의 출석한 일(day) 목록.
  Future<Set<int>> fetchCheckedInDaysOfMonth(
    String userId, {
    required int year,
    required int month,
  });

  Future<Map<String, dynamic>?> doCheckIn(String userId);
}
