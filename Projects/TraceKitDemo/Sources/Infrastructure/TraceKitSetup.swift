// TraceKitSetup.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import FirebaseRemoteConfig
import Foundation
import TraceKit
import TraceKitFirebase

/// TraceKit 초기화 설정
///
/// 데모 앱에서 사용할 TraceKit을 구성합니다.
/// - OSLog 출력 (PrettyTraceFormatter.verbose)
/// - File 출력 (JSONTraceFormatter)
/// - InMemoryTraceDestination
/// - Firebase Crashlytics / Analytics / Performance
/// - Firebase Remote Config
/// - CrashTracePreserver
enum TraceKitSetup {
    static let crashPreserver = CrashTracePreserver(preserveCount: 100)

    @MainActor
    private(set) static var isFirebaseConfigured: Bool = false

    @MainActor
    private static var cachedRemoteConfigManager: FirebaseRemoteConfigManager?

    @MainActor
    static var remoteConfigManager: FirebaseRemoteConfigManager? {
        guard isFirebaseConfigured else { return nil }

        if cachedRemoteConfigManager == nil {
            cachedRemoteConfigManager = FirebaseRemoteConfigManager()
        }

        return cachedRemoteConfigManager
    }

    @MainActor
    static func configure() async {
        let isFirebaseConfigured = configureFirebase()
        Self.isFirebaseConfigured = isFirebaseConfigured

        if !isFirebaseConfigured {
            cachedRemoteConfigManager = nil
        }

        await FirebaseIntegrationRuntime.shared.setPerformanceEnabled(isFirebaseConfigured)

        if let remoteConfigManager = remoteConfigManager {
            await remoteConfigManager.fetchAndActivate()
        }

        await checkPreviousCrash()

        let stream = TraceStream.shared
        let inMemoryDestination = InMemoryTraceDestination(stream: stream)
        let builder = TraceKitBuilder()
            .addOSLog(
                subsystem: "com.tracekit.TraceKitDemo",
                minLevel: .debug,
                formatter: PrettyTraceFormatter.verbose
            )
            .addFile(
                minLevel: .debug,
                retentionPolicy: .default
            )
            .addDestination(inMemoryDestination)
            .with(configuration: .debug)
            .withDefaultSanitizer()
            .withCrashPreserver(crashPreserver)

        if isFirebaseConfigured {
            builder
                .addDestination(FirebaseCrashlyticsTraceDestination())
                .addDestination(FirebaseAnalyticsTraceDestination())
                .addDestination(FirebasePerformanceTraceDestination())
        }

        _ = await builder.buildAsShared()
        await crashPreserver.installSignalHandlers()

        if let remoteConfigManager = remoteConfigManager {
            await remoteConfigManager.applyToTraceKit()
            await remoteConfigManager.startRealtimeUpdates()
            print("✅ [Remote Config] 실시간 업데이트 활성화")
        }

        print("✅ [CrashTracePreserver] 시그널 핸들러 설치 완료")
    }

    @MainActor
    private static func configureFirebase() -> Bool {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("ℹ️ [Firebase] GoogleService-Info.plist 없음, Firebase 연동 비활성화")
            return false
        }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ [Firebase] 초기화 완료")
        }

        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        print("✅ [Firebase Crashlytics] 활성화")
        return true
    }

    @MainActor
    private static func checkPreviousCrash() async {
        do {
            if let logs = try await crashPreserver.recover() {
                print("⚠️ [CrashTracePreserver] 이전 크래시 감지: \(logs.count)개 로그 복구됨")

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

    @MainActor
    static func registerSignalHandlers() {
        Task {
            await crashPreserver.installSignalHandlers()
        }
    }

    static var logDirectory: URL {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDir.appendingPathComponent("Logs", isDirectory: true)
    }
}
