// TraceLevelTests.swift
// TraceKitTests
//
// Created by jimmy on 2025-12-15.

import Foundation
import Testing
@testable import TraceKit

// MARK: - TraceLevel Tests

struct TraceLevelTests {
    // MARK: - Comparable Tests

    @Test("로그 레벨 비교 - error가 debug보다 높음")
    func errorIsGreaterThanDebug() {
        // Given
        let debug = TraceLevel.debug
        let error = TraceLevel.error

        // When & Then
        #expect(error > debug)
        #expect(debug < error)
        #expect(!(debug > error))
    }

    @Test("동일 레벨 비교 시 같음")
    func sameLevelIsEqual() {
        // Given
        let level1 = TraceLevel.info
        let level2 = TraceLevel.info

        // When & Then
        #expect(level1 == level2)
        #expect(!(level1 > level2))
        #expect(!(level1 < level2))
    }

    @Test("레벨 순서 검증", arguments: [
        (TraceLevel.verbose, TraceLevel.debug),
        (TraceLevel.debug, TraceLevel.info),
        (TraceLevel.info, TraceLevel.warning),
        (TraceLevel.warning, TraceLevel.error),
        (TraceLevel.error, TraceLevel.fatal)
    ])
    func levelOrderIsCorrect(lower: TraceLevel, higher: TraceLevel) {
        #expect(lower < higher)
        #expect(higher > lower)
    }

    // MARK: - Name Tests

    @Test("레벨별 name 속성 반환", arguments: [
        (TraceLevel.verbose, "VERBOSE"),
        (TraceLevel.debug, "DEBUG"),
        (TraceLevel.info, "INFO"),
        (TraceLevel.warning, "WARNING"),
        (TraceLevel.error, "ERROR"),
        (TraceLevel.fatal, "FATAL")
    ])
    func levelNameIsCorrect(level: TraceLevel, expectedName: String) {
        #expect(level.name == expectedName)
    }

    // MARK: - String Parsing Tests

    @Test("대문자 문자열로 레벨 파싱", arguments: [
        ("VERBOSE", TraceLevel.verbose),
        ("DEBUG", TraceLevel.debug),
        ("INFO", TraceLevel.info),
        ("WARNING", TraceLevel.warning),
        ("ERROR", TraceLevel.error),
        ("FATAL", TraceLevel.fatal)
    ])
    func parseUppercaseString(input: String, expected: TraceLevel) {
        #expect(TraceLevel.from(input) == expected)
    }

    @Test("소문자 문자열로 레벨 파싱")
    func parseLowercaseString() {
        #expect(TraceLevel.from("debug") == .debug)
        #expect(TraceLevel.from("error") == .error)
    }

    @Test("WARN을 WARNING으로 파싱")
    func parseWarnAsWarning() {
        #expect(TraceLevel.from("WARN") == .warning)
        #expect(TraceLevel.from("warn") == .warning)
    }

    @Test("잘못된 문자열 파싱 시 nil 반환")
    func parseInvalidStringReturnsNil() {
        #expect(TraceLevel.from("invalid") == nil)
        #expect(TraceLevel.from("") == nil)
        #expect(TraceLevel.from("TRACE") == nil)
    }

    // MARK: - Emoji Tests

    @Test("레벨별 이모지 반환")
    func levelEmojiIsNotEmpty() {
        for level in TraceLevel.allCases {
            #expect(!level.emoji.isEmpty)
        }
    }

    // MARK: - All Cases Tests

    @Test("allCases가 6개 레벨을 포함")
    func allCasesContainsSixLevels() {
        #expect(TraceLevel.allCases.count == 6)
    }

    @Test("allCases 순서가 올바름")
    func allCasesOrderIsCorrect() {
        let allCases = TraceLevel.allCases
        #expect(allCases[0] == .verbose)
        #expect(allCases[5] == .fatal)
    }

    // MARK: - Codable Tests

    @Test("TraceLevel Codable 인코딩/디코딩")
    func codableEncodingDecoding() throws {
        // Given
        let level = TraceLevel.warning
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // When
        let data = try encoder.encode(level)
        let decoded = try decoder.decode(TraceLevel.self, from: data)

        // Then
        #expect(decoded == level)
    }
}
