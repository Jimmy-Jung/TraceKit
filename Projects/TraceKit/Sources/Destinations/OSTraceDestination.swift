// OSTraceDestination.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation
import os.log

/// OSLog 출력 로그 목적지
/// - Note: Apple의 통합 로깅 시스템 (Console.app에서 확인 가능)
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public actor OSTraceDestination: TraceDestination {
    public let identifier: String = "oslog"

    public var minLevel: TraceLevel
    public var isEnabled: Bool

    /// OSLog 로거
    private let logger: os.Logger

    /// 로그 포맷터 (옵셔널)
    private let formatter: TraceFormatter?

    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.tracekit",
        category: String = "default",
        minLevel: TraceLevel = .verbose,
        isEnabled: Bool = true,
        formatter: TraceFormatter? = nil
    ) {
        logger = os.Logger(subsystem: subsystem, category: category)
        self.minLevel = minLevel
        self.isEnabled = isEnabled
        self.formatter = formatter
    }

    public func log(_ message: TraceMessage) async {
        guard shouldLog(message) else { return }

        let formattedMessage = formatter?.format(message) ?? message.message
        let osLogType = message.level.osLogType

        logger.log(level: osLogType, "\(formattedMessage)")
    }
}

// MARK: - TraceLevel+OSLogType

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private extension TraceLevel {
    var osLogType: OSLogType {
        switch self {
        case .verbose, .debug:
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
