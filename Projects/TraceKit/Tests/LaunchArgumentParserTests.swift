// LaunchArgumentParserTests.swift
// TraceKitTests
//
// Created by jimmy on 2025-12-15.

import Foundation
import Testing
@testable import TraceKit

// MARK: - LaunchArgumentParser Tests

struct LaunchArgumentParserTests {
    // MARK: - Log Level Tests

    @Test("logLevel 인자 파싱", arguments: [
        (["app", "-logLevel", "DEBUG"], TraceLevel.debug),
        (["app", "-logLevel", "INFO"], TraceLevel.info),
        (["app", "-logLevel", "WARNING"], TraceLevel.warning),
        (["app", "-logLevel", "ERROR"], TraceLevel.error),
        (["app", "-logLevel", "FATAL"], TraceLevel.fatal),
    ])
    func parseTraceLevel(arguments: [String], expectedLevel: TraceLevel) {
        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config != nil)
        #expect(config?.minLevel == expectedLevel)
    }

    @Test("소문자 logLevel 파싱")
    func parseLowercaseTraceLevel() {
        // Given
        let arguments = ["app", "-logLevel", "debug"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.minLevel == .debug)
    }

    // MARK: - Log Filter Tests

    @Test("logFilter 단일 카테고리")
    func parseSingleCategory() {
        // Given
        let arguments = ["app", "-logFilter", "Network"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.enabledCategories == Set(["Network"]))
    }

    @Test("logFilter 다중 카테고리")
    func parseMultipleCategories() {
        // Given
        let arguments = ["app", "-logFilter", "Network,Auth,UI"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.enabledCategories == Set(["Network", "Auth", "UI"]))
    }

    @Test("logFilter 공백 처리")
    func parseFilterWithSpaces() {
        // Given
        let arguments = ["app", "-logFilter", "Network, Auth, UI"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.enabledCategories?.contains("Network") == true)
        #expect(config?.enabledCategories?.contains("Auth") == true)
    }

    // MARK: - Disable Destination Tests

    @Test("disableConsole 파싱")
    func parseDisableConsole() {
        // Given
        let arguments = ["app", "-disableConsole"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.disabledDestinations.contains("console") == true)
    }

    @Test("disableSentry 파싱")
    func parseDisableSentry() {
        // Given
        let arguments = ["app", "-disableSentry"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.disabledDestinations.contains("sentry") == true)
    }

    @Test("여러 destination 비활성화")
    func parseMultipleDisables() {
        // Given
        let arguments = ["app", "-disableConsole", "-disableSentry", "-disableDatadog"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.disabledDestinations.contains("console") == true)
        #expect(config?.disabledDestinations.contains("sentry") == true)
        #expect(config?.disabledDestinations.contains("datadog") == true)
    }

    // MARK: - Sample Rate Tests

    @Test("sampleRate 파싱")
    func parseSampleRate() {
        // Given
        let arguments = ["app", "-sampleRate", "0.5"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.sampleRate == 0.5)
    }

    @Test("sampleRate 범위 제한 (상한)")
    func sampleRateClampedToMax() {
        // Given
        let arguments = ["app", "-sampleRate", "1.5"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.sampleRate == 1.0)
    }

    @Test("sampleRate 범위 제한 (하한)")
    func sampleRateClampedToMin() {
        // Given
        let arguments = ["app", "-sampleRate", "-0.5"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.sampleRate == 0.0)
    }

    // MARK: - Buffer Size Tests

    @Test("bufferSize 파싱")
    func parseBufferSize() {
        // Given
        let arguments = ["app", "-bufferSize", "50"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.bufferSize == 50)
    }

    // MARK: - Flush Interval Tests

    @Test("flushInterval 파싱")
    func parseFlushInterval() {
        // Given
        let arguments = ["app", "-flushInterval", "10"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.flushInterval == 10.0)
    }

    // MARK: - Masking Tests

    @Test("disableMasking 파싱")
    func parseDisableMasking() {
        // Given
        let arguments = ["app", "-disableMasking"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.isSanitizingEnabled == false)
    }

    @Test("enableMasking 파싱")
    func parseEnableMasking() {
        // Given
        let arguments = ["app", "-enableMasking"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config?.isSanitizingEnabled == true)
    }

    // MARK: - No Arguments Tests

    @Test("로그 관련 인자 없으면 nil")
    func noLogArgumentsReturnsNil() {
        // Given
        let arguments = ["app", "-someOtherFlag"]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config == nil)
    }

    @Test("빈 인자 배열은 nil")
    func emptyArgumentsReturnsNil() {
        // Given
        let arguments: [String] = []

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config == nil)
    }

    // MARK: - Multiple Arguments Tests

    @Test("여러 인자 동시 파싱")
    func parseMultipleArguments() {
        // Given
        let arguments = [
            "app",
            "-logLevel", "DEBUG",
            "-logFilter", "Network",
            "-sampleRate", "0.1",
            "-disableSentry",
            "-disableMasking",
        ]

        // When
        let config = LaunchArgumentParser.parse(from: arguments)

        // Then
        #expect(config != nil)
        #expect(config?.minLevel == .debug)
        #expect(config?.enabledCategories == Set(["Network"]))
        #expect(config?.sampleRate == 0.1)
        #expect(config?.disabledDestinations.contains("sentry") == true)
        #expect(config?.isSanitizingEnabled == false)
    }

    // MARK: - isDestinationEnabled Tests

    @Test("isDestinationEnabled 체크")
    func isDestinationEnabledCheck() {
        // Given
        let arguments = ["app", "-disableSentry"]

        // When
        let isEnabled = LaunchArgumentParser.isDestinationEnabled(.sentry, in: arguments)

        // Then
        #expect(isEnabled == false)
    }

    @Test("플래그 없으면 nil 반환")
    func noFlagReturnsNil() {
        // Given
        let arguments = ["app"]

        // When
        let isEnabled = LaunchArgumentParser.isDestinationEnabled(.console, in: arguments)

        // Then
        #expect(isEnabled == nil)
    }
}
