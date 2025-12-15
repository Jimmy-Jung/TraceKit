// SamplingPolicyTests.swift
// LoggerTests
//
// Created by jimmy on 2025-12-15.

import Testing
import Foundation
@testable import Logger

// MARK: - SamplingPolicy Tests

struct SamplingPolicyTests {
    
    // MARK: - Default Rate Tests
    
    @Test("기본 비율이 적용됨")
    func defaultRateApplied() {
        // Given
        let policy = SamplingPolicy(defaultRate: 0.5)
        let message = LogMessage(
            level: .info,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let rate = policy.rate(for: message)
        
        // Then
        #expect(rate == 0.5)
    }
    
    // MARK: - Always Include Levels Tests
    
    @Test("항상 포함 레벨은 100%", arguments: [LogLevel.error, LogLevel.fatal])
    func alwaysIncludeLevelsReturn100Percent(level: LogLevel) {
        // Given
        let policy = SamplingPolicy(
            defaultRate: 0.0,
            alwaysIncludeLevels: [.error, .fatal]
        )
        let message = LogMessage(
            level: level,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let rate = policy.rate(for: message)
        
        // Then
        #expect(rate == 1.0)
    }
    
    // MARK: - Level-based Rate Tests
    
    @Test("레벨별 비율이 기본 비율보다 우선")
    func levelRateOverridesDefault() {
        // Given
        let policy = SamplingPolicy(
            defaultRate: 0.5,
            ratesByLevel: [.debug: 0.1],
            alwaysIncludeLevels: []
        )
        let message = LogMessage(
            level: .debug,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let rate = policy.rate(for: message)
        
        // Then
        #expect(rate == 0.1)
    }
    
    // MARK: - Category-based Rate Tests
    
    @Test("카테고리별 비율 적용")
    func categoryRateApplied() {
        // Given
        let policy = SamplingPolicy(
            defaultRate: 0.5,
            ratesByCategory: ["Network": 0.2],
            alwaysIncludeLevels: []
        )
        let message = LogMessage(
            level: .info,
            message: "Test",
            category: "Network",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let rate = policy.rate(for: message)
        
        // Then
        #expect(rate == 0.2)
    }
    
    // MARK: - Rate Clamping Tests
    
    @Test("비율이 0.0 ~ 1.0으로 제한됨")
    func rateIsClamped() {
        // Given
        let policy1 = SamplingPolicy(defaultRate: -0.5)
        let policy2 = SamplingPolicy(defaultRate: 1.5)
        
        let message = LogMessage(
            level: .info,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // Then
        #expect(policy1.rate(for: message) == 0.0)
        #expect(policy2.rate(for: message) == 1.0)
    }
    
    // MARK: - Debug Policy Tests
    
    @Test("디버그 정책은 100%")
    func debugPolicyIs100Percent() {
        // Given
        let policy = SamplingPolicy.debug
        let message = LogMessage(
            level: .verbose,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let rate = policy.rate(for: message)
        
        // Then
        #expect(rate == 1.0)
    }
    
    // MARK: - Production Policy Tests
    
    @Test("프로덕션 정책의 error는 100%")
    func productionPolicyErrorIs100Percent() {
        // Given
        let policy = SamplingPolicy.production
        let message = LogMessage(
            level: .error,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let rate = policy.rate(for: message)
        
        // Then
        #expect(rate == 1.0)
    }
    
    @Test("프로덕션 정책의 verbose는 1%")
    func productionPolicyVerboseIs1Percent() {
        // Given
        let policy = SamplingPolicy.production
        let message = LogMessage(
            level: .verbose,
            message: "Test",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let rate = policy.rate(for: message)
        
        // Then
        #expect(rate == 0.01)
    }
    
    // MARK: - Minimal Policy Tests
    
    @Test("최소 정책은 1%")
    func minimalPolicyIs1Percent() {
        // Given
        let policy = SamplingPolicy.minimal
        
        // Then
        #expect(policy.defaultRate == 0.01)
    }
}

