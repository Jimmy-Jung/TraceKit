// JSONTraceFormatterTests.swift
// TraceKitTests
//
// Created by jimmy on 2025-12-15.

import Foundation
import Testing
@testable import TraceKit

// MARK: - JSONTraceFormatter Tests

struct JSONTraceFormatterTests {
    // MARK: - Basic Formatting Tests

    @Test("기본 메시지 JSON 포맷팅")
    func formatBasicMessage() {
        // Given
        let formatter = JSONTraceFormatter()
        let message = TraceMessage(
            level: .info,
            message: "Test message",
            category: "Test",
            file: "/path/to/TestFile.swift",
            function: "testFunc",
            line: 42
        )

        // When
        let result = formatter.format(message)

        // Then
        #expect(result.contains("\"level\":\"INFO\""))
        #expect(result.contains("\"message\":\"Test message\""))
        #expect(result.contains("\"category\":\"Test\""))
        #expect(result.contains("\"line\":42"))
    }

    @Test("JSON 파싱 가능한 출력")
    func outputIsParsableJSON() throws {
        // Given
        let formatter = JSONTraceFormatter()
        let message = TraceMessage(
            level: .error,
            message: "Error occurred",
            category: "Network",
            file: #file,
            function: #function,
            line: #line
        )

        // When
        let result = formatter.format(message)
        let data = result.data(using: .utf8)!

        // Then
        let json = try JSONSerialization.jsonObject(with: data)
        #expect(json is [String: Any])
    }

    // MARK: - Pretty Print Tests

    @Test("prettyPrint 옵션 적용")
    func prettyPrintOption() {
        // Given
        let formatter = JSONTraceFormatter(prettyPrint: true)
        let message = TraceMessage(
            level: .debug,
            message: "Debug",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )

        // When
        let result = formatter.format(message)

        // Then
        #expect(result.contains("\n"))
    }

    @Test("prettyPrint false면 한 줄")
    func noPrettyPrintIsSingleLine() {
        // Given
        let formatter = JSONTraceFormatter(prettyPrint: false)
        let message = TraceMessage(
            level: .info,
            message: "Info",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )

        // When
        let result = formatter.format(message)
        let lineCount = result.components(separatedBy: "\n").count

        // Then
        #expect(lineCount == 1)
    }

    // MARK: - Metadata Tests

    @Test("메타데이터 포함")
    func includesMetadata() {
        // Given
        let formatter = JSONTraceFormatter()
        let message = TraceMessage(
            level: .info,
            message: "Test",
            category: "Test",
            metadata: [
                "userId": AnyCodable(123),
                "action": AnyCodable("click"),
            ],
            file: #file,
            function: #function,
            line: #line
        )

        // When
        let result = formatter.format(message)

        // Then
        #expect(result.contains("metadata"))
        #expect(result.contains("userId"))
        #expect(result.contains("123"))
    }

    // MARK: - User Context Tests

    @Test("사용자 컨텍스트 포함")
    func includesUserContext() {
        // Given
        let formatter = JSONTraceFormatter()
        let context = UserContext(
            userId: "user123",
            deviceId: "device",
            appVersion: "1.0",
            buildNumber: "1",
            osVersion: "17.0",
            deviceModel: "iPhone",
            environment: .debug
        )
        let message = TraceMessage(
            level: .info,
            message: "Test",
            category: "Test",
            userContext: context,
            file: #file,
            function: #function,
            line: #line
        )

        // When
        let result = formatter.format(message)

        // Then
        #expect(result.contains("context"))
        #expect(result.contains("user123"))
    }

    // MARK: - Timestamp Tests

    @Test("타임스탬프 ISO8601 형식")
    func timestampIsISO8601() {
        // Given
        let formatter = JSONTraceFormatter()
        let message = TraceMessage(
            level: .info,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )

        // When
        let result = formatter.format(message)

        // Then
        #expect(result.contains("timestamp"))
        // ISO8601 형식은 "T"와 "Z" 또는 시간대를 포함
        #expect(result.contains("T"))
    }

    // MARK: - Special Characters Tests

    @Test("특수 문자 이스케이프")
    func escapesSpecialCharacters() throws {
        // Given
        let formatter = JSONTraceFormatter()
        let message = TraceMessage(
            level: .info,
            message: "Test with \"quotes\" and\nnewline",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )

        // When
        let result = formatter.format(message)
        let data = result.data(using: .utf8)!

        // Then - JSON 파싱 가능해야 함
        let json = try JSONSerialization.jsonObject(with: data)
        #expect(json is [String: Any])
    }
}
