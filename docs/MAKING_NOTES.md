# 공공곰타로덱 — 메이킹 노트 (배경/의도 중심)

Flutter 클라이언트의 **기획 의도·구현 요약**을 한곳에 정리한 문서입니다. (버전·기능은 시점에 따라 달라질 수 있으니 코드와 `pubspec.yaml`을 최종 기준으로 보시면 됩니다.)

재현 절차(실행 순서/검증 포인트)는 `docs/백업노트1.md`를 기준으로 관리합니다.

---

## 1. 한 줄 정의

**타로 뽑기·결과 캡처·피드·채팅·상점·가방·이벤트·출석**을 한 앱에서 제공하며, 데이터는 **오프라인·베타 번들(로컬 JSON·기기 저장)** 중심입니다.

---

## 2. 앱 특징 (사용자 관점)

| 영역 | 내용 |
|------|------|
| **타로** | 덱·매트·카드 뒷면·슬롯 테두리 장착 반영, 스프레드/결과 UI, 캡처·공유 흐름 |
| **오늘의 타로** | GNB **「오늘의 타로」** 탭: 날짜 시드 키워드, 106장 덱에서 10장을 5×2 슬롯에 받고 한 장씩 뒤집어 점수·결과 정리. 완료 후 **「게시하기」/「게시 안함」**으로 피드 반영 여부 선택(자동 게시 없음). **「오늘의 게시」** 탭은 `#오늘의타로` 태그 글만 모아 보기(정렬·타로점수순 등). 상단 **다시 뽑기**로 로컬 완료 표시를 지우고 같은 날 다시 진행 가능. |
| **오라클 / 한국전통 메이저** | 번들 에셋·상점·가방·수집 화면 연동 |
| **게시물(피드)** | 로컬 피드 저장소; 이미지 포스트는 캡처 PNG를 **`FeedPostCapture`**로 그대로 표시. 오늘의 타로 글은 본문 `합계 N점`으로 **타로점수순** 정렬에 쓰임 |
| **채팅** | 기기 저장 로컬 채팅 |
| **상점·가방** | 별조각 통화, 구매·장착, 이모티콘(팩/단품) |
| **이벤트** | 공지 카드 목록 (앱에 포함된 로컬·베타 공지) |
| **출석** | 일일 체크, 별조각 + 「행운이 가득한 날」상점 품목(별도 주기) |
| **깜짝 선물** | 상점 탭 동기화 시 2~7일 무작위 간격 유료 **미보유** 품목 1건 무료 제안 |
| **선물·지급 중복 방지** | 깜짝 선물·출석 행운·스타터 지급 시 `(itemId + itemType)` 기준으로 겹침 방지; 출석 행운 후보에서 **깜짝 선물 예약(pending)** 품목 제외 |
| **⭐1 / ⭐2 일일 한도** | 별조각 **1**짜리 상품은 UTC 기준 **하루 1건**; **2**짜리는 그날 **2~3건** 상한(날짜별 고정). 로컬 `user_state` |
| **로그인** | 게스트, **이 기기 전용 로컬 계정** |
| **베타·별조각** | GNB·상점에서 **별조각·광고(시뮬)** 메뉴 표시(`AppConfig.showBetaStarAdRewardMenu` 등). **GNB ⭐** = `StarChargeSheet`(카카오 안내·패키지 복사) |
| **피드 타로 이미지** | 캡처 스프레드: `feed_post_capture.dart` — 뒤집기·분할 없이 **업로드한 이미지 전체** 표시 |
| **가방 덱** | 한국전통 메이저 **덱** 선택 시 제목 `(선택)`, 버튼 **취소**로 기본 덱 복귀; 일반 덱은 `(장착)` 유지 |

---

## 3. 아키텍처 · 구현 개요

### 3.1 실행 모드 분기

- **`AppConfig.useOfflineBundleOnly`**: `GGGOM_OFFLINE_BUNDLE=true`이면 원격 런타임 JSON 로드를 생략합니다.
- **로컬 계정·게스트**: `LocalAccountStore`, `HomeScreen`에서 `userId`·저장소가 연결됩니다.
- **단일 진입점**: `main.dart`에서 테마·`MaterialApp`·`AppRoot` 연결; `AppRoot`가 스플래시 → 로그인/홈 라우팅을 담당합니다.

### 3.2 데이터 소스 추상화

