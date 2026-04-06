# 공공곰타로덱 — 메이킹 노트

Flutter 클라이언트의 **기획 의도·구현 요약**을 한곳에 정리한 문서입니다. (버전·기능은 시점에 따라 달라질 수 있으니 코드와 `pubspec.yaml`을 최종 기준으로 보시면 됩니다.)

---

## 1. 한 줄 정의

**타로 뽑기·결과 캡처·피드·채팅·상점·가방·이벤트·출석**을 한 앱에서 제공하고, **같은 코드베이스**로 **서버 연동(Supabase)** 빌드와 **오프라인·베타 번들(로컬 JSON)** 빌드를 모두 지원합니다.

---

## 2. 앱 특징 (사용자 관점)

| 영역 | 내용 |
|------|------|
| **타로** | 덱·매트·카드 뒷면·슬롯 테두리 장착 반영, 스프레드/결과 UI, 캡처·공유 흐름 |
| **오라클 / 한국전통 메이저** | 번들 에셋·상점·가방·수집 화면 연동 |
| **게시물(피드)** | Supabase 또는 로컬 피드 레포지토리; 이미지 포스트는 캡처 PNG를 **`FeedPostCapture`**로 그대로 표시 |
| **채팅** | 연동 빌드: Supabase 채팅 / 오프라인 빌드: 기기 저장 로컬 채팅 |
| **상점·가방** | 별조각 통화, 구매·장착, 이모티콘(팩/단품) |
| **이벤트** | 공지 카드 목록 (서버 `events` 또는 로컬 데모 공지) |
| **출석** | 일일 체크, 별조각 + 「행운이 가득한 날」상점 품목(별도 주기) |
| **깜짝 선물** | 상점 탭 동기화 시 2~7일 무작위 간격 유료 **미보유** 품목 1건 무료 제안 |
| **선물·지급 중복 방지** | 깜짝 선물·출석 행운·스타터 지급 시 `(itemId + itemType)` 기준으로 겹침 방지; 출석 행운 후보에서 **깜짝 선물 예약(pending)** 품목 제외 |
| **⭐1 / ⭐2 일일 한도** | 별조각 **1**짜리 상품은 UTC 기준 **하루 1건**; **2**짜리는 그날 **2~3건** 상한(날짜별 고정). 로컬 `user_state`·Supabase 보조 저장 |
| **로그인** | Google OAuth(Supabase), 게스트, **이 기기 전용 로컬 계정** |
| **베타·별조각** | 오프라인(**Supabase 미연동**) 빌드는 GNB·상점에서 **별조각·광고(시뮬)** 메뉴 기본 표시; 연동 빌드는 `AD_REWARD_TEST_MODE`일 때만. **GNB ⭐** = `StarChargeSheet`(카카오 안내·패키지 복사) |
| **피드 타로 이미지** | 캡처 스프레드: `feed_post_capture.dart` — 뒤집기·분할 없이 **업로드한 이미지 전체** 표시 |
| **가방 덱** | 한국전통 메이저 **덱** 선택 시 제목 `(선택)`, 버튼 **취소**로 기본 덱 복귀; 일반 덱은 `(장착)` 유지 |

---

## 3. 아키텍처 · 구현 개요

### 3.1 실행 모드 분기

- **`AppConfig.supabaseEnabled`**: `main`에서 Supabase 초기화에 성공하면 `true`. URL·anon 키는 기본값으로 `config/gggom_site_public_catalog.dart` 프로덕션을 쓰고, `GGGOM_OFFLINE_BUNDLE=true`이면 초기화를 건너뜁니다.
- **로컬 계정·게스트**: `LocalAccountStore`, `HomeScreen`에서 `userId`·데이터 소스 선택이 갈립니다.
- **단일 진입점**: `main.dart`에서 테마·`MaterialApp`·`AppRoot` 연결; `AppRoot`가 스플래시 → 로그인/홈 라우팅을 담당합니다.

### 3.2 데이터 소스 추상화

- `lib/standalone/data_sources.dart`에 **`FeedDataSource`**, **`ShopDataSource`**, **`EmoticonDataSource`**, **`EventDataSource`**, **`AttendanceDataSource`** 등이 정의되어 있습니다.
- **Supabase 구현**: `lib/repositories/*.dart` (`ShopRepository`, `FeedRepository`, …).
- **로컬 구현**: `lib/standalone/local_*_repository.dart` — JSON 파일·SharedPreferences(웹) 등 `local_json_store` 계층 사용.

