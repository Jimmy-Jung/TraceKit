# TraceKit

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20visionOS-lightgrey.svg)](https://www.apple.com)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Swift 기반의 유연하고 확장 가능한 멀티플랫폼 로깅 프레임워크입니다.

## 주요 기능

- 다중 출력 대상 지원 (Console, OSLog, File)
- Firebase 4대 서비스 통합 (Analytics, Crashlytics, Performance, Remote Config)
- **✨ Variadic Parameters Metadata API** (v1.2.1+, AnyCodable 래핑 불필요)
- Actor 기반 스레드 안전성
- 빌더 패턴을 통한 쉬운 구성
- **런타임 동적 설정 변경** (앱 재시작 없이 설정 업데이트)
- 민감정보 자동 마스킹
- 로그 샘플링 및 버퍼링
- 성능 추적 (Performance Tracing)
- **크래시 로그 보존** (mmap 기반)
- Launch Argument를 통한 런타임 설정
- Swift 6.0 / iOS 15.0+

## 빠른 시작

### 기본 사용법

```swift
import TraceKit

// 가장 간단한 사용 (동기 API)
TraceKit.info("앱이 시작되었습니다")
TraceKit.warning("메모리 사용량이 높습니다")
TraceKit.error("네트워크 연결 실패")

// 비동기 API (로그 완료 대기 필요 시)
Task {
    await TraceKit.async.info("로그 완료까지 대기")
}

// ✨ v1.2.1+ 메타데이터 추가 (권장)
TraceKit.info(
    "API 호출 성공",
    category: "Network",
    ("statusCode", 200),
    ("url", "https://api.example.com")
)
```

### 빌더를 사용한 커스텀 설정

```swift
import TraceKit

@main
struct MyApp: App {
    init() {
        Task {
            let logger = await TraceKitBuilder()
                .addConsole(formatter: PrettyTraceFormatter.verbose)
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
let debugLogger = await TraceKitBuilder.debug().buildAsShared()

// 프로덕션용 (최적화된 설정)
let prodLogger = await TraceKitBuilder.production().buildAsShared()
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

- `ConsoleTraceDestination` - 콘솔 출력 (stdout/stderr)
- `OSTraceDestination` - Apple os.log 시스템
- `FileTraceDestination` - 파일 저장

### Firebase 통합

`TraceKitFirebase` product에서 Crashlytics 연동 Destination을 제공합니다.
TraceKitDemo는 Analytics, Performance, Remote Config 데모 구현도 함께 포함합니다.

- `FirebaseCrashlyticsTraceDestination` - Crashlytics breadcrumb / non-fatal error 전송
- `FirebaseAnalyticsTraceDestination` - Analytics 이벤트 전송 (데모 앱 구현)
- `FirebasePerformanceTraceDestination` - Performance 모니터링 (데모 앱 구현)
- `FirebaseRemoteConfigManager` - 원격 설정 관리 (데모 앱 구현)

```swift
import TraceKit
import TraceKitFirebase

let logger = await TraceKitBuilder()
    .addDestination(FirebaseCrashlyticsTraceDestination())
    .buildAsShared()
```

자세한 사용법은 [외부 연동 문서](./Documents/05-외부-연동.md)를 참고하세요.

## 고급 기능

### 메타데이터 추가

TraceKit는 두 가지 방식의 메타데이터 API를 지원합니다:

**✨ 새로운 Variadic Parameters API (v1.2.1+, 권장)**

```swift
// AnyCodable 래핑 불필요 - 45% 코드 감소
TraceKit.info(
    "사용자 로그인 성공",
    category: "Auth",
    ("userId", "user123"),
    ("loginMethod", "OAuth")
)

// 비동기 버전
await TraceKit.async.info(
    "API 호출 성공",
    category: "Network",
    ("statusCode", 200),
    ("url", "https://api.example.com"),
    ("responseTime", 350.5)
)
```

**기존 Dictionary API (하위 호환)**

```swift
await TraceKit.async.info(
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
let result = await TraceKit.async.measure(name: "데이터 로딩") {
    await loadData()
}

// 수동 측정
let spanId = await TraceKit.async.startSpan(name: "복잡한 작업")
// ... 작업 수행 ...
await TraceKit.async.endSpan(id: spanId)
```

### 민감정보 마스킹

```swift
// 자동으로 마스킹됨
await TraceKit.async.info("사용자 이메일: john@example.com")
// 출력: "사용자 이메일: [EMAIL_REDACTED]"

await TraceKit.async.info("카드번호: 1234-5678-9012-3456")
// 출력: "카드번호: [CARD_REDACTED]"
```

### 크래시 로그 보존

```swift
// 크래시 직전 로그를 자동 보존
let logger = await TraceKitBuilder()
    .withCrashPreservation(count: 50)
    .buildAsShared()

// 앱 재시작 시 복구
if let crashLogs = await TraceKit.async.recoverCrashLogs() {
    print("크래시 전 로그 \(crashLogs.count)개 복구됨")
}
```

### 런타임 설정 변경

```swift
// 앱 실행 중 설정 변경 (앱 재시작 불필요)
let newConfig = TraceKitConfiguration(
    minLevel: .verbose,
    isSanitizingEnabled: false,
    sampleRate: 0.5
)

await TraceKit.async.configure(newConfig)
// 즉시 새로운 설정으로 동작
```

### Firebase Remote Config 연동

```swift
// Firebase Console에서 원격으로 설정 제어
let remoteConfigManager = FirebaseRemoteConfigManager()
await remoteConfigManager.fetchAndActivate()

// TraceKit에 자동 적용
await remoteConfigManager.applyToTraceKit()

// 실시간 자동 업데이트 (권장)
await remoteConfigManager.startRealtimeUpdates()
// Firebase Console 변경 시 2-3초 내 자동 반영
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

### Swift Package Manager (권장)

#### Xcode에서 설치

1. Xcode에서 File > Add Package Dependencies...
2. 다음 URL 입력:
```
https://github.com/megastudymobile/ms-tracekit-ios
```
3. 버전 규칙 선택 (예: "Up to Next Major Version" - 1.2.0)
4. 필요한 패키지 선택:
   - `TraceKit` - 코어 로깅 프레임워크 (필수)

#### Package.swift에서 설치

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/megastudymobile/ms-tracekit-ios", from: "1.2.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "TraceKit", package: "TraceKit")
        ]
    )
]
```

### Tuist

```swift
// Package.swift (Tuist 의존성)
dependencies: [
    .package(url: "https://github.com/megastudymobile/ms-tracekit-ios", from: "1.2.0")
]

