# Project
Seumseum(씀씀) — 지출을 기록하고 관리하는 iOS 가계부 앱.
SwiftUI + SwiftData, Tuist 멀티모듈. 아이폰 전용(세로 모드만), 최소 배포 타깃 iOS 17.
번들 ID: `com.xngsoo.seumseum`

## Tech Stack
- Language: Swift 6 (Strict Concurrency 활성화)
- UI: SwiftUI 우선, 불가피한 경우에만 UIKit (UIViewRepresentable로 래핑)
- Persistence: SwiftData
- Chart: Swift Charts (`SectorMark`) — 차트용 서드파티 금지
- Concurrency: async/await + Actor
- Project: Tuist **4.202.6 고정** (`mise.toml`). 버전 임의 변경 금지
- Test: Swift Testing (`@Test` / `#expect`)
- CI/CD: Jenkins + Fastlane

## Modules
- `Projects/App` — 진입점, 커스텀 탭바, DI, `LedgerNavigation` 소유. 화면 구현 코드 금지
- `Projects/Feature/Daily` — 탭 1. 일별 소비 내역
- `Projects/Feature/Monthly` — 탭 2. 월 달력
- `Projects/Feature/Statistics` — 탭 3. 주별/월별 통계
- `Projects/Feature/Settings` — 탭 4. 설정
- `Projects/Feature/Editor` — 추가/수정 모달. 모든 탭에서 재사용
- `Projects/Domain` — 엔티티(struct), Repository 프로토콜, UseCase, `LedgerNavigation`
- `Projects/Core/Persistence` — SwiftData 스택, `@Model` 엔티티, Repository 구현체
- `Projects/Core/DesignSystem` — 컬러/타이포 토큰, 공통 컴포넌트
- `Projects/Core/Shared` — `AmountFormatter`, 날짜 유틸, 확장

## Architecture
- 의존 방향: `App → Features → Domain`, `App → Persistence → Domain`. 역방향 의존 금지
- Feature 모듈끼리 직접 의존 금지 — 필요하면 Domain의 프로토콜/상태를 경유
- Domain은 SwiftUI/SwiftData를 import하지 않는다 (Foundation만)
- `@Model` 타입은 Persistence 밖으로 나가지 않는다. 경계에서 Domain struct로 매핑
- 탭 간 연동은 `@Observable LedgerNavigation`(selectedTab, selectedDate) 하나로만 한다.
  탭 2에서 날짜 탭 → `LedgerNavigation`의 두 값을 갱신 → 탭 1이 반응. 직접 호출 금지
- 화면 단위 MVVM: View는 렌더링만, 상태와 로직은 `@Observable` ViewModel
- ViewModel은 Repository 프로토콜에만 의존, 구현체는 App 레이어에서 주입
- 탭바는 `TabView` 기본 탭바가 아니라 커스텀 탭바 오버레이 (중앙 추가 버튼이 탭이 아닌 액션이므로)

## Domain Rules
- `Expense`: `id`, `amount: Decimal`, `memo: String`, `categoryID`, `date: Date`, `createdAt`, `sortOrder: Int`
- `Category`: `id`, `name`, `symbolName`, `colorToken`, `sortOrder`, `isBuiltIn`
- 정렬: 같은 날짜 안에서 `sortOrder` 오름차순. 신규 항목은 그 날짜의 최소 `sortOrder - 1`을 받아 맨 위에 온다
- 드래그 재정렬 시 해당 날짜의 항목만 `sortOrder`를 0부터 재부여한다
- 금액 축약 표기(`AmountFormatter.abbreviated`):
  - 10,000 미만 → 그대로 (`9800원`)
  - 10,000 이상 → 만 단위 소수 1자리 반올림, 소수부가 0이면 생략 (`10만원`, `11.3만원`, `153.5만원`)
  - 100,000,000 이상 → 같은 규칙을 억 단위로 (`1.2억원`)
  - 상세 화면과 입력 필드에서는 축약하지 않고 원 단위 그대로 (`1,535,000원`)
- 급여 주기(`PayPeriod`)는 통계에서만 쓴다. 탭 1·2는 항상 달력 기준 (일 / 1일~말일)
- 급여일 설정이 꺼져 있으면(기본) 주기 = 달력상의 월
- 급여일이 켜져 있으면 주기 = `해당 월 지급일 ~ 다음 달 지급일 전날`
- 지급일 보정 규칙은 설정값을 따른다: `.previousBusinessDay`(기본) / `.nextBusinessDay` / `.none`
- 보정 판정은 주말(토·일)만 본다. 공휴일 판정은 v1 범위 밖 — 사용자가 주기 시작일을 직접 조정
- 급여일로 29~31일을 고른 달에 해당 일자가 없으면 그 달의 마지막 날로 보정한 뒤 주말 규칙을 적용한다
- 삭제는 soft delete 하지 않는다. 즉시 삭제 + 취소 스낵바

## Screens
- 탭 1 Daily: 상단 날짜·요일, 하단 그날 내역 리스트(금액/내용/카테고리).
  롱프레스 드래그로 재정렬, 좌우 스와이프로 날짜 이동. 빈 날짜도 빈 상태 화면을 보여준다
