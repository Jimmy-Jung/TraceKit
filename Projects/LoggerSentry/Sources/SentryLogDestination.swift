// SentryLogDestination.swift
// LoggerSentry
//
// Created by jimmy on 2025-12-15.

import Foundation
import Logger
import Sentry

/// Sentry 로그 목적지
/// - Note: Sentry로 로그 및 에러 전송
public actor SentryLogDestination: LogDestination {
    public let identifier: String = "sentry"
    
    public var minLevel: LogLevel
    public var isEnabled: Bool
    
    /// Breadcrumb로 전송할 최소 레벨
    private let breadcrumbMinLevel: LogLevel
    
    /// 이벤트로 전송할 최소 레벨
    private let eventMinLevel: LogLevel
    
    public init(
        dsn: String,
        minLevel: LogLevel = .info,
        isEnabled: Bool = true,
        breadcrumbMinLevel: LogLevel = .debug,
        eventMinLevel: LogLevel = .error,
        environment: String = "development",
        debug: Bool = false
    ) {
        self.minLevel = minLevel
        self.isEnabled = isEnabled
        self.breadcrumbMinLevel = breadcrumbMinLevel
        self.eventMinLevel = eventMinLevel
        
        // Sentry 초기화 (이미 초기화되어 있으면 스킵)
        if SentrySDK.isEnabled == false {
            SentrySDK.start { options in
                options.dsn = dsn
                options.environment = environment
                options.debug = debug
                options.enableAutoSessionTracking = true
                options.attachStacktrace = true
            }
        }
    }
    
    public func log(_ message: LogMessage) async {
        guard shouldLog(message) else { return }
        
        // Breadcrumb 추가
        if message.level >= breadcrumbMinLevel {
            addBreadcrumb(from: message)
        }
        
        // 이벤트 전송
        if message.level >= eventMinLevel {
            sendEvent(from: message)
        }
    }
    
    // MARK: - Private
    
    private func addBreadcrumb(from message: LogMessage) {
        let breadcrumb = Breadcrumb()
        breadcrumb.level = mapToSentryLevel(message.level)
        breadcrumb.category = message.category
        breadcrumb.message = message.message
        breadcrumb.timestamp = message.timestamp
        
        if let metadata = message.metadata {
            breadcrumb.data = metadata.mapValues { $0.value }
        }
        
        SentrySDK.addBreadcrumb(breadcrumb)
    }
    
    private func sendEvent(from message: LogMessage) {
        let event = Event(level: mapToSentryLevel(message.level))
        event.message = SentryMessage(formatted: message.message)
        event.timestamp = message.timestamp
        event.logger = message.category
        
        // 위치 정보 추가
        event.extra = [
            "file": message.fileName,
            "function": message.function,
            "line": message.line
        ]
        
        // 메타데이터 추가
        if let metadata = message.metadata {
            for (key, value) in metadata {
                event.extra?[key] = value.value
            }
        }
        
        // 사용자 컨텍스트 추가
        if let userContext = message.userContext {
            if let userId = userContext.userId {
                let user = User()
                user.userId = userId
                SentrySDK.setUser(user)
            }
            
            event.tags = [
                "appVersion": userContext.appVersion,
                "osVersion": userContext.osVersion,
                "deviceModel": userContext.deviceModel
            ]
        }
        
        SentrySDK.capture(event: event)
    }
    
    private func mapToSentryLevel(_ level: LogLevel) -> SentryLevel {
        switch level {
        case .verbose, .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .fatal:
            return .fatal
        }
    }
}

// MARK: - User Context

extension SentryLogDestination {
    /// 사용자 정보 설정
    public func setUser(id: String?, email: String? = nil, username: String? = nil) {
        if let id = id {
            let user = User()
            user.userId = id
            user.email = email
            user.username = username
            SentrySDK.setUser(user)
        } else {
            SentrySDK.setUser(nil)
        }
    }
    
    /// 추가 컨텍스트 설정
    public func setContext(key: String, value: [String: Any]) {
        SentrySDK.configureScope { scope in
            scope.setContext(value: value, key: key)
        }
    }
    
    /// 태그 설정
    public func setTag(key: String, value: String) {
        SentrySDK.configureScope { scope in
            scope.setTag(value: value, key: key)
        }
    }
}