이 덕분에 `HomeScreen`·탭 위젯은 **같은 인터페이스**로 두 빌드를 모두 태울 수 있습니다.

### 3.3 상점·경제 핵심 로직

- **카탈로그**: `ShopItemRow`; 로컬은 `local_shop_catalog_v1.json` + 번들 행 병합(뒷면·슬롯·오라클·한국 메이저 등).
- **유저 상태**: 프로필(별조각·장착 ID), `user_items`에 상당하는 보유 목록, 이모 보유 집합; 로컬은 `local_shop_user_state_v1_<user>.json` 등.
- **깜짝 선물**: `SurpriseGiftState` / `SurpriseGiftSync` — 활성·유료·미보유·지정 타입만 후보; 주기 **2~7일**; 로컬은 유저 JSON 키 `surprise_gift`, Supabase 모드는 `local_surprise_gift_v1_<user>.json`.
- **출석 「행운」**: `AttendanceLuckyState` / `AttendanceLuckySync` — **1~3일** 간격; 동일한 지급 타입군; 로컬 `attendance_lucky` / 서버 모드 `local_attendance_lucky_v1_<user>.json`; DB insert 실패 시 쿨다운 소모 없음. **`doNotGrantKeys`**: 깜짝 선물 `pending`과 동일 품목이면 출석 행운 후보에서 제외.
- **보유 키·중복 제거**: `shop_models.dart`의 `gggomShopOwnedKey`, `gggomDedupeOwnedItems` — 가방/DB에 (id·타입) 중복 행이 있어도 목록상 한 건; `ensureDefaultUserItems`·`buyItem`은 **타입까지** 일치할 때 보유로 판단.
- **가격 일변동**: `config/shop_random_prices.dart` — `gggomDailyStarPrice`(오라클·한국 메이저 조각·번들 이모 등), `gggomStableStarPrice`(해시); 카탈로그 로드 시 `suggestedStarPriceForShopItem`과 로컬 정규화가 맞춤.
- **⭐1·⭐2 구매 일일 제한**: `gggomCanPurchaseStarOnePricedItemToday`, `gggomDailyStarTwoPurchaseCapForUtcDay` 등; 로컬 `star_one_purchase_utc_ymd` / ⭐2 카운트; Supabase는 `lib/standalone/star_one_purchase_daily.dart` 연동.
- **광고 시뮬 보상**: `ShopDataSource.grantAdRewardStars` / `widgets/ad_reward_sheet.dart`; `AppConfig.showBetaStarAdRewardMenu` (= 연동 끔 또는 `AD_REWARD_TEST_MODE`). 재시청 쿨타임 `AppConfig.adRewardCooldownMinutes`(기본 5분), 로컬 `local_app_preferences`에 계정별 저장.

### 3.4 UI · 네비게이션

