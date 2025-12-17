# Logger

Swift 기반의 유연하고 확장 가능한 iOS 로깅 프레임워크입니다.

## 주요 기능

- 다중 출력 대상 지원 (Console, OSLog, File, Sentry, Datadog, Firebase)
- Actor 기반 스레드 안전성
- 빌더 패턴을 통한 쉬운 구성
- 민감정보 자동 마스킹
- 로그 샘플링 및 버퍼링
- 성능 추적 (Performance Tracing)
- **크래시 로그 보존** (mmap 기반)
- Launch Argument를 통한 런타임 설정
- Swift 6.0 / iOS 15.0+

## 빠른 시작

### 기본 사용법

```swift
import Logger

// 기본 로거 사용
Task {
    await Logger.shared.info("앱이 시작되었습니다")
    await Logger.shared.warning("메모리 사용량이 높습니다")
    await Logger.shared.error("네트워크 연결 실패")
}
```

### 빌더를 사용한 커스텀 설정

```swift
import Logger

@main
struct MyApp: App {
    init() {
        Task {
            let logger = await LoggerBuilder()
                .addConsole(formatter: PrettyLogFormatter.verbose)
                .addOSLog()
                .withDefaultSanitizer()
                .withDefaultContextProvider(environment: .production)
                .buildAsShared()
        }
    }
}
```

### 디버그/프로덕션 프리셋

```swift
// 디버그용 (모든 로그, 컬러풀한 콘솔 출력)
let debugLogger = await LoggerBuilder.debug().buildAsShared()

// 프로덕션용 (최적화된 설정)
let prodLogger = await LoggerBuilder.production().buildAsShared()
```

## 로그 레벨

| 레벨 | 이모지 | 설명 |
|-----|-------|------|
| verbose | 📝 | 가장 상세한 추적 로그 |
| debug | 🔍 | 디버깅 목적의 로그 |
| info | ℹ️ | 일반 정보성 로그 |
| warning | ⚠️ | 잠재적 문제 경고 |
| error | ❌ | 오류 발생 |
| fatal | 💀 | 치명적 오류 |

## 로그 출력 예시

```
14:32:15.123 🔍 DEBUG [Network] API 요청 시작 (NetworkService.swift:42)
14:32:15.456 ℹ️ INFO [Network] 응답 수신: 200 OK (NetworkService.swift:58)
14:32:16.789 ⚠️ WARNING [Auth] 토큰 만료 임박 (AuthManager.swift:123)
```

## 출력 대상 (Destinations)

### 기본 제공

- `ConsoleLogDestination` - 콘솔 출력 (stdout/stderr)
- `OSLogDestination` - Apple os.log 시스템
- `FileLogDestination` - 파일 저장

### 외부 연동 (별도 모듈)

- `LoggerSentry` - Sentry 연동
- `LoggerDatadog` - Datadog 연동
- `LoggerFirebase` - Firebase Crashlytics 연동

## 고급 기능

### 메타데이터 추가

```swift
await Logger.shared.info(
    "사용자 로그인 성공",
    category: "Auth",
    metadata: [
        "userId": AnyCodable("user123"),
        "loginMethod": AnyCodable("OAuth")
    ]
)
```

### 성능 측정

```swift
// 자동 측정
let result = await Logger.shared.measure(name: "데이터 로딩") {
    await loadData()
}

// 수동 측정
let spanId = await Logger.shared.startSpan(name: "복잡한 작업")
// ... 작업 수행 ...
await Logger.shared.endSpan(id: spanId)
```

### 민감정보 마스킹

```swift
// 자동으로 마스킹됨
await Logger.shared.info("사용자 이메일: john@example.com")
// 출력: "사용자 이메일: [EMAIL]"

await Logger.shared.info("카드번호: 1234-5678-9012-3456")
// 출력: "카드번호: [CREDIT_CARD]"
```

### 크래시 로그 보존

```swift
// 크래시 직전 로그를 자동 보존
let logger = await LoggerBuilder()
    .withCrashPreservation(count: 50)
    .buildAsShared()

// 앱 재시작 시 복구
if let crashLogs = await Logger.shared.recoverCrashLogs() {
    print("크래시 전 로그 \(crashLogs.count)개 복구됨")
}
```

## 런타임 설정 (Launch Arguments)

Xcode에서 다음 launch argument로 로거를 제어할 수 있습니다:

```
-logLevel DEBUG           # 최소 로그 레벨 설정
-logFilter Network,Auth   # 특정 카테고리만 출력
-disableConsole           # 콘솔 출력 비활성화
-disableMasking           # 민감정보 마스킹 비활성화
```

## 설치

### Tuist

```swift
// Project.swift
let project = Project(
    name: "MyApp",
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .project(target: "Logger", path: "../Logger")
            ]
        )
    ]
)
```

## 문서

상세한 사용법은 [Documents](./Documents/) 폴더를 참고하세요.

- [프로젝트 개요](./Documents/01-프로젝트-개요.md)
- [아키텍처](./Documents/02-아키텍처.md)
- [사용법](./Documents/03-사용법.md)
- [고급 기능](./Documents/04-고급-기능.md)
- [외부 연동](./Documents/05-외부-연동.md)
- [런타임 설정](./Documents/06-런타임-설정.md)

## 요구사항

- iOS 15.0+
- Swift 6.0+
- Xcode 16.0+

## 라이선스

MIT License

