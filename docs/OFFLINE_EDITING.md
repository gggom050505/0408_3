# 오프라인에서 수정·보완하기 (도움말)

코드를 깊이 몰라도, **문구·색·이미지**는 이 가이드대로 손볼 수 있어요. 앱은 **로컬 저장**으로 타로·오라클·캡처·게스트·로컬 계정까지 돌아갑니다.

---

## 1. 준비 (처음 한 번)

| 상황 | 할 일 |
|------|--------|
| PC에 Flutter 설치됨 | 프로젝트 폴더에서 터미널 열기 |
| 인터넷 **있을 때** 한 번 | `flutter pub get` (패키지 받기). 이후에는 **오프라인에서도** 대부분 실행 가능 |
| Cursor / VS Code | **실행·디버그**에서 **「공공곰타로덱: 오프라인·게스트」** 선택 (`.vscode/launch.json`) |

**주의:** 맨 처음 `pub get`이나 Flutter SDK 업데이트는 네트워크가 필요할 수 있어요.

---

## 2. 실행 — 서버 없이

- **`GGGOM_OFFLINE_BUNDLE=true`** 로 빌드·실행하면 **원격 런타임 설정 로드를 생략**하고 번들·로컬 JSON 위주로 동작합니다.
- Cursor/VS Code에서는 **「공공곰타로덱: 오프라인·게스트」** 구성이 위 define을 넣도록 설정돼 있습니다.
- 게시물·상점·가방·이벤트·출석·채팅 탭도 **베타(로컬) 데이터로 동작**합니다(데이터는 이 기기 안에서만).
- 로그인 화면 → **「로그인 없이 둘러보기」** → 전 탭 확인 가능.

자세한 설명: [STANDALONE_INSTALL.md](STANDALONE_INSTALL.md)

**Windows 터미널 예 (완전 오프라인 번들):**

```powershell
cd 프로젝트\gggom0505_0403
flutter run -d windows --dart-define=GGGOM_OFFLINE_BUNDLE=true
```

웹(Chrome)만 로컬에서 볼 때:

```powershell
flutter run -d chrome --dart-define=GGGOM_OFFLINE_BUNDLE=true
```

---

## 3. 자주 고치는 곳

| 바꾸고 싶은 것 | 파일 / 폴더 |
|----------------|-------------|
| 전체 색감 | `lib/theme/app_colors.dart` |
| 로그인 화면 문구 | `lib/widgets/login_screen.dart` |
| 상단 탭 이름 | `lib/widgets/gnb.dart` |
| 타로 버튼·안내 문구 | `lib/widgets/tarot_tab.dart` |
| 스플래시 | `lib/widgets/splash_screen.dart`, `lib/config/gggom_offline_landing.dart` |
| 카드·오라클 그림 | `assets/www_gggom/cards/`, `assets/www_gggom/oracle_cards/` |

이미지 교체 후 앱 **완전 재시작**(핫 리로드만으로 안 될 수 있음).

---

## 4. 저장 후 확인

```powershell
dart analyze
```

---

## 5. 동업자에게 넘길 때

- 수정한 **파일 목록** + **스크린샷/녹화**

막히면 [OWNER_WORKFLOW.md](OWNER_WORKFLOW.md) 참고.
