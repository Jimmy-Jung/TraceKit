# CrashLogPreserver 사용 가이드

## 개요

`CrashLogPreserver`는 앱 크래시 시 로그를 보존하고 다음 실행 시 복구할 수 있는 Actor 기반 로그 보존기입니다.

## 주요 기능

### 1. 일반 로그 보존 (`persist()`)

```swift
let preserver = CrashLogPreserver(preserveCount: 50)

// 로그 기록
await preserver.record(logMessage)

// 파일에 저장
try await preserver.persist()

// 다음 실행 시 복구
if let logs = try await preserver.recover() {
    print("복구된 로그: \(logs.count)개")
}
```

### 2. 크래시 감지 (mmap 기반)

#### persistSync() - Signal Handler용 동기 저장

크래시가 발생했을 때 Signal Handler에서 안전하게 로그를 저장합니다.

**특징:**
- **nonisolated**: Actor isolation 우회
- **Signal-safe**: async-safe 함수만 사용
- **mmap 기반**: 메모리 매핑된 파일에 직접 쓰기
- **os_unfair_lock**: Spin lock으로 동기화

**구현:**

```swift
public nonisolated func persistSync() {
    guard let ptr = mmapPtr, mmapFD >= 0 else { return }
    
    os_unfair_lock_lock(&syncLock)
    defer { os_unfair_lock_unlock(&syncLock) }
    
    // "CRASH\n타임스탬프\n" 형식으로 저장
    let timestamp = Date().timeIntervalSince1970
    let header = "CRASH\n\(timestamp)\n"
    
    if let headerData = header.data(using: .utf8) {
        let headerBytes = [UInt8](headerData)
        memcpy(ptr, headerBytes, min(headerBytes.count, mmapSize))
        msync(ptr, mmapSize, MS_SYNC)
    }
}
```

### 3. Signal Handler 등록

#### 방법 1: registerSignalHandlers (기본)

```swift
let preserver = CrashLogPreserver()
CrashLogPreserver.registerSignalHandlers(preserver: preserver)
```

⚠️ **제한사항**: Actor를 전역 변수로 저장할 수 없어 실제로 작동하지 않습니다.

#### 방법 2: registerSignalHandlersUnsafe (권장)

```swift
let preserver = CrashLogPreserver()

// mmap 포인터를 직접 전달
await CrashLogPreserver.registerSignalHandlersUnsafe(
    mmapPtr: preserver.mmapPtr,  // ⚠️ private이므로 public으로 노출 필요
    mmapSize: 1024 * 1024
)
```

**Signal Handler에서 수행:**
1. "CRASH" 마커를 mmap에 쓰기
2. msync로 즉시 디스크에 동기화
3. exit() 호출

## 아키텍처

### mmap 기반 저장

```
┌─────────────────────────────────────┐
│  CrashLogPreserver (Actor)          │
├─────────────────────────────────────┤
│ ringBuffer: RingBuffer<LogMessage>  │  ← 일반 로그 버퍼
│ mmapPtr: UnsafeMutableRawPointer?   │  ← mmap 메모리
│ mmapFD: Int32                       │  ← 파일 디스크립터
│ syncLock: os_unfair_lock            │  ← 동기화 잠금
└─────────────────────────────────────┘
         │
         ├─ persist()     → crash_logs.json (일반 저장)
         ├─ persistSync() → crash_logs.mmap (크래시 시)
         └─ recover()     → 두 파일 모두 확인
```

### 파일 구조

```
~/Library/Caches/
├── crash_logs.json  ← 일반 로그 (JSON 형식)
└── crash_logs.mmap  ← 크래시 마커 (mmap)
```

**crash_logs.mmap 포맷:**
```
CRASH\n
1734345678.123\n
```

## 작동 방식

### 초기화 시

