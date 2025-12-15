// ConsoleLogDestination.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 콘솔 출력 로그 목적지
/// - Note: print/debugPrint를 통한 콘솔 출력
public actor ConsoleLogDestination: LogDestination {
    public let identifier: String = "console"
    
    public var minLevel: LogLevel
    public var isEnabled: Bool
    
    /// 로그 포맷터
    private let formatter: LogFormatter
    
    /// 출력 스트림 (stdout/stderr)
    public enum OutputStream: Sendable {
        case stdout
        case stderr
        case auto  // error, fatal은 stderr, 나머지는 stdout
    }
    
    private let outputStream: OutputStream
    
    public init(
        minLevel: LogLevel = .verbose,
        isEnabled: Bool = true,
        formatter: LogFormatter = PrettyLogFormatter.standard,
        outputStream: OutputStream = .auto
    ) {
        self.minLevel = minLevel
        self.isEnabled = isEnabled
        self.formatter = formatter
        self.outputStream = outputStream
    }
    
    public func log(_ message: LogMessage) async {
        guard shouldLog(message) else { return }
        
        let formattedMessage = formatter.format(message)
        
        switch outputStream {
        case .stdout:
            print(formattedMessage)
        case .stderr:
            fputs("\(formattedMessage)\n", stderr)
        case .auto:
            if message.level >= .error {
                fputs("\(formattedMessage)\n", stderr)
            } else {
                print(formattedMessage)
            }
        }
    }
}

