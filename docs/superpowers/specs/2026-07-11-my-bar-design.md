# My Bar — 메뉴바 아이콘 숨김 앱 설계 (v1)

날짜: 2026-07-11
상태: 승인됨 (사용자 리뷰 완료 전)
참조 프로젝트: `/Users/hyunwookim/Dev/apps/my-window-manager` (메뉴 레이아웃 · 정보 메뉴 · 버전관리 · 배포 · 서명 방식을 그대로 따른다)

## 1. 개요

macOS 메뉴바(상태 막대)의 아이콘을 "항상 보임 / 숨김 / 항상 숨김" 영역으로 나누고,
버튼·단축키로 노출/숨김을 토글하는 메뉴바 상주 앱. Hidden Bar와 같은
**NSStatusItem 길이 트릭** 기반으로 v1을 만들고, v2에서 ScreenCaptureKit 캡처
팝업(Ice 방식)을 얹는다.

### v1 범위

1. 메뉴바 아이콘 영역 구분: 항상 보임 / 숨김 (+ 옵션으로 항상 숨김 2단 영역)
2. 메인 아이콘 클릭·글로벌 단축키로 노출/숨김 토글
3. ⌘드래그로 아이콘 영역 이동 (macOS 표준 동작 + 온보딩 안내)
4. 노출/숨김 = 실제 메뉴바에서 펼침/접힘 (기능 4의 v1 구현; 팝업 패널은 v2)
5. 자동 재숨김 타이머
6. 노치 감지 + 안내
7. window-manager와 동일한: 설정 창 레이아웃, 정보 메뉴, 자체 업데이트,
   버전관리(`make bump-*`), 배포(`make publish`), 자체 서명

### 비범위 (v2+ 백로그, §10)

ScreenCaptureKit 캡처 팝업, 호버/스크롤 펼치기, 앱 트리거, 프로필 등.

## 2. 기술 접근

채택: **NSStatusItem 길이 트릭 (Hidden Bar/Dozer 방식)**

- 구분자 역할의 NSStatusItem 길이를 큰 값(10000)으로 늘리면 그 왼쪽의 다른 앱
  아이콘들이 화면 밖으로 밀려나 보이지 않게 된다. 길이를 원복하면 다시 나타난다.
- 공개 API만 사용, 특수 권한(Accessibility/Screen Recording) 불필요.
- 트레이드오프: 숨김은 "밀어내기"이므로 숨겨진 앱 아이콘도 계속 실행 중이며,
  펼칠 때 아이콘들이 밀리는 모습이 잠깐 보일 수 있다. Hidden Bar와 동일한 특성.

검토 후 배제한 대안: ScreenCaptureKit 캡처(권한·난이도 → v2로 연기),
Private API(SkyLight 등, OS 업데이트마다 파손 위험 → 영구 배제).

## 3. 메뉴바 아이템 구조

NSStatusItem 3개. 오른쪽이 메뉴바에서 더 오른쪽에 위치한다.

```
[숨김 아이콘들] ⋮ [일반 숨김 아이콘들] ❮ [항상 보임 아이콘들] ●
   ↑ alwaysHiddenSeparator      ↑ separator              ↑ mainItem
```

| 아이템 | 역할 | 표시 |
|---|---|---|
| `mainItem` | 토글 버튼 + 앱 메뉴 진입점. 항상 표시 | SF Symbol (접힘/펼침 상태에 따라 chevron 방향 등 변경) |
| `separator` | 이 왼쪽 = "숨김 영역". 접힘 시 `length = 10000` | 펼침 시 얇은 구분선 아이콘, 접힘 시 화면 밖 |
| `alwaysHiddenSeparator` | 이 왼쪽 = "항상 숨김 영역". 옵션 기능(기본 off) | fullyExpanded 상태에서만 보임 |

- 세 아이템 모두 `autosaveName` 지정 → macOS가 위치·순서를 기억하므로 영역
  구분이 재시작 후에도 유지된다.
