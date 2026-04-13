/// 한국전통 메이저 타로 **22장** — `assets/koreacard/korean majors(0).png` ~ `korean majors(21).png`.
///
/// 웹: `pubspec`에 `assets/koreacard/` 등록 → 네트워크 `/cards/` 없이 번들만으로 로드.
/// [getCardImageUrl]은 이 테마에서 `null`을 반환해 항상 이 경로를 쓰게 함.
library;

const String kKoreaTraditionalMajorAssetDir = 'assets/koreacard';

/// RW 메이저와 동일 번호 0~21.
const int kKoreaTraditionalMajorIllustrationCount = 22;

/// 번들에 있는 한국전통 메이저 TarotCard id.
const Set<int> kKoreaTraditionalMajorTarotCardIds = {
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
};

String _koreaTraditionalMajorPngFileName(int cardId) =>
    'korean majors($cardId).png';

/// [cardId] 0~21 → Flutter [Image.asset] 키. 그 외 `null`.
String? koreaTraditionalMajorAssetPath(int cardId) {
  if (cardId < 0 || cardId > 21) {
    return null;
  }
  return '$kKoreaTraditionalMajorAssetDir/${_koreaTraditionalMajorPngFileName(cardId)}';
}

/// 상점·가방 덱 썸네일 (0번 바보·김삿갓 등).
const String kKoreaTraditionalMajorShopThumbnailAsset =
    '$kKoreaTraditionalMajorAssetDir/korean majors(0).png';
