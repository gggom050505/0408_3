/// 내부 해시 — [gggomStableStarPrice] / [gggomDailyStarPrice] 공통.
int gggomStableStarPrice(
  String key, {
  int min = 1,
  int max = 10,
}) {
  assert(min <= max);
  var h = 2166136261;
  for (var i = 0; i < key.length; i++) {
    h ^= key.codeUnitAt(i);
    h = (h * 16777619) & 0x7FFFFFFF;
  }
  final span = max - min + 1;
  return min + (h % span);
}

/// UTC 기준 날짜만 (자정 기준 일 단위 가격 변동용).
DateTime gggomUtcDateOnly([DateTime? utc]) {
  final d = utc ?? DateTime.now().toUtc();
  return DateTime.utc(d.year, d.month, d.day);
}

/// 상점 단가 — **매일(UTC 날짜)** 바뀜. 같은 날·같은 품목은 항상 동일(해시 기반).
///
/// 품목마다 그날 **1~100** 결정론 난수를 한 번 뽑고:
/// - `1` → 별조각 **1**
/// - `2`~`5` → **2**
/// - `6`~`15` → **3**
/// - `16`~`100` → **4**~**10** (별도 결정론 난수)
///
/// [dayUtc]가 null이면 **오늘 UTC** 날짜를 사용합니다.
int gggomDailyStarPrice(String key, [DateTime? dayUtc]) {
  final d = gggomUtcDateOnly(dayUtc);
  final salt =
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final tier = gggomStableStarPrice('$salt|tier|$key', min: 1, max: 100);
  if (tier == 1) {
    return 1;
  }
  if (tier <= 5) {
    return 2;
  }
  if (tier <= 15) {
    return 3;
  }
  return gggomStableStarPrice('$salt|tier4_10|$key', min: 4, max: 10);
}

/// UTC `yyyy-mm-dd` (⭐1·⭐2 일일 구매 한도).
String gggomTodayUtcYmdKey() {
  final d = gggomUtcDateOnly();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// ⭐1 — 같은 UTC 날에 이미 한 건이면 `false`.
bool gggomCanPurchaseStarOnePricedItemToday(String? lastPurchaseUtcYmd) {
  if (lastPurchaseUtcYmd == null || lastPurchaseUtcYmd.isEmpty) {
    return true;
  }
  return lastPurchaseUtcYmd != gggomTodayUtcYmdKey();
}

/// ⭐2 — 그 UTC 날짜마다 허용 **2 또는 3건** (날짜별 고정).
int gggomDailyStarTwoPurchaseCapForUtcDay([DateTime? dayUtc]) {
  final d = gggomUtcDateOnly(dayUtc);
  final salt =
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  return 2 + gggomStableStarPrice('star2_daily_cap|$salt', min: 0, max: 1);
}

/// ⭐2 — 오늘(UTC) [storedCount]건으로 상한 도달 시 `false`.
bool gggomCanPurchaseStarTwoPricedItemToday({
  required String? storedYmd,
  required int storedCount,
}) {
  final today = gggomTodayUtcYmdKey();
  final cap = gggomDailyStarTwoPurchaseCapForUtcDay();
  if (storedYmd == null || storedYmd.isEmpty || storedYmd != today) {
    return true;
  }
  return storedCount < cap;
}

/// ⭐2 구매 1건 성공 후 저장할 `(utc_ymd, count)`.
({String ymd, int count}) gggomNextStarTwoPurchaseState({
  required String? storedYmd,
  required int storedCount,
}) {
  final today = gggomTodayUtcYmdKey();
  if (storedYmd == null || storedYmd.isEmpty || storedYmd != today) {
    return (ymd: today, count: 1);
  }
  return (ymd: storedYmd, count: storedCount + 1);
}