- 항상 숨김 영역이 off면 `alwaysHiddenSeparator`를 생성하지 않는다(또는 제거).
- 사용자가 구분자를 mainItem 오른쪽으로 드래그하는 등 순서가 꼬이면: 다음 토글
  시점에 순서를 검증하고, 꼬였으면 안내 알림 후 위치 초기화(autosave 제거 후 재생성).

### 상태 머신 — `HidingEngine`

```
collapsed ──토글──▶ expanded ──⌥클릭/명령──▶ fullyExpanded
    ▲                  │                        │
    └──토글/타이머──────┴────────토글/타이머──────┘
```

- 순수 Swift enum + 전이 함수로 구현하고 AppKit에서 분리 → 단위 테스트 대상.
- `fullyExpanded`는 항상 숨김 영역 사용 시에만 존재.
- 자동 재숨김 타이머: expanded/fullyExpanded 진입 시 시작, 만료 시 collapsed로.
  설정값 초 단위(기본 10초, 0 = 자동 재숨김 없음). 메뉴가 열려 있는 동안은 보류.
- (제거됨 2026-07-11) "다른 곳 클릭 시 즉시 재숨김"은 v1에서 구현했다가 제거 —
  글로벌 클릭 모니터가 환경에 따라 동작이 불안정했고 자동 재숨김 타이머로 충분.

## 4. 인터랙션

### 메인 아이콘

- **좌클릭**: 펼침/접힘 토글 (`collapsed ↔ expanded`)
- **⌥+좌클릭**: 항상 숨김 영역까지 펼침 (`fullyExpanded`) — 항상 숨김 기능 on일 때
- **우클릭**: 앱 메뉴 표시 (아래 레이아웃)

### 앱 메뉴 (window-manager `MenuBarContent` 레이아웃을 따름)

```
My Bar 정보
──────────
숨긴 아이콘 보기/숨기기      ⇧⌘\     ← 현재 상태에 따라 라벨 토글
항상 숨김 영역 보기                   ← 옵션 on일 때만 표시
──────────
업데이트 확인...
설정...                      ⌘,      (systemImage: gearshape)
종료                         q       (systemImage: power)
```

- NSStatusItem 기반이므로 NSMenu로 구현하되, 항목 구성·순서·아이콘·단축키
  표기는 window-manager와 동일하게 맞춘다.
- "My Bar 정보"는 window-manager와 동일하게 SwiftUI `InfoView`를 별도
  hiddenTitleBar Window(width 320)로 연다 (표준 About 패널 대신 — GitHub 링크
  클릭 가능해야 하므로).

### 글로벌 단축키

- 의존성: `soffes/HotKey` (window-manager와 동일).
- v1 단축키 1개: 노출/숨김 토글. 기본값 ⇧⌘\. 설정 > 일반에서
  window-manager의 `HotkeyCaptureView` 패턴으로 변경/해제.

### 아이콘 영역 이동 (기능 3)

- macOS 표준: **⌘를 누른 채 아이콘 드래그**로 구분자 왼쪽/오른쪽 이동.
- 첫 실행 온보딩 창에서 애니메이션/그림과 함께 안내. 온보딩은 첫 실행 시 자동
  표시(`needsSetup` 플래그, window-manager의 ConfigStore 패턴), 설정에서 다시 열기 가능.
- 온보딩 직후에는 expanded 상태로 시작해 사용자가 바로 드래그해볼 수 있게 한다.

### 복귀 경로

- `applicationShouldHandleReopen`: Finder/`open`으로 앱을 다시 열면 설정 창 표시
  (window-manager와 동일 패턴).

## 5. 설정 창

window-manager와 동일한 구조: SwiftUI `Window` scene + `.hiddenTitleBar`
+ NavigationSplitView 사이드바. 기본 크기는 콘텐츠에 맞게 축소(예: 640×480).

### 탭: 일반

