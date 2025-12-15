// LogSamplerTests.swift
// LoggerTests
//
// Created by jimmy on 2025-12-15.

import Testing
import Foundation
@testable import Logger

// MARK: - LogSampler Tests

struct LogSamplerTests {
    
    // MARK: - Always Include Tests
    
    @Test("error 레벨은 항상 포함")
    func errorLevelAlwaysIncluded() {
        // Given
        let policy = SamplingPolicy(
            defaultRate: 0.0,
            alwaysIncludeLevels: [.error, .fatal]
        )
        let sampler = LogSampler(policy: policy)
        let message = LogMessage(
            level: .error,
            message: "Error message",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let shouldLog = sampler.shouldLog(message)
        
        // Then
        #expect(shouldLog == true)
    }
    
    @Test("fatal 레벨은 항상 포함")
    func fatalLevelAlwaysIncluded() {
        // Given
        let policy = SamplingPolicy(
            defaultRate: 0.0,
            alwaysIncludeLevels: [.error, .fatal]
        )
        let sampler = LogSampler(policy: policy)
        let message = LogMessage(
            level: .fatal,
            message: "Fatal message",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let shouldLog = sampler.shouldLog(message)
        
        // Then
        #expect(shouldLog == true)
    }
    
    // MARK: - Zero Rate Tests
    
    @Test("0% 비율은 항상 제외 (alwaysInclude 외)")
    func zeroRateNeverIncludes() {
        // Given
        let policy = SamplingPolicy(
            defaultRate: 0.0,
            alwaysIncludeLevels: []
        )
        let sampler = LogSampler(policy: policy)
        let message = LogMessage(
            level: .debug,
            message: "Debug message",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let shouldLog = sampler.shouldLog(message)
        
        // Then
        #expect(shouldLog == false)
    }
    
    // MARK: - Full Rate Tests
    
    @Test("100% 비율은 항상 포함")
    func fullRateAlwaysIncludes() {
        // Given
        let policy = SamplingPolicy(defaultRate: 1.0)
        let sampler = LogSampler(policy: policy)
        let message = LogMessage(
            level: .debug,
            message: "Debug message",
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
        
        // When
        let shouldLog = sampler.shouldLog(message)
        
        // Then
        #expect(shouldLog == true)
    }
    
    // MARK: - Debug Policy Tests
    
    @Test("디버그 정책은 모든 레벨 포함")
    func debugPolicyIncludesAll() {
        // Given
        let sampler = LogSampler(policy: .debug)
        
        // When & Then
        for level in LogLevel.allCases {
            let message = LogMessage(
                level: level,
                message: "Test",
                category: "Test",
                file: #file,
                function: #function,
                line: #line
            )
            #expect(sampler.shouldLog(message) == true)
        }
    }
    
    // MARK: - Probabilistic Tests
    
    @Test("50% 비율은 대략 절반 포함")
    func fiftyPercentRateIncludesAboutHalf() {
        // Given
        let policy = SamplingPolicy(
            defaultRate: 0.5,
            alwaysIncludeLevels: []
        )
        let sampler = LogSampler(policy: policy)
        
        var includedCount = 0
        let totalCount = 1000
        
        // When
        for i in 0..<totalCount {
            let message = LogMessage(
                level: .info,
                message: "Test \(i)",
                category: "Test",
                file: #file,
                function: #function,
                line: #line
            )
            if sampler.shouldLog(message) {
                includedCount += 1
            }
        }
        
        // Then (대략 40% ~ 60% 범위)
        let ratio = Double(includedCount) / Double(totalCount)
        #expect(ratio >= 0.35)
        #expect(ratio <= 0.65)
    }
}
