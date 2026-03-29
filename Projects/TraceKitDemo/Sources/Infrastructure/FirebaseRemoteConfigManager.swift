// FirebaseRemoteConfigManager.swift
// TraceKitDemo
//
// Created by jimmy on 2026-01-22.

import FirebaseRemoteConfig
import Foundation
import TraceKit

/// Firebase Remote Config를 사용한 TraceKit 동적 설정 관리
///
/// 앱 업데이트 없이 TraceKit의 동작을 원격으로 제어합니다.
/// A/B 테스트, 긴급 디버깅 모드 활성화, 프로덕션 환경 모니터링 강화 등에 활용됩니다.
///
/// ## Remote Config 키
/// - `tracekit_min_level`: 최소 로그 레벨 (verbose, debug, info, warning, error, fatal)
/// - `tracekit_sampling_rate`: 샘플링 비율 (0.0 ~ 1.0)
/// - `tracekit_enable_crashlytics`: Crashlytics 연동 활성화
/// - `tracekit_enable_analytics`: Analytics 연동 활성화
/// - `tracekit_enable_performance`: Performance 연동 활성화
/// - `tracekit_enable_sanitizer`: 민감정보 마스킹 활성화
actor FirebaseRemoteConfigManager {
    private let remoteConfig: RemoteConfig
    private let fetchInterval: TimeInterval = 3600
    private var configUpdateListenerRegistration: ConfigUpdateListenerRegistration?

    init() {
        remoteConfig = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = fetchInterval
        remoteConfig.configSettings = settings

        let defaults: [String: NSObject] = [
            "tracekit_min_level": "debug" as NSObject,
            "tracekit_sampling_rate": 1.0 as NSObject,
            "tracekit_enable_crashlytics": true as NSObject,
            "tracekit_enable_analytics": true as NSObject,
            "tracekit_enable_performance": true as NSObject,
            "tracekit_enable_sanitizer": true as NSObject,
        ]

        remoteConfig.setDefaults(defaults)
    }

    deinit {
        configUpdateListenerRegistration?.remove()
    }

    @discardableResult
    func fetchAndActivate() async -> Bool {
        do {
            let status = try await remoteConfig.fetchAndActivate()
            let success = status == .successFetchedFromRemote || status == .successUsingPreFetchedData

            if success {
                if status == .successFetchedFromRemote {
                    print("✅ [Remote Config] 설정 가져오기 성공 (서버에서 최신)")
                } else {
                    print("✅ [Remote Config] 설정 가져오기 성공 (캐시 사용)")
                }
            } else {
                print("⚠️ [Remote Config] 변경사항 없음")
            }

            return success
        } catch {
            print("❌ [Remote Config] 설정 가져오기 실패: \(error)")
            return false
        }
    }

    @discardableResult
    func fetchAndActivateImmediately() async -> Bool {
        do {
            try await remoteConfig.fetch(withExpirationDuration: 0)
            try await remoteConfig.activate()

            print("✅ [Remote Config] 즉시 가져오기 성공 (캐시 무시)")
            return true
        } catch {
            print("❌ [Remote Config] 즉시 가져오기 실패: \(error)")
            return false
        }
    }

    func startRealtimeUpdates(onChange: (@Sendable () async -> Void)? = nil) {
        configUpdateListenerRegistration = remoteConfig.addOnConfigUpdateListener { [weak self] configUpdate, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ [Remote Config] 실시간 업데이트 오류: \(error)")
                return
            }

            guard let configUpdate = configUpdate else {
                print("⚠️ [Remote Config] 업데이트 정보 없음")
                return
            }

            print("🔔 [Remote Config] 설정 변경 감지 - 업데이트된 키: \(configUpdate.updatedKeys)")

            Task {
                do {
                    try await self.remoteConfig.activate()
                    print("✅ [Remote Config] 변경된 설정 활성화 완료")

                    await self.applyToTraceKit()

                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .remoteConfigDidUpdate,
                            object: nil,
                            userInfo: ["updatedKeys": configUpdate.updatedKeys]
                        )
                    }

                    await onChange?()
                } catch {
                    print("❌ [Remote Config] 활성화 실패: \(error)")
                }
            }
        }

        print("👂 [Remote Config] 실시간 업데이트 리스너 시작")
    }

    func stopRealtimeUpdates() {
        configUpdateListenerRegistration?.remove()
        configUpdateListenerRegistration = nil
        print("🛑 [Remote Config] 실시간 업데이트 리스너 중지")
    }

    func applyToTraceKit() async {
        let config = buildTraceKitConfiguration()
        await FirebaseIntegrationRuntime.shared.setPerformanceEnabled(isPerformanceEnabled)
        await TraceKit.async.configure(config)

        print("✅ [Remote Config] TraceKit 설정 적용 완료")
        printCurrentConfiguration()
    }

    private func buildTraceKitConfiguration() -> TraceKitConfiguration {
        let minLevel = minimumTraceLevel
        let samplingRate = self.samplingRate
        let sanitizerEnabled = isSanitizerEnabled
        var disabledDestinations: Set<String> = []

        if !isCrashlyticsEnabled {
            disabledDestinations.insert("firebase.crashlytics")
        }

        if !isAnalyticsEnabled {
            disabledDestinations.insert("firebase.analytics")
        }

        if !isPerformanceEnabled {
            disabledDestinations.insert("firebase.performance")
        }

        return TraceKitConfiguration(
            minLevel: minLevel,
            disabledDestinations: disabledDestinations,
            isSanitizingEnabled: sanitizerEnabled,
            sampleRate: samplingRate,
            bufferSize: 1000
        )
    }

    var minimumTraceLevel: TraceLevel {
        let levelString = remoteConfig["tracekit_min_level"].stringValue
        return parseTraceLevel(levelString)
    }

    var samplingRate: Double {
        let rate = remoteConfig["tracekit_sampling_rate"].numberValue.doubleValue
        return max(0.0, min(1.0, rate))
    }

    var isCrashlyticsEnabled: Bool {
        remoteConfig["tracekit_enable_crashlytics"].boolValue
    }

    var isAnalyticsEnabled: Bool {
        remoteConfig["tracekit_enable_analytics"].boolValue
    }

    var isPerformanceEnabled: Bool {
        remoteConfig["tracekit_enable_performance"].boolValue
    }

    var isSanitizerEnabled: Bool {
        remoteConfig["tracekit_enable_sanitizer"].boolValue
    }

    private func parseTraceLevel(_ string: String) -> TraceLevel {
        switch string.lowercased() {
        case "verbose": return .verbose
        case "debug": return .debug
        case "info": return .info
        case "warning", "warn": return .warning
        case "error": return .error
        case "fatal": return .fatal
        default: return .info
        }
    }

    private func printCurrentConfiguration() {
        print(
            """
            📊 [Remote Config] 현재 설정:
              - minLevel: \(minimumTraceLevel.name)
              - samplingRate: \(samplingRate)
              - Crashlytics: \(isCrashlyticsEnabled ? "ON" : "OFF")
              - Analytics: \(isAnalyticsEnabled ? "ON" : "OFF")
              - Performance: \(isPerformanceEnabled ? "ON" : "OFF")
              - Sanitizer: \(isSanitizerEnabled ? "ON" : "OFF")
            """
        )
    }
}

// MARK: - Notification

extension Notification.Name {
    static let remoteConfigDidUpdate = Notification.Name("remoteConfigDidUpdate")
}