- `lib/standalone/data_sources.dart`에 **`FeedDataSource`**, **`ShopDataSource`**, **`EmoticonDataSource`**, **`EventDataSource`**, **`AttendanceDataSource`** 등이 정의되어 있습니다.
- **로컬 구현**: `lib/standalone/local_*_repository.dart` — JSON 파일·SharedPreferences(웹) 등 `local_json_store` 계층 사용.

### 3.3 상점·경제 핵심 로직

- **카탈로그**: `ShopItemRow`; 로컬은 `local_shop_catalog_v1.json` + 번들 행 병합(뒷면·슬롯·오라클·한국 메이저 등).
- **유저 상태**: 프로필(별조각·장착 ID), `user_items`에 상당하는 보유 목록, 이모 보유 집합; 로컬은 `local_shop_user_state_v1_<user>.json` 등.
- **깜짝 선물**: `SurpriseGiftState` / `SurpriseGiftSync` — 활성·유료·미보유·지정 타입만 후보; 주기 **2~7일**; 유저 JSON 키 `surprise_gift` / `local_surprise_gift_v1_<user>.json`.
- **출석 「행운」**: `AttendanceLuckyState` / `AttendanceLuckySync` — **1~3일** 간격; 동일한 지급 타입군; 로컬 `attendance_lucky` / `local_attendance_lucky_v1_<user>.json`; 지급 실패 시 쿨다운 소모 없음. **`doNotGrantKeys`**: 깜짝 선물 `pending`과 동일 품목이면 출석 행운 후보에서 제외.
- **보유 키·중복 제거**: `shop_models.dart`의 `gggomShopOwnedKey`, `gggomDedupeOwnedItems` — 가방/DB에 (id·타입) 중복 행이 있어도 목록상 한 건; `ensureDefaultUserItems`·`buyItem`은 **타입까지** 일치할 때 보유로 판단.
- **가격 일변동**: `config/shop_random_prices.dart` — `gggomDailyStarPrice`(오라클·한국 메이저 조각·번들 이모 등), `gggomStableStarPrice`(해시); 카탈로그 로드 시 `suggestedStarPriceForShopItem`과 로컬 정규화가 맞춤.
- **⭐1·⭐2 구매 일일 제한**: `gggomCanPurchaseStarOnePricedItemToday`, `gggomDailyStarTwoPurchaseCapForUtcDay` 등; 로컬 `star_one_purchase_utc_ymd` / ⭐2 카운트(`lib/standalone/star_one_purchase_daily.dart`).
- **광고 시뮬 보상**: `ShopDataSource.grantAdRewardStars` / `widgets/ad_reward_sheet.dart`; `AppConfig.showBetaStarAdRewardMenu`·`AD_REWARD_TEST_MODE`. 시청 완료 시 별조각 **기본 3개**( `AD_REWARD_STARS` 로 변경 가능). 재시청 쿨타임 `AppConfig.adRewardCooldownMinutes`(기본 10분), 로컬 `local_app_preferences`에 계정별 저장.

### 3.4 UI · 네비게이션

