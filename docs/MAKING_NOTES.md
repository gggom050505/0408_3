# 공공곰타로덱 — 메이킹 노트 (의도/구조)

이 문서는 앱의 **기획 의도와 구조**를 빠르게 파악하기 위한 요약입니다.  
재현 절차는 `docs/백업노트1.md`를 기준으로 관리합니다.

최종 정리: **2026-04-29**

---

## 1) 한 줄 정의

공공곰타로덱은 **타로·오늘의 타로·피드·채팅·상점·가방·이벤트·간지 달력**을 묶은 Flutter 앱이며, 기본 운영은 **오프라인 번들/로컬 데이터 중심**입니다.

---

## 2) 최근 핵심 변화

### 2-1. 오프닝(스플래시)
- `assets/opening/` 이미지 캐러셀 우선 사용.
- 파일명 인코딩/정렬 안정화로 웹·번들 경로 혼선을 줄임.

관련 파일:
- `lib/config/opening_assets.dart`
- `lib/widgets/splash_screen.dart`

### 2-2. 간지 달력 확장
- 오행 설명 배너(성질/특성/기질) 추가.
- 날짜 탭 시 일진 중심 바텀시트 안내 추가.
- 60갑자 패턴 데이터 분리(`lib/data/*`)로 유지보수성 개선.

관련 파일:
- `lib/widgets/ganji_calendar_tab.dart`
- `lib/data/ganji_sixty_day_patterns.dart`
- `lib/data/five_elements_guide.dart`

### 2-3. 오늘의 타로 UX
- 10칸 배치 후 **한 번에 뒤집기** 버튼 추가.
- 결과 전환 흐름은 기존 완료 조건을 유지.

관련 파일:
- `lib/widgets/today_tarot_screen.dart`

### 2-4. 타로 설명 스위치 영속화
- `카드 설명 보기` 켜기/끄기 상태를 계정별 로컬 저장.
- `타로 탭` / `오늘의 타로`가 같은 설정을 공유.

관련 파일:
- `lib/standalone/local_app_preferences.dart`
- `lib/widgets/tarot_tab.dart`
- `lib/widgets/today_tarot_screen.dart`

---

## 3) 주요 화면/데이터 구조

### 3-1. 화면 허브
- 앱 진입: `lib/main.dart` → `lib/widgets/app_root.dart`
- 홈 탭 관리: `lib/widgets/home_screen.dart`, `lib/widgets/gnb.dart`

### 3-2. 데이터 계층
- 인터페이스: `lib/standalone/data_sources.dart`
- 로컬 구현: `lib/standalone/local_*_repository.dart`
- 앱 UI 설정 저장: `lib/standalone/local_app_preferences.dart`

### 3-3. 문서 뷰어
- 메이킹 노트 화면: `lib/widgets/making_notes_screen.dart`
- 로드 문서: `docs/MAKING_NOTES.md` (현재 문서)

---

## 4) 실행/검증 포인트

- 권장 실행:
  - `flutter run --dart-define=GGGOM_OFFLINE_BUNDLE=true`
- 정적 분석:
  - `dart analyze lib`
- 대표 테스트:
  - `flutter test test/today_tarot_screen_test.dart`
  - `flutter test test/making_notes_screen_test.dart`

---

## 5) 운영 메모

- 오프라인 번들이 기본 전제이며, 외부 URL/배포 연동은 명시 요청 시에만 진행.
- 간지 달력의 사건 해설은 역사 연간 명칭을 “패턴 참고”로 활용하는 성격임.
- 상세 재현 순서/체크리스트는 항상 `docs/백업노트1.md`를 우선 참고.
