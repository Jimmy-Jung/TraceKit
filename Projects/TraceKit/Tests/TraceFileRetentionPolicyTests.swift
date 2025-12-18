// TraceFileRetentionPolicyTests.swift
// TraceKitTests
//
// Created by jimmy on 2025-12-15.

import Foundation
import Testing
@testable import TraceKit

// MARK: - TraceFileRetentionPolicy Tests

struct TraceFileRetentionPolicyTests {
    // MARK: - Default Policy Tests

    @Test("기본 정책 값 검증")
    func defaultPolicyValues() {
        // Given & When
        let policy = TraceFileRetentionPolicy.default

        // Then
        #expect(policy.retentionDays == 7)
        #expect(policy.maxTotalSize == 100 * 1024 * 1024)
        #expect(policy.maxFileSize == 10 * 1024 * 1024)
        #expect(policy.cleanupInterval == 3600)
        #expect(policy.fileExtension == "log")
    }

    // MARK: - Debug Policy Tests

    @Test("디버그 정책은 1일 보관")
    func debugPolicyValues() {
        // Given & When
        let policy = TraceFileRetentionPolicy.debug

        // Then
        #expect(policy.retentionDays == 1)
        #expect(policy.maxTotalSize == 10 * 1024 * 1024)
        #expect(policy.maxFileSize == 1 * 1024 * 1024)
    }

    // MARK: - Long Term Policy Tests

    @Test("장기 보관 정책은 30일")
    func longTermPolicyValues() {
        // Given & When
        let policy = TraceFileRetentionPolicy.longTerm

        // Then
        #expect(policy.retentionDays == 30)
        #expect(policy.maxTotalSize == 500 * 1024 * 1024)
        #expect(policy.maxFileSize == 50 * 1024 * 1024)
    }

    // MARK: - Custom Policy Tests

    @Test("커스텀 정책 생성")
    func createCustomPolicy() {
        // Given & When
        let policy = TraceFileRetentionPolicy(
            retentionDays: 14,
            maxTotalSize: 200 * 1024 * 1024,
            maxFileSize: 20 * 1024 * 1024,
            cleanupInterval: 7200,
            fileExtension: "json",
            dateFormat: "yyyyMMdd"
        )

        // Then
        #expect(policy.retentionDays == 14)
        #expect(policy.maxTotalSize == 200 * 1024 * 1024)
        #expect(policy.fileExtension == "json")
        #expect(policy.dateFormat == "yyyyMMdd")
    }

    // MARK: - Nil maxTotalSize Tests

    @Test("maxTotalSize nil 허용")
    func maxTotalSizeCanBeNil() {
        // Given & When
        let policy = TraceFileRetentionPolicy(
            retentionDays: 7,
            maxTotalSize: nil
        )

        // Then
        #expect(policy.maxTotalSize == nil)
    }

    // MARK: - Equatable Tests

    @Test("동일 정책 비교")
    func equalPolicies() {
        // Given
        let policy1 = TraceFileRetentionPolicy.default
        let policy2 = TraceFileRetentionPolicy.default

        // Then
        #expect(policy1 == policy2)
    }
}