- 탭 2 Monthly: 월 그리드, 각 날짜 셀 하단에 그날 합계(축약 표기).
  날짜 탭 → 탭 1 이동, 좌우 스와이프로 월 이동, 달력 하단에 월 총액
- 탭 3 Statistics: 세그먼트 없이 급여 주기 단위 단일 화면. 카테고리별 원형 그래프,
  총액, 일평균, 최다 사용 카테고리, 직전 주기 대비 증감. 주기 안의 주차별 막대 그래프를 함께 보여준다.
  화면 상단에 적용 기간을 항상 명시한다 (`7/25 – 8/24`). 좌우 스와이프로 이전/다음 주기 이동
- 탭 4 Settings: 카테고리 관리(추가/이름·색상·아이콘 수정/순서 변경/삭제),
  급여일, 지급일 보정 규칙, 통화 표시, 기록 리마인더 알림, CSV 내보내기, 앱 잠금
- 급여일 행 아래에는 캡션으로 활용법을 안내하고, 날짜를 고르는 동안 적용 기간 미리보기를 함께 보여준다
  (`매월 25일 → 7/25 – 8/24`). 보정 규칙은 급여일이 켜져 있을 때만 노출한다
- 급여일을 처음 켤 때 확인 다이얼로그로 통계 기준이 바뀐다는 점과 기록은 그대로라는 점을 알린다
- 추가 모달: 입력 순서는 금액 → 카테고리 → 날짜 → 내용. 진입 시 금액 키패드에 포커스.
  탭 1에서 열면 기본 날짜 = 화면에 보이는 날짜, 그 외에는 오늘

## Commands
- 프로젝트 생성: `tuist generate`
- 의존성 설치: `tuist install`
- 빌드: `tuist build Seumseum`
- 전체 테스트: `tuist test`
- 단일 테스트: `xcodebuild test -workspace Seumseum.xcworkspace -scheme Seumseum -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:DomainTests/[TestName]`
- 포맷: `swiftformat .`
- 린트: `swiftlint --strict`
- 베타 배포: `bundle exec fastlane beta`

## Git
- `main`: 항상 배포 가능 상태. 릴리스와 핫픽스만 반영한다. 직접 푸시 금지
- `dev`: 통합 브랜치. 모든 기능 작업이 여기로 모인다. 직접 푸시 금지, PR로만 반영
- 작업 브랜치: `feat/`, `fix/`, `refactor/`, `chore/` + 영문 케밥 케이스 (예: `feat/monthly-calendar`)
- `dev`에서 분기 → `dev`로 PR → Squash merge → 브랜치 삭제
- 심사 제출 시 `dev`에서 `release/x.y.z` 분기. 승인 후 `vX.Y.Z` 태그를 찍고 `main`과 `dev`에 모두 머지
- 긴급 수정은 `main`에서 `hotfix/` 분기 → `main`에 머지 후 태그, `dev`에도 반드시 역머지
- 커밋 메시지: Conventional Commits. 제목은 영문, 본문은 한국어 허용
- Jenkins: `dev`/`main` 대상 PR 이벤트 → `tuist test` + `swiftlint --strict`, `v*` 태그 → `fastlane beta`

## Conventions
- 상태 관리는 `@Observable` + `@State` 조합
- SwiftUI View 파일에는 항상 `#Preview` 블록 포함, mock 데이터 사용
- View body가 30줄을 넘으면 하위 View로 분리
- 비동기 API는 `async throws`. 예상 가능한 실패는 도메인 에러 타입으로 정의
- 에러 타입 명명: `[Feature]Error`, `LocalizedError` 채택
- 1 파일 1 주요 타입, 파일명 = 타입명
- 테스트 파일: `*Tests.swift`, Swift Testing의 `@Test` 사용
- 문자열/이미지 리터럴 대신 Tuist가 생성한 리소스 심볼 사용
- 접근 제어 기본값은 internal, 모듈 외부에 노출할 API만 public

## Do NOT
- Do not use Core Data directly — SwiftData only
- Do not use Combine in new code — Swift Concurrency only
- Do not use `ObservableObject` / `@Published` — use `@Observable`
- Do not expose `@Model` types outside the Persistence module
- Do not use `Double` for money — `Decimal` only
- Do not sort expenses by `createdAt` at query time — use `sortOrder`
- Do not apply the pay period to tab 1 or tab 2 — statistics only
- Do not hardcode holiday dates — v1 adjusts for weekends only
- Do not use force unwrap (`!`) or `try!` in production code
- Do not use `DispatchQueue.main.async` — use `@MainActor`
- Do not access singletons inside ViewModel — inject dependencies
- Do not edit `*.xcodeproj` / `*.xcworkspace` — they are generated, edit `Project.swift`
- Do not change the pinned Tuist version
- Do not add third-party dependencies without approval
- Do not add comments unless the logic is non-obvious
- Do not add landscape or iPad layout code
- Do not hardcode secrets — use `.xcconfig` / environment variables
- Do not commit directly to `main` or `dev`, and do not push or create tags without explicit instruction    

## References
- 모듈 정의 헬퍼: `Tuist/ProjectDescriptionHelpers/Module.swift`
- 외부 의존성: `Tuist/Package.swift`
- 디자인 토큰: `Projects/Core/DesignSystem/Sources/Tokens/`
