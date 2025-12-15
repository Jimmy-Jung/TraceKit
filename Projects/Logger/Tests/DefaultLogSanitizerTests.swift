// DefaultLogSanitizerTests.swift
// LoggerTests
//
// Created by jimmy on 2025-12-15.

import Testing
import Foundation
@testable import Logger

// MARK: - DefaultLogSanitizer Tests

struct DefaultLogSanitizerTests {
    
    // MARK: - Email Masking Tests
    
    @Test("이메일 마스킹")
    func masksEmail() {
        // Given
        let sanitizer = DefaultLogSanitizer()
        let message = LogMessage(
            level: .info,
            message: "User email: test@example.com logged in",
            category: "Auth",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let sanitized = sanitizer.sanitize(message)
        
        // Then
        #expect(!sanitized.message.contains("test@example.com"))
        #expect(sanitized.message.contains("[EMAIL_REDACTED]"))
    }
    
    @Test("다중 이메일 마스킹")
    func masksMultipleEmails() {
        // Given
        let sanitizer = DefaultLogSanitizer()
        let message = LogMessage(
            level: .info,
            message: "From: a@b.com, To: c@d.com",
            category: "Email",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let sanitized = sanitizer.sanitize(message)
        
        // Then
        #expect(!sanitized.message.contains("a@b.com"))
        #expect(!sanitized.message.contains("c@d.com"))
    }
    
    // MARK: - JWT Masking Tests
    
    @Test("JWT 토큰 마스킹")
    func masksJWT() {
        // Given
        let sanitizer = DefaultLogSanitizer()
        let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U"
        let message = LogMessage(
            level: .debug,
            message: "Token: \(jwt)",
            category: "Auth",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let sanitized = sanitizer.sanitize(message)
        
        // Then
        #expect(!sanitized.message.contains(jwt))
        #expect(sanitized.message.contains("[JWT_REDACTED]"))
    }
    
    // MARK: - Password Masking Tests
    
    @Test("패스워드 필드 마스킹")
    func masksPassword() {
        // Given
        let sanitizer = DefaultLogSanitizer()
        let message = LogMessage(
            level: .debug,
            message: "Login attempt with password=supersecret123",
            category: "Auth",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let sanitized = sanitizer.sanitize(message)
        
        // Then
        #expect(!sanitized.message.contains("supersecret123"))
        #expect(sanitized.message.contains("[PASSWORD_REDACTED]"))
    }
    
    // MARK: - Disabled Sanitizer Tests
    
    @Test("비활성화 시 원본 유지")
    func disabledSanitizerPreservesOriginal() {
        // Given
        let sanitizer = DefaultLogSanitizer(isEnabled: false)
        let originalMessage = "User email: test@example.com"
        let message = LogMessage(
            level: .info,
            message: originalMessage,
            category: "Auth",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let sanitized = sanitizer.sanitize(message)
        
        // Then
        #expect(sanitized.message == originalMessage)
    }
    
    // MARK: - Multiple Patterns Tests
    
    @Test("여러 민감 정보 동시 마스킹")
    func masksMultipleSensitiveData() {
        // Given
        let sanitizer = DefaultLogSanitizer()
        let message = LogMessage(
            level: .info,
            message: "User test@example.com called API with password=secret123",
            category: "Auth",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let sanitized = sanitizer.sanitize(message)
        
        // Then
        #expect(!sanitized.message.contains("test@example.com"))
        #expect(!sanitized.message.contains("secret123"))
    }
    
    // MARK: - No Sensitive Data Tests
    
    @Test("민감 정보 없으면 원본 유지")
    func preservesMessageWithoutSensitiveData() {
        // Given
        let sanitizer = DefaultLogSanitizer()
        let originalMessage = "Application started successfully"
        let message = LogMessage(
            level: .info,
            message: originalMessage,
            category: "App",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let sanitized = sanitizer.sanitize(message)
        
        // Then
        #expect(sanitized.message == originalMessage)
    }
    
    // MARK: - Other Fields Preserved Tests
    
    @Test("메시지 외 필드 유지")
    func preservesOtherFields() {
        // Given
        let sanitizer = DefaultLogSanitizer()
        let message = LogMessage(
            level: .error,
            message: "Error for user@test.com",
            category: "Network",
            metadata: ["key": AnyCodable("value")],
            file: "/path/to/file.swift",
            function: "myFunc",
            line: 99
        )
        
        // When
        let sanitized = sanitizer.sanitize(message)
        
        // Then
        #expect(sanitized.level == .error)
        #expect(sanitized.category == "Network")
        #expect(sanitized.line == 99)
        #expect(sanitized.id == message.id)
    }
    
    // MARK: - Builder Tests
    
    @Test("빌더로 커스텀 패턴 추가")
    func builderAddsCustomPattern() throws {
        // Given
        let sanitizer = try DefaultLogSanitizer.Builder()
            .add(name: "customId", pattern: #"ID-\d{6}"#, replacement: "[ID_HIDDEN]")
            .build()
        
        let message = LogMessage(
            level: .info,
            message: "User ID-123456 logged in",
            category: "Auth",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let sanitized = sanitizer.sanitize(message)
        
        // Then
        #expect(!sanitized.message.contains("ID-123456"))
        #expect(sanitized.message.contains("[ID_HIDDEN]"))
    }
    
    @Test("빌더 empty()는 기본 패턴 없음")
    func builderEmptyHasNoDefaultPatterns() {
        // Given
        let sanitizer = DefaultLogSanitizer.Builder.empty().build()
        let message = LogMessage(
            level: .info,
            message: "Email: test@example.com",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let sanitized = sanitizer.sanitize(message)
        
        // Then
        #expect(sanitized.message.contains("test@example.com"))
    }
    
    @Test("빌더 enabled(false)")
    func builderDisabled() {
        // Given
        let sanitizer = DefaultLogSanitizer.Builder()
            .enabled(false)
            .build()
        
        // Then
        #expect(sanitizer.isEnabled == false)
    }
}
