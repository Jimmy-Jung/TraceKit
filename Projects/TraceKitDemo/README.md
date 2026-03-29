# 📱 TraceKitDemo

TraceKit의 기능을 체험할 수 있는 데모 앱입니다.

## 🚀 실행 방법

### 1. Firebase 설정 (Optional)

Firebase 기능을 사용하려면 자신의 Firebase 프로젝트를 설정하세요:

1. [Firebase Console](https://console.firebase.google.com/)에서 새 프로젝트 생성
2. iOS 앱 추가 (Bundle ID: `com.tracekit.TraceKitDemo`)
3. `GoogleService-Info.plist` 다운로드
4. 다운로드한 파일을 `Projects/TraceKitDemo/Resources/` 폴더에 복사

```bash
# 예시 파일이 제공됩니다
cp Projects/TraceKitDemo/Resources/GoogleService-Info.plist.example \
   Projects/TraceKitDemo/Resources/GoogleService-Info.plist

# 위 파일을 편집하여 자신의 Firebase 설정을 입력하세요
```

> **참고**: Firebase 설정 없이도 앱의 기본 기능은 모두 사용 가능합니다. Firebase 연동 기능만 비활성화됩니다.

### 2. Tuist로 프로젝트 생성

```bash
cd Projects/TraceKitDemo
tuist generate
```

### 3. Xcode에서 열기

```bash
open TraceKitDemo.xcworkspace
```

### 4. 실행

- Scheme 선택: **TraceKitDemo**
- Simulator 선택: **iPhone 15 Pro**
- **⌘ + R** (실행)

---

## 📦 구조

```
TraceKitDemo/
├── Tuist.swift          # Tuist 설정
├── Project.swift        # 프로젝트 매니페스트
└── Sources/
    ├── App/             # 앱 진입점
    ├── Design/          # UI 컴포넌트, 테마
    ├── Infrastructure/  # TraceKit 설정, 스트림
    └── Presentation/    # 화면별 View/ViewModel
        ├── LogGenerator/
        ├── LogViewer/
        ├── CrashDemo/
        ├── Sanitizer/
        ├── Performance/
        └── Settings/
```

---

## 🎨 기능

### 1. Log Generator
- 다양한 로그 레벨 생성
- 카테고리별 로그 테스트
- 메타데이터 포함 로그

### 2. Log Viewer
- 실시간 로그 스트림
- 레벨/카테고리 필터링
- 로그 상세 보기

### 3. Crash Demo
- 강제 크래시 발생
- 크래시 로그 복구
- 크래시 전후 로그 확인

### 4. Sanitizer Demo
- 민감정보 마스킹 테스트
- 이메일, 전화번호, 카드번호 등
- 커스텀 패턴 추가

### 5. Performance
- Span 생성 및 종료
- 중첩 Span 측정
- 성능 메트릭 확인

### 6. Settings
- 로그 레벨 설정
- 샘플링 비율 조정
- 버퍼 크기 설정
- 로그 파일 관리

---

## 🔧 의존성

TraceKitDemo는 로컬 SPM 패키지를 참조합니다:

```swift
packages: [
    .local(path: .relativeToRoot("../../"))
]

dependencies: [
    .package(product: "TraceKit", type: .runtime)
]
```

루트의 `Package.swift`에서 TraceKit을 빌드합니다.

---

## 🔥 Firebase 연동 (Optional)

TraceKitDemo는 Firebase Analytics, Crashlytics, Performance Monitoring과 선택적으로 연동할 수 있습니다.

### Firebase 기능

1. **Analytics**: 커스텀 이벤트 로깅
2. **Crashlytics**: 크래시 리포트 전송
3. **Performance**: 네트워크 및 커스텀 성능 추적

### 설정 방법

자세한 Firebase 연동 가이드는 [FIREBASE_MODULES_GUIDE.md](FIREBASE_MODULES_GUIDE.md)를 참고하세요.

---

## 🐛 문제 해결

### "No such module 'TraceKit'" 에러

**해결책:**
```bash
# 패키지 캐시 초기화
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf .build

# 다시 생성
tuist clean
tuist generate
```

### Tuist 버전 확인

```bash
tuist version
# 4.0 이상 권장
```

---

## 📚 더 알아보기

- [TraceKit 문서](../../Documents/)
- [Tuist 공식 문서](https://docs.tuist.io)
