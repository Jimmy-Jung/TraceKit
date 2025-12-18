// DatadogTraceDestination.swift
// TraceKitDatadog
//
// Created by jimmy on 2025-12-15.

import DatadogLogs
import Foundation
import TraceKit

/// Datadog 로그 목적지
/// - Note: Datadog으로 구조화된 로그 전송
public actor DatadogTraceDestination: TraceDestination {
    public let identifier: String = "datadog"

    public var minLevel: TraceLevel
    public var isEnabled: Bool

    /// Datadog Logger 인스턴스
    private var datadogLogger: LoggerProtocol?

    /// 서비스 이름
    private let serviceName: String

    public init(
        clientToken _: String,
        environment _: String,
        serviceName: String,
        minLevel: TraceLevel = .info,
        isEnabled: Bool = true
    ) {
        self.minLevel = minLevel
        self.isEnabled = isEnabled
        self.serviceName = serviceName

        // Datadog Logs 설정
        Logs.enable(with: Logs.Configuration())

        // Logger 생성
        datadogLogger = DatadogLogs.Logger.create(
            with: DatadogLogs.Logger.Configuration(
                name: serviceName,
                networkInfoEnabled: true,
                bundleWithRumEnabled: true,
                bundleWithTraceEnabled: true
            )
        )
    }

    public func log(_ message: TraceMessage) async {
        guard shouldLog(message), let logger = datadogLogger else { return }

        // 속성 준비
        var attributes: [String: Encodable] = [
            "file": message.fileName,
            "function": message.function,
            "line": message.line,
            "category": message.category,
        ]

        // 메타데이터 추가
        if let metadata = message.metadata {
            for (key, value) in metadata {
                attributes[key] = String(describing: value.value)
            }
        }

        // 사용자 컨텍스트 추가
        if let userContext = message.userContext {
            attributes["userId"] = userContext.userId
            attributes["sessionId"] = userContext.sessionId
            attributes["appVersion"] = userContext.appVersion
            attributes["osVersion"] = userContext.osVersion
            attributes["deviceModel"] = userContext.deviceModel
        }

        // 레벨에 따라 로그 전송
        switch message.level {
        case .verbose, .debug:
            logger.debug(message.message, attributes: attributes)
        case .info:
            logger.info(message.message, attributes: attributes)
        case .warning:
            logger.warn(message.message, attributes: attributes)
        case .error:
            logger.error(message.message, attributes: attributes)
        case .fatal:
            logger.critical(message.message, attributes: attributes)
        }
    }
}

// MARK: - Context Management

public extension DatadogTraceDestination {
    /// 전역 속성 추가
    func addAttribute(key: String, value: Encodable) {
        datadogLogger?.addAttribute(forKey: key, value: value)
    }

    /// 전역 속성 제거
    func removeAttribute(key: String) {
        datadogLogger?.removeAttribute(forKey: key)
    }

    /// 태그 추가
    func addTag(key: String, value: String) {
        datadogLogger?.addTag(withKey: key, value: value)
    }

    /// 태그 제거
    func removeTag(key: String) {
        datadogLogger?.removeTag(withKey: key)
    }
}