// Project.swift
let project = Project(
    name: "MyApp",
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .package(product: "TraceKit")
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
- [데모 앱](./Documents/07-데모-앱.md)

### Firebase 통합

- [Firebase 통합 모듈 가이드](./Projects/TraceKitDemo/FIREBASE_MODULES_GUIDE.md)
  - Analytics, Crashlytics, Performance, Remote Config 연동
  - 실시간 모니터링 및 원격 설정 관리
  - 데모 앱에서 실제 구현 예제 확인

## 요구사항

- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 8.0+
- visionOS 1.0+
- Swift 6.0+
- Xcode 16.0+

## 플랫폼별 특징

| 플랫폼 | Console | OSLog | File | 외부 연동 | 특이사항 |
|--------|---------|-------|------|----------|---------|
| iOS | ✅ | ✅ | ✅ | ✅ | 전체 기능 지원 |
| macOS | ✅ | ✅ | ✅ | ✅ | ~/Library/Logs에 저장 |
| tvOS | ✅ | ✅ | ✅ | ✅ | 전체 기능 지원 |
| watchOS | ✅ | ✅ | ⚠️ | ✅ | 제한된 저장 공간 |
| visionOS | ✅ | ✅ | ✅ | ✅ | 전체 기능 지원 |

⚠️ watchOS는 저장 공간이 제한적이므로 파일 로그 사용 시 retentionPolicy 설정 권장

## 버전 히스토리

### 1.2.1 (2026-02-04)

**개선사항**
- ✨ Variadic Parameters를 사용한 Metadata API 추가
  - `AnyCodable` 래핑 자동화로 45% 코드 감소
  - 모든 로그 레벨 (verbose~fatal) 지원
  - 100% 하위 호환성 유지
- 📝 12개 신규 테스트 추가

**Before & After**
```swift
// Before (기존 방식)
TraceKit.info(
    "API 호출",
    category: "Network",
    metadata: [
        "statusCode": AnyCodable(200),
        "url": AnyCodable("https://...")
    ]
)

// After (v1.2.1+)
TraceKit.info(
    "API 호출",
    category: "Network",
    ("statusCode", 200),
    ("url", "https://...")
)
```

### 1.2.0 (2026-01-27)

**새로운 기능**
- Firebase 4대 서비스 통합 (Analytics, Crashlytics, Performance, Remote Config)
- 런타임 동적 설정 변경 기능 (`configure()` API)
- Firebase Remote Config를 통한 원격 설정 관리
- 실시간 자동 업데이트 지원 (Console 변경 시 2-3초 내 반영)
- TraceKitDemo 독립 Tuist 프로젝트로 구성

**개선사항**
- Swift 6.0 Concurrency 완전 지원
- Firebase 통합 데모 화면 추가
- 설정 변경 이력 자동 로깅
- 외부 연동 모듈 아키텍처 개선

**문서**
- [Firebase 통합 모듈 가이드](./Projects/TraceKitDemo/FIREBASE_MODULES_GUIDE.md) 추가
- 데모 앱 README 업데이트

### 1.1.0

- 크래시 로그 보존 기능 추가
- 멀티플랫폼 지원 (iOS, macOS, tvOS, watchOS, visionOS)
- Launch Argument 런타임 설정

### 1.0.0

- 초기 릴리즈

## 라이선스

MIT License - Copyright (c) 2025 Jung Junyoung

자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

---

## 플랫폼별 사용 예시

### macOS

```swift
import TraceKit

@main
struct MyMacApp: App {
    init() {
        Task {
            let logger = await TraceKitBuilder()
                .addConsole()
                .addOSLog()
                .addFile() // ~/Library/Logs/BundleID/에 저장
                .buildAsShared()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### watchOS

```swift
import TraceKit

@main
struct MyWatchApp: App {
    init() {
        Task {
            // watchOS는 저장 공간이 제한적이므로 보관 정책 설정
            let retentionPolicy = TraceFileRetentionPolicy(
                retentionDays: 3,
                maxFileSize: 512 * 1024, // 512KB
                maxTotalSize: 2 * 1024 * 1024 // 2MB
            )
            
            let logger = await TraceKitBuilder()
                .addConsole()
                .addOSLog()
                .addFile(retentionPolicy: retentionPolicy)
                .buildAsShared()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### tvOS

```swift
import TraceKit

@main
struct MyTVApp: App {
    init() {
        Task {
            let logger = await TraceKitBuilder()
                .addConsole()
                .addOSLog()
                .buildAsShared()
            
            await TraceKit.async.info("tvOS 앱 시작", category: "App")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### visionOS

```swift
import TraceKit

@main
struct MyVisionApp: App {
    init() {
        Task {
            let logger = await TraceKitBuilder()
                .addConsole()
                .addOSLog()
                .addFile()
                .withDefaultSanitizer()
                .buildAsShared()
            
            await TraceKit.async.info("visionOS 앱 시작", category: "App")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```
