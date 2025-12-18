// CrashlyticsTraceDestination.swift
// TraceKitFirebase
//
// Created by jimmy on 2025-12-15.

import FirebaseCrashlytics
import Foundation
import TraceKit

/// Firebase Crashlytics 로그 목적지
/// - Note: Crashlytics로 로그 및 크래시 정보 전송
public actor CrashlyticsTraceDestination: TraceDestination {
    public let identifier: String = "crashlytics"

    public var minLevel: TraceLevel
    public var isEnabled: Bool

    /// Crashlytics 인스턴스
    private let crashlytics: Crashlytics

    public init(
        minLevel: TraceLevel = .info,
        isEnabled: Bool = true
    ) {
        self.minLevel = minLevel
        self.isEnabled = isEnabled
        crashlytics = Crashlytics.crashlytics()
    }

    public func log(_ message: TraceMessage) async {
        guard shouldLog(message) else { return }

        // 로그 메시지 기록
        let logLine = "[\(message.level.name)] [\(message.category)] \(message.message)"
        crashlytics.log(logLine)

        // 사용자 컨텍스트 설정
        if let userContext = message.userContext {
            if let userId = userContext.userId {
                crashlytics.setUserID(userId)
            }

            crashlytics.setCustomValue(userContext.appVersion, forKey: "appVersion")
            crashlytics.setCustomValue(userContext.osVersion, forKey: "osVersion")
            crashlytics.setCustomValue(userContext.deviceModel, forKey: "deviceModel")
        }

        // 메타데이터를 커스텀 키로 설정
        if let metadata = message.metadata {
            for (key, value) in metadata {
                crashlytics.setCustomValue(String(describing: value.value), forKey: key)
            }
        }

        // Error/Fatal 레벨은 Non-fatal error로 기록
        if message.level >= .error {
            let error = NSError(
                domain: message.category,
                code: message.level.rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey: message.message,
                    "file": message.fileName,
                    "function": message.function,
                    "line": message.line,
                ]
            )
            crashlytics.record(error: error)
        }
    }
}

// MARK: - User Management

public extension CrashlyticsTraceDestination {
    /// 사용자 ID 설정
    func setUserId(_ userId: String?) {
        if let userId = userId {
            crashlytics.setUserID(userId)
        }
    }

    /// 커스텀 키 설정
    func setCustomKey(_ key: String, value: Any) {
        crashlytics.setCustomValue(value, forKey: key)
    }

    /// 커스텀 키 여러 개 설정
    func setCustomKeys(_ keysAndValues: [String: Any]) {
        crashlytics.setCustomKeysAndValues(keysAndValues)
    }
}