- **홈**: `HomeScreen` — 상단 `Gnb`(출석·**별조각 충전**·**광고(베타)**·저장하기·**메이킹 노트**(번들 `docs/MAKING_NOTES.md`) 등; 좁은 폭에서는 아이콘 묶음이 **가로 스크롤**됩니다.
- **상점**: 별조각 패널 아래 베타 시 **「별조각·광고」** 배너로도 시트 진입(`ShopTab.onBetaAdReward`).
- **탭**: 타로 / 피드 / 채팅 / 상점 / 가방 / 이벤트 — `MainTab` enum.
- **애니메이션**: `lib/widgets/app_motion.dart` — `AppearAnimation`, `StaggerItem`, 탭 전환 헬퍼, 커스텀 페이지 전환(`GgomFadeUpwardsPageTransitionsBuilder`); 테마에 `InkSparkle` 스플래시 등. 상점·가방·로그인·이벤트 헤더·모달 등에 스태거/등장 연출 적용.
- **스플래시**: `assets/opening/` 캐러셀 또는 기본 1프레임 후 `AppRoot` 진행.

### 3.5 기타 모듈

- **타로 세션 저장·복원**: standalone 타로 세션 유틸, 워크스페이스 JSON 미러(개발용 `GGGOM_PROJECT_ROOT` 등).
- **이모티콘**: 웹 공개 카탈로그 REST + 오프라인 매니페스트; `AdaptiveNetworkOrAssetImage`로 경로 통일.
- **데스크톱**: `window_manager`, `desktop_init` 등 창 옵션.

---

## 4. 빌드 · 설정 (자주 쓰는 dart-define)

| 키 | 용도 |
|----|------|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | 비우면 카탈로그 기본(Supabase) 사용; 스테이징만 바꿀 때 지정 |
| `GGGOM_OFFLINE_BUNDLE` | `true`/`1`이면 Supabase 미초기화(오프라인 번들) |
| `ASSET_ORIGIN` | 카드 등 원격 에셋 베이스 URL |
| `OAUTH_REDIRECT_URL` | OAuth 복귀 URL |
| `AD_REWARD_TEST_MODE` | Supabase **연동** 빌드에서만 광고 시뮬 메뉴 강제 표시(`true`/`1`) |
| `AD_REWARD_STARS` | 시뮬 보상 별조각 개수(기본 3) |
| *(암묵)* | `SUPABASE` 없이 실행 시 `showBetaStarAdRewardMenu`가 켜져 GNB·상점에 시뮬 메뉴 표시 |
| `GGGOM_PROJECT_ROOT` | 로컬 상태 → `assets/local_dev_state/` 미러 |

자세한 실행 예는 `lib/main.dart` 상단 주석을 참고하면 됩니다.

---

## 5. 디렉터리 지도 (요약)

```
lib/
  main.dart              # 앱·테마·진입
  widgets/               # 화면·탭·모달 (home_screen, tarot_tab, shop_tab, feed_post_capture, …)
  standalone/            # 오프라인 레포·동기화·JSON·경로 유틸
  repositories/          # Supabase 어댑터
  models/                # DTO (shop, feed, event, surprise_gift, attendance_lucky, …)
  config/                # 카탈로그·에셋·가격·게이트
  theme/                 # 색·그라데이션
  services/              # 로컬 세션 등
```

---

## 6. 운영·문서 연계

- 오프라인 편집: `docs/OFFLINE_EDITING.md`
- 단독 실행(베타 번들): `docs/STANDALONE_INSTALL.md`
- Supabase **이벤트 공지**는 DB `events`와 `EventRepository` 스키마에 맞게 등록해야 로컬 데모와 동일한 정책을 서버에서도 안내할 수 있습니다.

---

## 7. 변경 시 추천 체크리스트

1. `ShopDataSource` / `FeedDataSource` 등 **계약 변경** 시 로컬·Supabase **양쪽** 구현 및 위젯 호출부 확인  
2. 경제 규칙(깜짝 선물·출석 행운·시세·⭐1/⭐2 일일 한도)은 **상태 JSON 스키마**와 마이그레이션 주의  
3. 새 탭·전환 추가 시 **`AnimatedSwitcher`의 Key**와 `app_motion` 트랜지션 일관성 유지  
4. 일별 가격 키(`gggomDailyStarPrice`)·티어 구간을 바꿀 경우 `test/shop_daily_price_test.dart`·이모/한국 메이저 가격 테스트 재확인  

---

## 8. 테스트 (요약)

| 경로 | 내용 |
|------|------|
| `test/shop_daily_price_test.dart` | 일별 시세·재현성 |
| `test/star_one_daily_limit_test.dart` | ⭐1 일일 1건·로컬 `buyItem` |
| `test/gift_no_duplicate_test.dart` | 보유 dedupe·출석 `doNotGrantKeys` |
| `test/beta_ad_reward_menu_test.dart` | `showBetaStarAdRewardMenu` |
| `test/feed_sort_test.dart` 등 | 피드 모델·정렬 |

로컬 상점 통합 테스트는 `path_provider` 모킹이 필요한 경우가 많음(`shop_admin_smoke_test.dart`, `star_one_daily_limit_test.dart` 참고).

---

*이 문서는 “메이킹 노트” 성격으로 유지보수 시 빠르게 맥락을 잡기 위한 것입니다. 세부 스펙은 이슈·PR·코드 주석을 함께 참고해 주세요.*
