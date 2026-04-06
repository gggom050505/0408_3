import '../config/shop_random_prices.dart';
import '../models/shop_models.dart';

/// 번들 오라클 카드 80장 — 실제 PNG: `assets/oracle/oracle(1).png` ~ `oracle(80).png`
const int kBundledOracleCardCount = 80;

/// 상점·가방 썸네일·웹 public 트리와 동일한 **논리 경로** (실제 파일은 [bundledOracleAssetPath]).
/// DB `thumbnail_url`에도 같은 형식을 쓰면 [resolvePublicAssetUrl]이 `assets/oracle/` 로 연결합니다.
String bundledOracleCatalogThumbnailPath(int cardNumber1Based) {
  if (cardNumber1Based < 1 || cardNumber1Based > kBundledOracleCardCount) {
    return 'oracle_cards/oracle(1).png';
  }
  return 'oracle_cards/oracle($cardNumber1Based).png';
}

/// 오라클 카드 번호 1~80 → 상점 별조각 (항목별 난수형 고정가).
int oracleCardShopStarPrice(int cardNumber1Based, [DateTime? dayUtc]) =>
    gggomDailyStarPrice(
      'oracle-card-${cardNumber1Based.toString().padLeft(2, '0')}',
      dayUtc,
    );

/// 덱 설계 기준 한글 제목 80개 (천상·자연·그림자·행동 순).
const List<String> kBundledOracleTitlesKo = [
  '성운',
  '북극성',
  '초승달',
  '보름달',
  '유성우',
  '태양풍',
  '은하의 문',
  '일식',
  '안드로메다',
  '황도대',
  '초신성',
  '블랙홀',
  '화이트홀',
  '오로라',
  '혜성',
  '성단',
  '우주먼지',
  '정지된 궤도',
  '웜홀',
  '창조의 기둥',
  '오래된 뿌리',
  '어린 싹',
  '단비',
  '폭풍우',
  '낙엽',
  '거미줄',
  '바위',
  '산불',
  '꿀벌',
  '고치',
  '연꽃',
  '가뭄',
  '철새',
  '겨울잠',
  '담쟁이덩굴',
  '안개',
  '단풍',
  '샘물',
  '가시나무',
  '대지',
  '깨진 거울',
  '빈 의자',
  '쇠사슬',
  '끝없는 복도',
  '가면',
  '검은 늪',
  '날카로운 혀',
  '가려진 눈',
  '무너진 탑',
  '그림자 인형',
  '차가운 벽',
  '불타는 다리',
  '시든 꽃',
  '바닥 없는 구멍',
  '가시 왕관',
  '굳게 닫힌 문',
  '거미의 포옹',
  '잿더미',
  '거울 속의 낯선 이',
  '그림자의 입맞춤',
  '대장간',
  '갈림길',
  '돛을 올리다',
  '황금 열쇠',
  '첫 발자국',
  '등불을 든 손',
  '수확의 낫',
  '건설자',
  '활시위',
  '빈 그릇',
  '횃불 이어달리기',
  '망치와 정',
  '닻을 내리다',
  '나침반',
  '씨앗 주머니',
  '거친 파도',
  '징검다리',
  '불꽃의 춤',
  '빈 손',
  '축제의 잔',
];

/// 로컬·Supabase 공통: `shop_items` DB에 없어도 앱 번들 오라클 80종을 상점에 노출.
List<ShopItemRow> bundledOracleShopCatalogRows() {
  return List<ShopItemRow>.generate(
    kBundledOracleCardCount,
    (i) {
      final n = i + 1;
      return ShopItemRow(
        id: 'oracle-card-${n.toString().padLeft(2, '0')}',
        name: bundledOracleShopDisplayName(n),
        type: 'oracle_card',
        price: oracleCardShopStarPrice(n),
        thumbnailUrl: bundledOracleCatalogThumbnailPath(n),
        isActive: true,
      );
    },
  );
}

/// [Image.asset] 등 Flutter 번들용 실제 경로. 1~80만 유효.
String? bundledOracleAssetPath(int cardNumber) {
  if (cardNumber < 1 || cardNumber > kBundledOracleCardCount) {
    return null;
  }
  return 'assets/oracle/oracle($cardNumber).png';
}

/// 상점·가방에 표시할 이름.
String bundledOracleShopDisplayName(int cardNumber1Based) {
  if (cardNumber1Based < 1 || cardNumber1Based > kBundledOracleCardCount) {
    return '오라클 카드';
  }
  final title = kBundledOracleTitlesKo[cardNumber1Based - 1];
  return '${cardNumber1Based.toString().padLeft(2, '0')}. $title';
}

/// 상점·가방 ID `oracle-card-01` ~ `oracle-card-80` → 카드 번호 1~80.
int? oracleItemIdToCardNumber(String itemId) {
  final m = RegExp(r'^oracle-card-(\d+)$').firstMatch(itemId);
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}
