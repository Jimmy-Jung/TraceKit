// SensitiveDataPatternTests.swift
// LoggerTests
//
// Created by jimmy on 2025-12-15.

import Testing
import Foundation
@testable import Logger

// MARK: - SensitiveDataPattern Tests

struct SensitiveDataPatternTests {
    
    // MARK: - Email Pattern Tests
    
    @Test("이메일 패턴 매칭", arguments: [
        "test@example.com",
        "user.name@gmail.com",
        "admin123@company.co.kr"
    ])
    func emailPatternMatches(email: String) {
        // Given
        let pattern = SensitiveDataPattern.email
        let range = NSRange(email.startIndex..., in: email)
        
        // When
        let matches = pattern.regex.numberOfMatches(in: email, options: [], range: range)
        
        // Then
        #expect(matches > 0)
    }
    
    @Test("이메일 아닌 문자열 미매칭", arguments: [
        "not an email",
        "user@",
        "@domain.com",
        "plaintext"
    ])
    func emailPatternDoesNotMatch(text: String) {
        // Given
        let pattern = SensitiveDataPattern.email
        let range = NSRange(text.startIndex..., in: text)
        
        // When
        let matches = pattern.regex.numberOfMatches(in: text, options: [], range: range)
        
        // Then
        #expect(matches == 0)
    }
    
    // MARK: - JWT Pattern Tests
    
    @Test("JWT 패턴 매칭")
    func jwtPatternMatches() {
        // Given
        let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U"
        let pattern = SensitiveDataPattern.jwtToken
        let range = NSRange(jwt.startIndex..., in: jwt)
        
        // When
        let matches = pattern.regex.numberOfMatches(in: jwt, options: [], range: range)
        
        // Then
        #expect(matches > 0)
    }
    
    // MARK: - Bearer Token Pattern Tests
    
    @Test("Bearer 토큰 패턴 매칭")
    func bearerTokenPatternMatches() {
        // Given
        let text = "Authorization: Bearer abc123def456"
        let pattern = SensitiveDataPattern.bearerToken
        let range = NSRange(text.startIndex..., in: text)
        
        // When
        let matches = pattern.regex.numberOfMatches(in: text, options: [], range: range)
        
        // Then
        #expect(matches > 0)
    }
    
    // MARK: - Credit Card Pattern Tests
    
    @Test("신용카드 패턴 매칭", arguments: [
        "1234-5678-9012-3456",
        "1234 5678 9012 3456",
        "1234567890123456"
    ])
    func creditCardPatternMatches(card: String) {
        // Given
        let pattern = SensitiveDataPattern.creditCard
        let range = NSRange(card.startIndex..., in: card)
        
        // When
        let matches = pattern.regex.numberOfMatches(in: card, options: [], range: range)
        
        // Then
        #expect(matches > 0)
    }
    
    // MARK: - Phone Number Pattern Tests
    
    @Test("한국 전화번호 패턴 매칭", arguments: [
        "010-1234-5678",
        "01012345678",
        "010-123-4567"
    ])
    func koreanPhonePatternMatches(phone: String) {
        // Given
        let pattern = SensitiveDataPattern.phoneNumberKR
        let range = NSRange(phone.startIndex..., in: phone)
        
        // When
        let matches = pattern.regex.numberOfMatches(in: phone, options: [], range: range)
        
        // Then
        #expect(matches > 0)
    }
    
    // MARK: - Password Pattern Tests
    
    @Test("패스워드 필드 패턴 매칭", arguments: [
        "password=secret123",
        "pwd:mypassword",
        "Password: admin"
    ])
    func passwordPatternMatches(text: String) {
        // Given
        let pattern = SensitiveDataPattern.password
        let range = NSRange(text.startIndex..., in: text)
        
        // When
        let matches = pattern.regex.numberOfMatches(in: text, options: [], range: range)
        
        // Then
        #expect(matches > 0)
    }
    
    // MARK: - Korean SSN Pattern Tests
    
    @Test("주민등록번호 패턴 매칭")
    func koreanSSNPatternMatches() {
        // Given
        let ssn = "901231-1234567"
        let pattern = SensitiveDataPattern.koreanSSN
        let range = NSRange(ssn.startIndex..., in: ssn)
        
        // When
        let matches = pattern.regex.numberOfMatches(in: ssn, options: [], range: range)
        
        // Then
        #expect(matches > 0)
    }
    
    // MARK: - Defaults Tests
    
    @Test("defaults에 기본 패턴들 포함")
    func defaultsContainsExpectedPatterns() {
        // Given & When
        let defaults = SensitiveDataPattern.defaults
        
        // Then
        #expect(defaults.count >= 5)
        
        let names = defaults.map { $0.name }
        #expect(names.contains("email"))
        #expect(names.contains("jwtToken"))
        #expect(names.contains("password"))
    }
    
    // MARK: - Custom Pattern Tests
    
    @Test("커스텀 패턴 생성")
    func createCustomPattern() throws {
        // Given & When
        let pattern = try SensitiveDataPattern(
            name: "customId",
            pattern: #"ID-\d{6}"#,
            replacement: "[ID_REDACTED]"
        )
        
        // Then
        #expect(pattern.name == "customId")
        #expect(pattern.replacement == "[ID_REDACTED]")
    }
    
    @Test("잘못된 정규식으로 패턴 생성 시 에러")
    func invalidRegexThrows() {
        #expect(throws: (any Error).self) {
            try SensitiveDataPattern(
                name: "invalid",
                pattern: "[invalid",  // 잘못된 정규식
                replacement: ""
            )
        }
    }
}

