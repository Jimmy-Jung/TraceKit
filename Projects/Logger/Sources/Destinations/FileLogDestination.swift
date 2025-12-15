// FileLogDestination.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 파일 출력 로그 목적지
/// - Note: 로그를 파일에 저장하여 추후 분석/업로드 가능
public actor FileLogDestination: LogDestination {
    public let identifier: String = "file"
    
    public var minLevel: LogLevel
    public var isEnabled: Bool
    
    /// 로그 포맷터
    private let formatter: LogFormatter
    
    /// 파일 관리자
    private let fileManager: LogFileManager
    
    /// 내부 버퍼
    private var buffer: [String] = []
    
    /// 버퍼 플러시 크기
    private let bufferSize: Int
    
    public init(
        minLevel: LogLevel = .verbose,
        isEnabled: Bool = true,
        formatter: LogFormatter = JSONLogFormatter(),
        fileManager: LogFileManager,
        bufferSize: Int = 10
    ) {
        self.minLevel = minLevel
        self.isEnabled = isEnabled
        self.formatter = formatter
        self.fileManager = fileManager
        self.bufferSize = bufferSize
    }
    
    public func log(_ message: LogMessage) async {
        guard shouldLog(message) else { return }
        
        let formattedMessage = formatter.format(message)
        buffer.append(formattedMessage)
        
        if buffer.count >= bufferSize {
            await flushBuffer()
        }
    }
    
    public func flush(_ messages: [LogMessage]) async {
        for message in messages {
            if shouldLog(message) {
                let formattedMessage = formatter.format(message)
                buffer.append(formattedMessage)
            }
        }
        await flushBuffer()
    }
    
    /// 버퍼를 파일에 쓰기
    private func flushBuffer() async {
        guard !buffer.isEmpty else { return }
        
        let linesToWrite = buffer
        buffer.removeAll()
        
        let content = linesToWrite.joined(separator: "\n") + "\n"
        
        do {
            try await fileManager.append(content)
        } catch {
            // 파일 쓰기 실패 시 콘솔에 출력
            print("[FileLogDestination] Failed to write logs: \(error)")
        }
    }
    
    /// 남은 버퍼 강제 플러시
    public func forceFlush() async {
        await flushBuffer()
    }
}