- 로그인 시 시작 (`LoginItemManager` 복사 — SMAppService)
- 토글 단축키 (HotkeyCaptureView)
- 자동 재숨김: 사용 여부 + 초 (기본 10초)
- 항상 숨김 영역 사용 (기본 off) + ⌥클릭 안내 문구
- 메뉴바 아이콘 모양 선택 (SF Symbol 2~3종)
- 노치 안내 배너 (노치 감지 시에만 표시, §6)

### 탭: 정보

window-manager `InfoView`와 **동일 구현** (이름·URL만 교체):

- 앱 아이콘 160×160 → "My Bar" (title2.bold) → `버전 X.Y.Z (빌드N)` (secondary)
- [업데이트 확인] 버튼 → `Updater.checkForUpdates(silent: false)`
- [GitHub] 링크 버튼 (`.buttonStyle(.link)`) → `https://github.com/DevooKim/my-bar`
- `NSHumanReadableCopyright` (caption, secondary)
- 세로 패딩 32, spacing 10, `frame(maxWidth: .infinity)`

## 6. 노치 대응 (v1: 감지 + 안내)

- 감지: `NSScreen.safeAreaInsets.top > 0` (또는 `auxiliaryTopLeftArea` 존재).
- 노치 맥에서는 펼쳐도 아이콘이 노치 뒤로 들어가 보이지 않을 수 있다:
  - 설정 > 일반에 안내 배너 표시("메뉴바 공간이 부족하면 노치 뒤로 가려질 수
    있습니다 — 잘 쓰지 않는 아이콘은 항상 숨김 영역으로 옮기세요").
  - 근본 해결은 v2 캡처 팝업.

## 7. 모듈 구조

```
Sources/MyBar/
  App/
    MyBarApp.swift          @main. Window scenes(설정/정보/업데이트/온보딩) 정의
    AppDelegate.swift       StatusBarController·Updater 연결, reopen 처리
    AppState.swift          창 open 액션 주입, 선택 탭 등 (window-manager 패턴)
  Core/
    StatusBarController.swift  NSStatusItem 3개 생성·순서 검증·클릭 라우팅
    HidingEngine.swift         상태머신 + 자동 재숨김 타이머 (AppKit 비의존)
    NotchDetector.swift        safeAreaInsets 기반 감지
    Updater.swift              window-manager 복사, repo 상수만 교체
    LoginItemManager.swift     window-manager 복사
  Models/
    HidingState.swift          collapsed/expanded/fullyExpanded + 전이
    HotkeyConfig.swift         window-manager 복사
    SemanticVersion.swift      window-manager 복사
  Storage/
    PreferencesStore.swift     ConfigStore 패턴 (ObservableObject + UserDefaults/JSON)
  UI/
    Settings/  SettingsRootView(사이드바), GeneralView, InfoView
    Onboarding/ OnboardingView (⌘드래그 안내)
    Update/    window-manager의 UpdateWindowRoot/UpdatePromptState/UpdatePromptView 복사
Tests/MyBarTests/
    HidingEngineTests          상태 전이, 타이머 만료, 항상숨김 off시 fullyExpanded 불가
    SemanticVersionTests       window-manager 복사
```

- 주의: 메인 토글 아이콘은 SwiftUI `MenuBarExtra`가 아니라 **NSStatusItem**으로
  만든다. 좌클릭 토글/우클릭 메뉴 분리와 구분자 아이템들과의 순서 제어가
  필요하기 때문.
- 창 관리: window-manager의 "Window scene + openWindow 주입" 패턴은 항상
  렌더되는 MenuBarExtra label이 있어야 동작하는데(주입 지점), my-bar에는 그
  호스트가 없다. 따라서 설정·정보·업데이트·온보딩 창은 window-manager의
  온보딩 창과 같은 **NSWindow + NSHostingController** 패턴으로 AppState가
  소유·재사용한다. UI 구조(NavigationSplitView 사이드바, hiddenTitleBar 스타일,
  VisualEffectView 머티리얼)는 동일하게 유지한다.

## 8. 빌드 · 버전관리 · 배포 · 서명 (window-manager와 동일)

| 항목 | 내용 |
|---|---|
| 패키지 | SwiftPM 실행형, swift-tools 6.0, `swiftLanguageModes: [.v5]`, macOS 14+, 의존성 HotKey |
| Makefile | window-manager 것 복사: `build/test/app/run/release/publish/bump-*` + CLT Swift Testing TESTFLAGS 트릭 |
| 버전 | `Info.plist` `CFBundleShortVersionString`(semver) + `CFBundleVersion`(빌드번호), `scripts/bump.sh` (깨끗한 트리 강제, 커밋까지) |
| 번들 | `scripts/bundle.sh`: `swift build -c release` → `dist/My Bar.app` 조립 |
| 서명 | 자체 서명 identity `MyBar Dev` (env `MB_SIGN_IDENTITY`로 재정의), 실패 시 ad-hoc 폴백. 노터라이즈 없음 |
| 배포 | `scripts/publish.sh`: ditto zip → `git tag vX.Y.Z` → push → `gh release create` (커밋 제목 기반 체인지로그, bump 커밋 제외) |
| 업데이트 | `Updater`: GitHub Releases API 조회 → SwiftUI 프롬프트 → zip 다운로드 → quarantine 제거 → in-place 교체 → 재실행. 실행 5초 후 + 24시간 주기 silent 체크 |
| repo | `DevooKim/my-bar` (README의 설치 안내 링크 포함) |

### Info.plist

window-manager 것 기반, 차이점만:

- `CFBundleDisplayName`: `My Bar` / `CFBundleName`: `MyBar` / `CFBundleExecutable`: `MyBar`
- `CFBundleIdentifier`: `io.goorm.MyBar`
- `NSAccessibilityUsageDescription` **제거** (v1은 무권한)
- `LSMinimumSystemVersion`: `14.0` (패키지 platforms `.v14`와 일치 — 참조 앱은 13.0으로 남아있는 불일치가 있으니 답습하지 않음)
- 유지: `LSUIElement=true`, ko/en localizations, productivity 카테고리, 초기 버전 0.1.0 / 빌드 1

## 9. 에러 처리·엣지 케이스

- 구분자 순서 꼬임(mainItem보다 오른쪽 등): 토글 시 검증 → 알림 → autosave 초기화 후 재생성.
- 메뉴바 공간 부족(노치·아이콘 과다): 펼쳐도 일부가 안 보일 수 있음 — §6 안내로 대응.
- 풀스크린 앱에서 메뉴바 자동 숨김: 시스템 동작에 따름, 특별 처리 없음.
- 다중 모니터: NSStatusItem은 시스템이 모든 메뉴바에 동일하게 그림 — v1은 별도 처리 없음.
- `swift run`(비번들) 실행: Updater는 스킵(window-manager와 동일 가드).

## 10. 백로그 (v2+)

1. **캡처 팝업 (기능 4 완성형)**: ScreenCaptureKit로 숨긴 아이콘 영역을 캡처해
   메인 아이콘 아래 팝업 패널에 아이콘 이미지를 나열, 클릭 시 해당 아이콘
   위치로 클릭 전달. Screen Recording 권한 온보딩 필요. Ice 방식.
2. 호버/스크롤로 펼치기 (메뉴바에 마우스 올리거나 스크롤 시 임시 펼침)
3. 앱 트리거: 특정 앱 실행/포커스 시 특정 아이콘 자동 노출
4. 아이콘 검색/이름 표시
5. 프로필 (집/회사 등 영역 구성 전환)
6. 메뉴바 아이콘 간격 조절 (defaults NSStatusItemSpacing 계열)

## 11. 성공 기준

- 재부팅·재로그인 후에도 영역 구분과 접힘 상태가 유지된다.
- 클릭·단축키 토글이 즉각 반응하고, 자동 재숨김이 설정대로 동작한다.
- `make test` 통과 (HidingEngine 상태머신 커버), `make app`으로 서명된 번들 생성,
  `make publish`로 GitHub Release까지 무인 진행.
- 설정 창·정보 탭·업데이트 흐름이 window-manager와 시각적으로 동일한 구조.
