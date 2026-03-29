// FirebaseRemoteConfigManager.swift
// TraceKitDemo
//
// Created by jimmy on 2026-01-22.

import Foundation
import TraceKit
import FirebaseRemoteConfig

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
///
/// ## 사용 예시
/// ```swift
/// let manager = FirebaseRemoteConfigManager()
/// await manager.fetchAndActivate()
/// await manager.applyToTraceKit()
/// ```
actor FirebaseRemoteConfigManager {
    private let remoteConfig: RemoteConfig
    private let fetchInterval: TimeInterval = 3600 // 1시간
    private var configUpdateListenerRegistration: ConfigUpdateListenerRegistration?
    
    init() {
        remoteConfig = RemoteConfig.remoteConfig()
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = fetchInterval
        remoteConfig.configSettings = settings
        
        let defaults: [String: NSObject] = [
            "tracekit_min_level": "info" as NSObject,
            "tracekit_sampling_rate": 1.0 as NSObject,
            "tracekit_enable_crashlytics": true as NSObject,
            "tracekit_enable_analytics": true as NSObject,
            "tracekit_enable_performance": true as NSObject,
            "tracekit_enable_sanitizer": true as NSObject
        ]
        
        remoteConfig.setDefaults(defaults)
    }
    
    deinit {
        configUpdateListenerRegistration?.remove()
    }
    
    /// Remote Config 값 가져오기 및 활성화
    ///
    /// 서버에서 최신 설정을 가져와 활성화합니다.
    /// minimumFetchInterval을 고려하므로 캐시된 값을 사용할 수 있습니다.
    /// 실패 시 기본값을 사용합니다.
    ///
    /// - Returns: 성공 여부
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
    
    /// Remote Config 값 즉시 가져오기 및 활성화
    ///
    /// minimumFetchInterval을 무시하고 서버에서 즉시 최신 설정을 가져옵니다.
    /// UI에서 "새로고침" 버튼을 눌렀을 때 사용합니다.
    ///
    /// - Returns: 성공 여부
    @discardableResult
    func fetchAndActivateImmediately() async -> Bool {
        do {
            // fetch(withExpirationDuration: 0)으로 캐시를 무시하고 즉시 가져옴
            try await remoteConfig.fetch(withExpirationDuration: 0)
            try await remoteConfig.activate()
            
            print("✅ [Remote Config] 즉시 가져오기 성공 (캐시 무시)")
            return true
        } catch {
            print("❌ [Remote Config] 즉시 가져오기 실패: \(error)")
            return false
        }
    }
    
    /// 실시간 Remote Config 업데이트 리스너 시작
    ///
    /// Firebase Console에서 설정을 변경하면 자동으로 알림을 받아 TraceKit에 즉시 적용합니다.
    /// - Note: 앱이 포그라운드에 있을 때만 동작합니다.
    ///
    /// - Parameter onChange: 설정 변경 시 호출될 콜백
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
                // 변경된 설정 활성화
                do {
                    try await self.remoteConfig.activate()
                    print("✅ [Remote Config] 변경된 설정 활성화 완료")
                    
                    // TraceKit에 자동 적용
                    await self.applyToTraceKit()
                    
                    // UI 업데이트를 위한 Notification 발송
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .remoteConfigDidUpdate,
                            object: nil,
                            userInfo: ["updatedKeys": configUpdate.updatedKeys]
                        )
                    }
                    
                    // 콜백 실행
                    await onChange?()
                } catch {
                    print("❌ [Remote Config] 활성화 실패: \(error)")
                }
            }
        }
        
        print("👂 [Remote Config] 실시간 업데이트 리스너 시작")
    }
    
    /// 실시간 업데이트 리스너 중지
    func stopRealtimeUpdates() {
        configUpdateListenerRegistration?.remove()
        configUpdateListenerRegistration = nil
        print("🛑 [Remote Config] 실시간 업데이트 리스너 중지")
    }
    
    /// Remote Config 설정을 TraceKit에 적용
    ///
    /// Remote Config의 값을 읽어 TraceKit 동작을 동적으로 변경합니다.
    func applyToTraceKit() async {
        let config = buildTraceKitConfiguration()
        await FirebaseIntegrationRuntime.shared.setPerformanceEnabled(isPerformanceEnabled)
        
        // TraceKit 런타임 설정 업데이트
        await TraceKit.async.configure(config)
        
        print("✅ [Remote Config] TraceKit 설정 적용 완료")
        printCurrentConfiguration()
    }
    
    /// Remote Config 값으로 TraceKitConfiguration 생성
    private func buildTraceKitConfiguration() -> TraceKitConfiguration {
        let minLevel = minimumTraceLevel
        let samplingRate = self.samplingRate
        let sanitizerEnabled = self.isSanitizerEnabled
        var disabledDestinations: Set<String> = []

        if !isCrashlyticsEnabled {
            disabledDestinations.insert("firebase.crashlytics")
        }

        if !isAnalyticsEnabled {
            disabledDestinations.insert("firebase.analytics")
        }
        
        return TraceKitConfiguration(
            minLevel: minLevel,
            disabledDestinations: disabledDestinations,
            isSanitizingEnabled: sanitizerEnabled,
            sampleRate: samplingRate,
            bufferSize: 1000
        )
    }
    
    /// 최소 로그 레벨
    var minimumTraceLevel: TraceLevel {
        let levelString = remoteConfig["tracekit_min_level"].stringValue
        return parseTraceLevel(levelString)
    }
    
    /// 샘플링 비율 (0.0 ~ 1.0)
    var samplingRate: Double {
        let rate = remoteConfig["tracekit_sampling_rate"].numberValue.doubleValue
        return max(0.0, min(1.0, rate))
    }
    
    /// Crashlytics 연동 활성화 여부
    var isCrashlyticsEnabled: Bool {
        remoteConfig["tracekit_enable_crashlytics"].boolValue
    }
    
    /// Analytics 연동 활성화 여부
    var isAnalyticsEnabled: Bool {
        remoteConfig["tracekit_enable_analytics"].boolValue
    }
    
    /// Performance 연동 활성화 여부
    var isPerformanceEnabled: Bool {
        remoteConfig["tracekit_enable_performance"].boolValue
    }
    
    /// 민감정보 마스킹 활성화 여부
    var isSanitizerEnabled: Bool {
        remoteConfig["tracekit_enable_sanitizer"].boolValue
    }
    
    /// 문자열을 TraceLevel로 파싱
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
    
    /// 현재 적용된 설정 출력
    private func printCurrentConfiguration() {
        print("""
        [Remote Config] 현재 설정:
        - 최소 로그 레벨: \(minimumTraceLevel.name)
        - 샘플링 비율: \(String(format: "%.2f", samplingRate))
        - Crashlytics: \(isCrashlyticsEnabled ? "활성화" : "비활성화")
        - Analytics: \(isAnalyticsEnabled ? "활성화" : "비활성화")
        - Performance: \(isPerformanceEnabled ? "활성화" : "비활성화")
        - Sanitizer: \(isSanitizerEnabled ? "활성화" : "비활성화")
        """)
    }
}

// MARK: - Notification

extension Notification.Name {
    /// Remote Config 설정이 업데이트되었을 때 발송되는 알림
    static let remoteConfigDidUpdate = Notification.Name("remoteConfigDidUpdate")
}
