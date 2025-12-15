// OSLogDestination.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation
import OSLog

/// Apple os.log 기반 로그 목적지
/// - Note: 시스템 콘솔에서 확인 가능, Instruments 연동
@available(iOS 14.0, *)
public actor OSLogDestination: LogDestination {
    public let identifier: String = "oslog"
    
    public var minLevel: LogLevel
    public var isEnabled: Bool
    
    /// os.Logger 인스턴스 캐시
    private var loggers: [String: os.Logger] = [:]
    
    /// 서브시스템 (보통 번들 ID)
    private let subsystem: String
    
    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.logger",
        minLevel: LogLevel = .verbose,
        isEnabled: Bool = true
    ) {
        self.subsystem = subsystem
        self.minLevel = minLevel
        self.isEnabled = isEnabled
    }
    
    public func log(_ message: LogMessage) async {
        guard shouldLog(message) else { return }
        
        let logger = getLogger(for: message.category)
        let osLogType = mapLogLevel(message.level)
        
        // os.Logger는 String 인터폴레이션만 지원
        logger.log(level: osLogType, "\(message.message, privacy: .public)")
    }
    
    /// 카테고리별 Logger 인스턴스 반환
    private func getLogger(for category: String) -> os.Logger {
        if let cached = loggers[category] {
            return cached
        }
        
        let logger = os.Logger(subsystem: subsystem, category: category)
        loggers[category] = logger
        return logger
    }
    
    /// LogLevel을 OSLogType으로 변환
    private func mapLogLevel(_ level: LogLevel) -> OSLogType {
        switch level {
        case .verbose:
            return .debug
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .fatal:
            return .fault
        }
    }
}

