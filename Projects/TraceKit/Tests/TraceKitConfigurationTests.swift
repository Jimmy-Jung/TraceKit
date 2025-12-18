// TraceKitConfigurationTests.swift
// TraceKitTests
//
// Created by jimmy on 2025-12-15.

import Foundation
import Testing
@testable import TraceKit

// MARK: - TraceKitConfiguration Tests

struct TraceKitConfigurationTests {
    // MARK: - Default Configuration Tests

    @Test("기본 설정 값 검증")
    func defaultConfigurationValues() {
        // Given & When
        let config = TraceKitConfiguration.default

        // Then
        #expect(config.minLevel == .verbose)
        #expect(config.enabledCategories == nil)
        #expect(config.disabledDestinations.isEmpty)
        #expect(config.isSanitizingEnabled == true)
        #expect(config.sampleRate == 1.0)
        #expect(config.bufferSize == 100)
        #expect(config.flushInterval == 5.0)
    }

    // MARK: - Debug Configuration Tests

    @Test("디버그 설정 값 검증")
    func debugConfigurationValues() {
        // Given & When
        let config = TraceKitConfiguration.debug

        // Then
        #expect(config.minLevel == .verbose)
        #expect(config.isSanitizingEnabled == false)
        #expect(config.sampleRate == 1.0)
    }

    // MARK: - Production Configuration Tests

    @Test("프로덕션 설정 값 검증")
    func productionConfigurationValues() {
        // Given & When
        let config = TraceKitConfiguration.production

        // Then
        #expect(config.minLevel == .info)
        #expect(config.isSanitizingEnabled == true)
        #expect(config.sampleRate == 0.1)
    }

    // MARK: - Custom Configuration Tests

    @Test("커스텀 설정 생성")
    func createCustomConfiguration() {
        // Given & When
        let config = TraceKitConfiguration(
            minLevel: .warning,
            enabledCategories: Set(["Network", "Auth"]),
            disabledDestinations: Set(["sentry"]),
            isSanitizingEnabled: false,
            sampleRate: 0.5,
            bufferSize: 50,
            flushInterval: 10.0
        )

        // Then
        #expect(config.minLevel == .warning)
        #expect(config.enabledCategories == Set(["Network", "Auth"]))
        #expect(config.disabledDestinations.contains("sentry"))
        #expect(config.isSanitizingEnabled == false)
        #expect(config.sampleRate == 0.5)
        #expect(config.bufferSize == 50)
        #expect(config.flushInterval == 10.0)
    }

    // MARK: - Sample Rate Clamping Tests

    @Test("sampleRate 상한 제한")
    func sampleRateClampedToMax() {
        // Given & When
        let config = TraceKitConfiguration(sampleRate: 1.5)

        // Then
        #expect(config.sampleRate == 1.0)
    }

    @Test("sampleRate 하한 제한")
    func sampleRateClampedToMin() {
        // Given & When
        let config = TraceKitConfiguration(sampleRate: -0.5)

        // Then
        #expect(config.sampleRate == 0.0)
    }

    // MARK: - Merge Tests

    @Test("설정 병합 - 기본 값 유지")
    func mergePreservesBaseValues() {
        // Given
        let base = TraceKitConfiguration(
            minLevel: .debug,
            enabledCategories: Set(["Network"]),
            sampleRate: 0.8
        )
        let override = TraceKitConfiguration(
            minLevel: .error,
            sampleRate: 0.2
        )

        // When
        let merged = base.merged(with: override)

        // Then
        #expect(merged.minLevel == .error)
        #expect(merged.sampleRate == 0.2)
        // enabledCategories는 override에 nil이면 base 유지
    }

    @Test("설정 병합 - disabledDestinations 합집합")
    func mergeUnionsDisabledDestinations() {
        // Given
        let base = TraceKitConfiguration(
            disabledDestinations: Set(["console"])
        )
        let override = TraceKitConfiguration(
            disabledDestinations: Set(["sentry"])
        )

        // When
        let merged = base.merged(with: override)

        // Then
        #expect(merged.disabledDestinations.contains("console"))
        #expect(merged.disabledDestinations.contains("sentry"))
    }

    // MARK: - Equatable Tests

    @Test("동일 설정 비교")
    func equalConfigurations() {
        // Given
        let config1 = TraceKitConfiguration.default
        let config2 = TraceKitConfiguration.default

        // Then
        #expect(config1 == config2)
    }

    @Test("다른 설정 비교")
    func differentConfigurations() {
        // Given
        let config1 = TraceKitConfiguration.debug
        let config2 = TraceKitConfiguration.production

        // Then
        #expect(config1 != config2)
    }
}
