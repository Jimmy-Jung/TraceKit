// TraceKitSetup.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import Foundation
import TraceKit

/// TraceKit 초기화 설정
///
/// 데모 앱에서 사용할 TraceKit을 구성합니다.
/// - OSLog 출력 (PrettyTraceFormatter.verbose) - Xcode 콘솔 및 Console.app
/// - File 출력 (JSONTraceFormatter) - 디바이스에 로그 파일 저장
/// - InMemoryTraceDestination (앱 내 로그 뷰어용)
/// - 민감정보 마스킹 활성화
/// - CrashTracePreserver (크래시 로그 보존)
///
/// ## 사용 예시
/// ```swift
/// Task {
///     await TraceKitSetup.configure()
/// }
/// ```
///
/// ## 구성된 Destination
/// | Destination | 용도 |
/// |------------|------|
/// | OSLog | Xcode 콘솔, Console.app, Instruments 연동 (PrettyTraceFormatter 적용) |
/// | File | 디바이스에 JSON 형식 로그 파일 저장 (7일 보관) |
/// | InMemory | TraceViewer 화면에서 실시간 로그 확인 |
/// | CrashTracePreserver | 크래시 직전 로그 보존 및 복구 |
///
/// ## 로그 파일 위치
/// `Library/Caches/Logs/log-YYYY-MM-DD.log`
///
/// - Note: 앱 시작 시 `TraceKitDemoApp.init()`에서 호출됩니다.
enum TraceKitSetup {
    /// 공유 CrashTracePreserver 인스턴스
    static let crashPreserver = CrashTracePreserver(preserveCount: 100)

    /// TraceKit 초기화
    ///
    /// 앱 시작 시 한 번 호출하여 TraceKit을 구성합니다.
    /// 전역 TraceKit 인스턴스가 설정되며, static 메서드를 통해 접근할 수 있습니다.
    ///
    /// - Important: MainActor에서 실행되어야 합니다.
    @MainActor
    static func configure() async {
        // 이전 크래시 확인
        await checkPreviousCrash()

        let stream = TraceStream.shared
        let inMemoryDestination = InMemoryTraceDestination(stream: stream)

        _ = await TraceKitBuilder()
            .addOSLog(
                subsystem: "com.tracekit.TraceKitDemo",
                formatter: PrettyTraceFormatter.verbose
            )
            .addFile(
                minLevel: .debug,
                retentionPolicy: .default
            )
            .addDestination(inMemoryDestination)
            .with(configuration: .debug)
            .withDefaultSanitizer()
            .buildAsShared()

        // Signal Handler 등록 (전역 mmap 포인터 사용)
        // registerSignalHandlers()
    }

    /// 이전 크래시 확인 및 로그 복구
    @MainActor
    private static func checkPreviousCrash() async {
        do {
            if let logs = try await crashPreserver.recover() {
                print("⚠️ [CrashTracePreserver] 이전 크래시 감지: \(logs.count)개 로그 복구됨")

                // 복구된 로그 출력 (상위 5개만)
                for log in logs.prefix(5) {
                    print("  - [\(log.level.name)] \(log.message)")
                }

                if logs.count > 5 {
                    print("  ... 외 \(logs.count - 5)개")
                }
            }
        } catch {
            print("⚠️ [CrashTracePreserver] 크래시 로그 복구 실패: \(error)")
        }
    }

    /// Signal Handler 등록 (옵션)
    /// - Warning: 프로덕션에서 사용 시 주의 필요
    @MainActor
    static func registerSignalHandlers() {
        // CrashTracePreserver.registerSignalHandlersUnsafe(...)
        // 주의: Actor의 mmap 포인터에 직접 접근할 수 없으므로
        // 실제 구현 시 전역 변수나 다른 방법 필요
    }

    /// 로그 파일 디렉토리 URL
    static var logDirectory: URL {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDir.appendingPathComponent("Logs", isDirectory: true)
    }
}