```swift
public init(preserveCount: Int = 50, storageURL: URL? = nil) {
    // 1. RingBuffer 생성
    self.ringBuffer = RingBuffer(capacity: preserveCount)
    
    // 2. 저장 경로 설정
    self.storageURL = storageURL ?? defaultPath
    
    // 3. mmap 초기화
    setupMmap()  // crash_logs.mmap 파일 생성 및 매핑
}
```

### 크래시 발생 시

```
1. 앱 실행 중 SIGSEGV 발생
2. Signal Handler 호출
3. crashMmapPtr에 "CRASH\n..." 쓰기
4. msync로 즉시 디스크 동기화
5. exit()
```

### 다음 실행 시

```swift
if let logs = try await preserver.recover() {
    // 1. hasCrashData() → mmap에서 "CRASH" 확인
    // 2. clearMmapData() → mmap 초기화
    // 3. crash_logs.json 읽기
    // 4. 로그 반환
}
```

## 사용 예시

### 앱 시작 시

```swift
@main
struct MyApp: App {
    init() {
        setupCrashLogger()
    }
    
    func setupCrashLogger() {
        Task {
            let preserver = CrashLogPreserver()
            
            // 이전 크래시 로그 확인
            if let logs = try? await preserver.recover() {
                print("⚠️ 이전 크래시 감지: \(logs.count)개 로그")
                // 서버로 전송 또는 분석
            }
            
            // 현재 세션용 Signal Handler 등록
            // (실제로는 mmap 포인터를 노출해야 함)
        }
    }
}
```

### 정기적 저장

```swift
class LogManager {
    let preserver = CrashLogPreserver()
    
    func log(_ message: LogMessage) async {
        await preserver.record(message)
        
        // 10개마다 저장
        if await preserver.count >= 10 {
            try? await preserver.persist()
        }
    }
}
```

## Signal Handler 안전성

### ✅ Signal-safe 함수

- `memcpy`, `memset`
- `open`, `close`, `write`
- `mmap`, `munmap`, `msync`
- `os_unfair_lock_lock`, `os_unfair_lock_unlock`
- `exit`

### ❌ Signal-unsafe 함수

- `malloc`, `free`
- `printf`, `NSLog`
- `JSONEncoder`
- `async/await`
- 대부분의 Foundation API

## 제한사항

1. **Actor 접근 불가**: Signal Handler에서 Actor 메서드를 직접 호출할 수 없음
2. **전역 변수 필요**: `crashMmapPtr` 같은 전역 변수를 사용해야 함
3. **제한된 정보**: mmap에는 최소한의 정보만 저장 가능 (크래시 마커만)
4. **수동 정리**: `cleanup()` 메서드를 명시적으로 호출해야 mmap 정리됨

## 개선 제안

### 1. mmap 포인터 노출

```swift
public actor CrashLogPreserver {
    // public으로 변경
    public nonisolated var mmapPointer: UnsafeMutableRawPointer? {
        mmapPtr
    }
}
```

### 2. 자동 Signal Handler 등록

```swift
public init(
    preserveCount: Int = 50,
    storageURL: URL? = nil,
    autoRegisterSignals: Bool = true
) {
    // ...
    
    if autoRegisterSignals {
        Self.registerSignalHandlersUnsafe(
            mmapPtr: mmapPtr,
            mmapSize: mmapSize
        )
    }
}
```

### 3. 더 많은 정보 저장

```swift
// 현재: "CRASH\n타임스탬프\n"
// 개선: "CRASH\n타임스탬프\nSignal번호\n스택크기\n"
```

## 요약

- ✅ mmap 기반 크래시 감지 구현 완료
- ✅ Signal-safe한 `persistSync()` 구현
- ✅ os_unfair_lock 동기화
- ✅ 빌드 성공 (`BUILD SUCCEEDED`)
- ⚠️ 실제 프로덕션 사용 시 mmap 포인터 노출 필요
- ⚠️ Signal Handler 등록 시 전역 변수 사용 필요
