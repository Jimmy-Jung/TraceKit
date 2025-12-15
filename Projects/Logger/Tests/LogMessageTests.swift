// LogMessageTests.swift
// LoggerTests
//
// Created by jimmy on 2025-12-15.

import Testing
import Foundation
@testable import Logger

// MARK: - LogMessage Tests

struct LogMessageTests {
    
    // MARK: - Creation Tests
    
    @Test("LogMessage 기본 생성")
    func createBasicLogMessage() {
        // Given & When
        let message = LogMessage(
            level: .info,
            message: "Test message",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // Then
        #expect(message.level == .info)
        #expect(message.message == "Test message")
        #expect(message.category == "Test")
        #expect(message.metadata == nil)
        #expect(message.userContext == nil)
    }
    
    @Test("LogMessage에 메타데이터 포함")
    func createLogMessageWithMetadata() {
        // Given
        let metadata: [String: AnyCodable] = [
            "userId": 123,
            "action": "login"
        ]
        
        // When
        let message = LogMessage(
            level: .info,
            message: "User action",
            category: "Auth",
            metadata: metadata,
            file: #file,
            function: #function,
            line: #line
        )
        
        // Then
        #expect(message.metadata != nil)
        #expect(message.metadata?.count == 2)
    }
    
    // MARK: - FileName Tests
    
    @Test("fileName이 전체 경로에서 파일명만 추출")
    func fileNameExtractsOnlyFileName() {
        // Given
        let message = LogMessage(
            level: .debug,
            message: "Test",
            category: "Test",
            file: "/Users/test/Project/Sources/MyFile.swift",
            function: "testFunc",
            line: 42
        )
        
        // When
        let fileName = message.fileName
        
        // Then
        #expect(fileName == "MyFile.swift")
    }
    
    // MARK: - WithSanitizedMessage Tests
    
    @Test("withSanitizedMessage가 메시지만 변경")
    func withSanitizedMessageOnlyChangesMessage() {
        // Given
        let original = LogMessage(
            level: .warning,
            message: "Original message with secret@email.com",
            category: "Auth",
            file: #file,
            function: #function,
            line: 100
        )
        
        // When
        let sanitized = original.withSanitizedMessage("Original message with [REDACTED]")
        
        // Then
        #expect(sanitized.message == "Original message with [REDACTED]")
        #expect(sanitized.level == original.level)
        #expect(sanitized.category == original.category)
        #expect(sanitized.id == original.id)
        #expect(sanitized.line == original.line)
    }
    
    // MARK: - WithUserContext Tests
    
    @Test("withUserContext가 컨텍스트 추가")
    func withUserContextAddsContext() {
        // Given
        let original = LogMessage(
            level: .info,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: 1
        )
        
        let context = UserContext(
            userId: "user123",
            sessionId: "session456",
            deviceId: "device789",
            appVersion: "1.0.0",
            buildNumber: "100",
            osVersion: "17.0",
            deviceModel: "iPhone15,2",
            environment: .debug
        )
        
        // When
        let withContext = original.withUserContext(context)
        
        // Then
        #expect(withContext.userContext != nil)
        #expect(withContext.userContext?.userId == "user123")
        #expect(withContext.message == original.message)
    }
    
    // MARK: - Description Tests
    
    @Test("description 포맷 검증")
    func descriptionFormat() {
        // Given
        let message = LogMessage(
            level: .error,
            message: "Something failed",
            category: "Network",
            file: "/path/to/NetworkService.swift",
            function: "fetchData",
            line: 50
        )
        
        // When
        let description = message.description
        
        // Then
        #expect(description.contains("[ERROR]"))
        #expect(description.contains("[Network]"))
        #expect(description.contains("Something failed"))
        #expect(description.contains("NetworkService.swift"))
        #expect(description.contains(":50"))
    }
    
    // MARK: - Timestamp Tests
    
    @Test("timestamp가 현재 시간 근처")
    func timestampIsNearNow() {
        // Given
        let before = Date()
        
        // When
        let message = LogMessage(
            level: .info,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: 1
        )
        
        let after = Date()
        
        // Then
        #expect(message.timestamp >= before)
        #expect(message.timestamp <= after)
    }
    
    // MARK: - ID Uniqueness Tests
    
    @Test("각 메시지는 고유 ID를 가짐")
    func eachMessageHasUniqueId() {
        // Given & When
        let message1 = LogMessage(
            level: .info,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: 1
        )
        
        let message2 = LogMessage(
            level: .info,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: 1
        )
        
        // Then
        #expect(message1.id != message2.id)
    }
}