- **홈**: `HomeScreen` — 상단 `Gnb`(출석·**별조각 충전**·**광고(베타)**·저장하기·**메이킹 노트**(번들 `docs/MAKING_NOTES.md`) 등; 좁은 폭에서는 아이콘 묶음이 **가로 스크롤**됩니다.
- **상점**: 별조각 패널 아래 베타 시 **「별조각·광고」** 배너로도 시트 진입(`ShopTab.onBetaAdReward`).
- **탭(GNB)**: **타로 / 오늘의 타로 / 오늘의 게시 / 게시물 / 채팅 / 상점 / 가방 / 이벤트** — `MainTab` enum(8칸; 가로가 좁으면 탭 줄 **가로 스크롤**). 마지막으로 선택한 탭은 `LocalAppPreferences`에 저장되어 복원됩니다.
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
| `GGGOM_OFFLINE_BUNDLE` | `true`/`1`이면 원격 런타임 설정 생략(오프라인 번들) |
| `EMOTICON_CATALOG_URL`, `EMOTICON_CATALOG_ANON_KEY` | (선택) 이모티콘 카탈로그 PostgREST 호환 API |
| `ASSET_ORIGIN` | 카드 등 원격 에셋 베이스 URL |
| `AD_REWARD_TEST_MODE` | 광고 시뮬 메뉴 강제 표시(`true`/`1`) |
| `AD_REWARD_STARS` | 시뮬 보상 별조각 개수(기본 3) |
| `GGGOM_PROJECT_ROOT` | 로컬 상태 → `assets/local_dev_state/` 미러 |

자세한 실행 예는 `lib/main.dart` 상단 주석을 참고하면 됩니다.

---

## 5. 디렉터리 지도 (요약)

```
lib/
  main.dart              # 앱·테마·진입
  widgets/               # 화면·탭·모달 (home_screen, tarot_tab, shop_tab, feed_post_capture, …)
  standalone/            # 로컬 레포·동기화·JSON·경로 유틸
  models/                # DTO (shop, feed, event, surprise_gift, attendance_lucky, …)
  config/                # 카탈로그·에셋·가격·게이트
  theme/                 # 색·그라데이션
  services/              # 로컬 세션 등
```

---

## 6. 운영·문서 연계

- 오프라인 편집: `docs/OFFLINE_EDITING.md`
- 단독 실행(베타 번들): `docs/STANDALONE_INSTALL.md`
---

## 6-1. 최근 추가/보완 (2026-04-09, 요약)

이번 작업에서 사용자 요청으로 반영된 핵심 변경 요약입니다.  
세부 재현 절차는 `docs/백업노트1.md`를 따릅니다.

### A) 오늘의 타로 모바일/확대 안정화

- 파일: `lib/widgets/today_tarot_screen.dart`
- 변경:
  - 인트로/완료 차단 화면을 스크롤 가능한 레이아웃으로 변경해 작은 모바일 화면에서도 버튼이 잘리지 않게 보완.
  - 카드 뒤집기 후 큰 보기 다이얼로그를 `카드 고정 영역 + 설명 스크롤 영역`으로 분리해 카드 전체가 화면 안에 보이게 조정.

### B) 카드/미디어 URL 로딩 보강

- 파일:
  - `lib/data/card_themes.dart`
  - `lib/widgets/adaptive_network_asset_image.dart`
  - `lib/widgets/ad_reward_sheet.dart`
- 변경:
  - `assets/...` 경로도 웹에서 `assetOrigin` 절대 URL 우선 로드.
  - 네트워크 이미지 실패 시 `Image.asset` 폴백 추가.
  - 광고 영상 로딩은 `assetOrigin URL -> 현재 오리진 URL -> asset -> fallback URL` 순서로 재시도.

### C) 상점 가격 정책 조정(최종)

- 한국전통 메이저 카드: `7~9`
  - `lib/config/korea_major_card_catalog.dart`
- 카드 뒷면: `3~5`
  - `lib/data/card_back_shop_assets.dart`
  - `lib/standalone/local_shop_repository.dart` 가격 정규화 포함
- 이모티콘: `1~4` + `3/4` 고가중치
  - `lib/config/bundle_emoticon_catalog.dart`
  - 가중치: `1(10%) / 2(15%) / 3(35%) / 4(40%)`

### D) 개인 상점 「내가 팔기」 확장

- 파일:
  - `lib/widgets/personal_shop_screen.dart`
  - `lib/standalone/local_peer_shop_repository.dart`
- 변경:
  - 등록 대상이 보유품 기준에서 **상점 카탈로그 전체 품목 + 번들 이모티콘 전체**로 확장.
  - 드롭다운은 타입 우선순위 정렬 + `[타입]` 라벨 표시로 탐색성 개선.
  - 로컬 개인상점 등록 시 판매자 보유 검증 없이 등록 허용(중복 진열은 기존처럼 차단).

### E) 선물/지급 정책 보완

- 파일:
  - `lib/standalone/local_shop_repository.dart`
  - `lib/config/app_config.dart`
- 변경:
  - 로그인 시 환영 선물 자동 지급 로직 보강: `⭐20 + 이모7 + 오라클8`.
  - 현재 정책: **로그인 세션당 1회**, 로그아웃 후 재로그인 시 다시 지급.
  - dev 선물팩 계정 제한 define 추가:
    - `GGGOM_DEV_GRANT_USER_REQUEST_PACK_ONLY_USER_ID=<계정ID>`

---

## 6-2. 최근 추가/보완 (2026-04-17, 요약)

### F) 오늘 접속자수 표시를 Supabase 의존 없이 유지

- 파일:
  - `lib/services/daily_visitor_counter.dart`
  - `lib/widgets/home_screen.dart`
- 배경:
  - 배포/개발 환경에서 Supabase URL·키 미설정, RPC 오류, 일시 네트워크 장애가 있을 때
    GNB의 `오늘 접속` 라벨이 사라지거나 미표시되는 문제가 반복될 수 있었습니다.
- 설계 의도:
  - **가능하면 Supabase 집계값을 우선 사용**하되,
  - 불가능한 경우에도 UX를 끊지 않기 위해 **기기 로컬 카운트로 자동 폴백**합니다.
- 동작 원칙:
  - Supabase RPC 응답 파싱 성공: 서버 집계값 표시
  - Supabase 미설정/실패/응답 비정상: 로컬 카운트(`SharedPreferences`) 표시
  - `HomeScreen`은 환경과 무관하게 항상 방문자 라벨을 렌더링
- 한계/주의:
  - 로컬 폴백은 **기기 기준 일일 방문 횟수**이므로, 전체 사용자 공용 DAU와 의미가 다릅니다.
  - 운영 통계(실제 공용 접속자수)가 필요하면 서버 집계(Supabase 등)를 유지해야 합니다.

---

## 6-3. 이벤트 보완 방향 (2026-04-17, 기획 메모)

이벤트 탭은 **공지·기간 한정 보상**을 다루기 쉬운 곳이라, 아래를 기준으로 확장하면 운영 실수와 사용자 혼란을 줄일 수 있습니다.

### A) 노출·기간 정책

- 이벤트 카드에 **시작일·종료일·기준 타임존(KST)** 를 명시한다.
- 종료된 이벤트는 **목록에서 숨기거나** `종료` 뱃지로 구분해 혼동을 막는다.

### B) 보상·중복 방지

- 보상 수령 키를 표준화한다. 예: `event_id + reward_id + user_id + date_key`(또는 이벤트별 고유 키).
- 지급 API/저장소는 **idempotent** 하게 설계한다. 성공·실패·이미 수령을 사용자에게 구분해 안내한다.

### C) 실패·복구 UX

- 네트워크/저장 실패 시 **재시도** 버튼과 간단한 원인 안내를 둔다.
- “수령 완료” 상태는 로컬에 안정적으로 기록하고, 재실행 후에도 일관되게 보인다.

### D) 운영 플래그

- `이벤트 강제 노출`, `테스트 이벤트`, `이벤트 전체 비활성` 등은 `AppConfig` dart-define 으로 분리해 배포 시 실수를 줄인다.

### E) 콘텐츠 관리

- 문구·배너는 가능하면 **번들 JSON/가이드 파일**로 두고 코드 수정 없이 교체할 수 있게 한다. (현재: `lib/standalone/local_event_repository.dart`, `lib/config/bundled_event_guides.dart` 등과 연계)

### F) 관측·테스트

- 노출·상세 진입·보상 클릭·지급 성공/실패에 대한 최소 로그(또는 디버그 플래그)를 두면 이후 개선 근거가 된다.
- 기간 경계(KST 자정), 중복 수령, 재시도, 오프라인 모드에 대한 테스트를 추가하는 것을 권장한다.

---

## 7. 변경 시 추천 체크리스트

1. `ShopDataSource` / `FeedDataSource` 등 **계약 변경** 시 `local_*_repository` 및 위젯 호출부 확인  
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
| `test/feed_sort_test.dart` 등 | 피드 모델·정렬·`parseTodayTarotTotalScoreFromPostContent` |
| `test/today_tarot_screen_test.dart` | 오늘의 타로: 인트로·뽑기·설명서·다시 뽑기·차단 UI(테스트 전용 `debugForceBlockedGateForTest`) |
| `test/today_tarot_keyword_test.dart` · `test/today_tarot_deck_test.dart` | 키워드 시드·덱 구성 |

로컬 상점 통합 테스트는 `path_provider` 모킹이 필요한 경우가 많음(`star_one_daily_limit_test.dart` 참고). 오늘의 타로 화면 테스트는 prefs 경로가 막히지 않도록 `setUpAll`에서 `getApplicationSupportDirectory` 등을 목 처리합니다.

---

*이 문서는 “메이킹 노트” 성격으로 유지보수 시 빠르게 맥락을 잡기 위한 것입니다. 세부 스펙은 이슈·PR·코드 주석을 함께 참고해 주세요.*
