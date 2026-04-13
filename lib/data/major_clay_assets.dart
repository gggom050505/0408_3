/// 3D 클레이풍 메이저 일러스트 (`assets/major/`).
///
/// * RW 메이저 **22장** (TarotCard id 0~21)
/// * 같은 스타일 확장 **2장** — TarotCard id **82, 83** (Mother / Father)
///
/// 합계 **24장**. 파일명은 한글이나 웹·Flutter 번들에서 정상 동작하도록 `pubspec`에
/// `assets/major/` 폴더를 통째로 넣는다.
library;

const String kMajorClayAssetDir = 'assets/major';

/// 상점·가방 썸네일용 (0번).
const String kMajorClayShopThumbnailAsset = '$kMajorClayAssetDir/majors(0).png';

/// TarotCard id → 번들 상대 경로. 메이저·82·83만. 그 외는 `null` (마이너 등은 default 덱).
String? majorClayAssetPathForTarotCardId(int cardId) {
  final name = _majorClayFileById[cardId];
  if (name == null) {
    return null;
  }
  return '$kMajorClayAssetDir/$name';
}

const Map<int, String> _majorClayFileById = {
  0: 'majors(0).png',
  1: 'majors(1).png',
  2: 'majors(2).png',
  3: 'majors(3).png',
  4: 'majors(4).png',
  5: 'majors(5).png',
  6: 'majors(6).png',
  7: 'majors(7).png',
  8: 'majors(8).png',
  9: 'majors(9).png',
  10: 'majors(10).png',
  11: 'majors(11).png',
  12: 'majors(12).png',
  13: 'majors(13).png',
  14: 'majors(14).png',
  15: 'majors(15).png',
  16: 'majors(16).png',
  17: 'majors(17).png',
  18: 'majors(18).png',
  19: 'majors(19).png',
  20: 'majors(20).png',
  21: 'majors(21).png',
  82: 'majors(22).png',
  83: 'majors(23).png',
};

/// 클레이 메이저 에셋이 있는 TarotCard id (24개).
const Set<int> kMajorClayTarotCardIds = {
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
  82, 83,
};
