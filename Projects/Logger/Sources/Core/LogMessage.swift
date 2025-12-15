// LogMessage.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로그 메시지 값 객체
/// - Note: 불변 구조체로 스레드 안전성 보장
public struct LogMessage: Codable, Sendable, Identifiable {
    /// 고유 식별자
    public let id: UUID
    
    /// 로그 레벨
    public let level: LogLevel
    
    /// 로그 메시지 본문
    public let message: String
    
    /// 로그 카테고리 (예: "Network", "Auth", "UI")
    public let category: String
    
    /// 추가 메타데이터
    public let metadata: [String: AnyCodable]?
    
    /// 사용자 컨텍스트
    public let userContext: UserContext?
    
    /// 로그 발생 시간
    public let timestamp: Date
    
    /// 로그 호출 파일 경로
    public let file: String
    
    /// 로그 호출 함수명
    public let function: String
    
    /// 로그 호출 라인 번호
    public let line: Int
    
    public init(
        id: UUID = UUID(),
        level: LogLevel,
        message: String,
        category: String,
        metadata: [String: AnyCodable]? = nil,
        userContext: UserContext? = nil,
        timestamp: Date = Date(),
        file: String,
        function: String,
        line: Int
    ) {
        self.id = id
        self.level = level
        self.message = message
        self.category = category
        self.metadata = metadata
        self.userContext = userContext
        self.timestamp = timestamp
        self.file = file
        self.function = function
        self.line = line
    }
    
    /// 파일명만 추출 (경로 제외)
    public var fileName: String {
        (file as NSString).lastPathComponent
    }
    
    /// 마스킹된 메시지로 새 LogMessage 생성
    /// - Parameter sanitizedMessage: 마스킹 처리된 메시지
    /// - Returns: 메시지가 교체된 새 LogMessage
    public func withSanitizedMessage(_ sanitizedMessage: String) -> LogMessage {
        LogMessage(
            id: id,
            level: level,
            message: sanitizedMessage,
            category: category,
            metadata: metadata,
            userContext: userContext,
            timestamp: timestamp,
            file: file,
            function: function,
            line: line
        )
    }
    
    /// 사용자 컨텍스트가 추가된 새 LogMessage 생성
    /// - Parameter context: 추가할 사용자 컨텍스트
    /// - Returns: 컨텍스트가 추가된 새 LogMessage
    public func withUserContext(_ context: UserContext) -> LogMessage {
        LogMessage(
            id: id,
            level: level,
            message: message,
            category: category,
            metadata: metadata,
            userContext: context,
            timestamp: timestamp,
            file: file,
            function: function,
            line: line
        )
    }
}

// MARK: - CustomStringConvertible

extension LogMessage: CustomStringConvertible {
    public var description: String {
        "[\(level.name)] [\(category)] \(message) (\(fileName):\(line))"
    }
}

