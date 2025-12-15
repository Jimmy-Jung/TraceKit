// LogLevelTests.swift
// LoggerTests
//
// Created by jimmy on 2025-12-15.

import Foundation
import Testing
@testable import Logger

// MARK: - LogLevel Tests

struct LogLevelTests {
    
    // MARK: - Comparable Tests
    
    @Test("로그 레벨 비교 - error가 debug보다 높음")
    func errorIsGreaterThanDebug() {
        // Given
        let debug = LogLevel.debug
        let error = LogLevel.error
        
        // When & Then
        #expect(error > debug)
        #expect(debug < error)
        #expect(!(debug > error))
    }
    
    @Test("동일 레벨 비교 시 같음")
    func sameLevelIsEqual() {
        // Given
        let level1 = LogLevel.info
        let level2 = LogLevel.info
        
        // When & Then
        #expect(level1 == level2)
        #expect(!(level1 > level2))
        #expect(!(level1 < level2))
    }
    
    @Test("레벨 순서 검증", arguments: [
        (LogLevel.verbose, LogLevel.debug),
        (LogLevel.debug, LogLevel.info),
        (LogLevel.info, LogLevel.warning),
        (LogLevel.warning, LogLevel.error),
        (LogLevel.error, LogLevel.fatal)
    ])
    func levelOrderIsCorrect(lower: LogLevel, higher: LogLevel) {
        #expect(lower < higher)
        #expect(higher > lower)
    }
    
    // MARK: - Name Tests
    
    @Test("레벨별 name 속성 반환", arguments: [
        (LogLevel.verbose, "VERBOSE"),
        (LogLevel.debug, "DEBUG"),
        (LogLevel.info, "INFO"),
        (LogLevel.warning, "WARNING"),
        (LogLevel.error, "ERROR"),
        (LogLevel.fatal, "FATAL")
    ])
    func levelNameIsCorrect(level: LogLevel, expectedName: String) {
        #expect(level.name == expectedName)
    }
    
    // MARK: - String Parsing Tests
    
    @Test("대문자 문자열로 레벨 파싱", arguments: [
        ("VERBOSE", LogLevel.verbose),
        ("DEBUG", LogLevel.debug),
        ("INFO", LogLevel.info),
        ("WARNING", LogLevel.warning),
        ("ERROR", LogLevel.error),
        ("FATAL", LogLevel.fatal)
    ])
    func parseUppercaseString(input: String, expected: LogLevel) {
        #expect(LogLevel.from(input) == expected)
    }
    
    @Test("소문자 문자열로 레벨 파싱")
    func parseLowercaseString() {
        #expect(LogLevel.from("debug") == .debug)
        #expect(LogLevel.from("error") == .error)
    }
    
    @Test("WARN을 WARNING으로 파싱")
    func parseWarnAsWarning() {
        #expect(LogLevel.from("WARN") == .warning)
        #expect(LogLevel.from("warn") == .warning)
    }
    
    @Test("잘못된 문자열 파싱 시 nil 반환")
    func parseInvalidStringReturnsNil() {
        #expect(LogLevel.from("invalid") == nil)
        #expect(LogLevel.from("") == nil)
        #expect(LogLevel.from("TRACE") == nil)
    }
    
    // MARK: - Emoji Tests
    
    @Test("레벨별 이모지 반환")
    func levelEmojiIsNotEmpty() {
        for level in LogLevel.allCases {
            #expect(!level.emoji.isEmpty)
        }
    }
    
    // MARK: - All Cases Tests
    
    @Test("allCases가 6개 레벨을 포함")
    func allCasesContainsSixLevels() {
        #expect(LogLevel.allCases.count == 6)
    }
    
    @Test("allCases 순서가 올바름")
    func allCasesOrderIsCorrect() {
        let allCases = LogLevel.allCases
        #expect(allCases[0] == .verbose)
        #expect(allCases[5] == .fatal)
    }
    
    // MARK: - Codable Tests
    
    @Test("LogLevel Codable 인코딩/디코딩")
    func codableEncodingDecoding() throws {
        // Given
        let level = LogLevel.warning
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let data = try encoder.encode(level)
        let decoded = try decoder.decode(LogLevel.self, from: data)
        
        // Then
        #expect(decoded == level)
    }
}
