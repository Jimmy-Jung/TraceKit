// TraceBufferPolicyTests.swift
// TraceKitTests
//
// Created by jimmy on 2025-12-15.

import Foundation
import Testing
@testable import TraceKit

// MARK: - TraceBufferPolicy Tests

struct TraceBufferPolicyTests {
    // MARK: - Default Policy Tests

    @Test("기본 정책 값 검증")
    func defaultPolicyValues() {
        // Given & When
        let policy = TraceBufferPolicy.default

        // Then
        #expect(policy.maxSize == 100)
        #expect(policy.flushInterval == 5.0)
        #expect(policy.flushOnLevel == .error)
        #expect(policy.flushOnBackground == true)
    }

    // MARK: - Realtime Policy Tests

    @Test("실시간 정책은 버퍼 크기 1")
    func realtimePolicyHasSizeOne() {
        // Given & When
        let policy = TraceBufferPolicy.realtime

        // Then
        #expect(policy.maxSize == 1)
        #expect(policy.flushInterval == 0)
        #expect(policy.flushOnLevel == nil)
    }

    // MARK: - Battery Saver Policy Tests

    @Test("배터리 절약 정책은 큰 버퍼와 긴 간격")
    func batterySaverPolicyValues() {
        // Given & When
        let policy = TraceBufferPolicy.batterySaver

        // Then
        #expect(policy.maxSize == 200)
        #expect(policy.flushInterval == 30.0)
        #expect(policy.flushOnLevel == .error)
    }

    // MARK: - Custom Policy Tests

    @Test("커스텀 정책 생성")
    func createCustomPolicy() {
        // Given & When
        let policy = TraceBufferPolicy(
            maxSize: 50,
            flushInterval: 10.0,
            flushOnLevel: .warning,
            flushOnBackground: false
        )

        // Then
        #expect(policy.maxSize == 50)
        #expect(policy.flushInterval == 10.0)
        #expect(policy.flushOnLevel == .warning)
        #expect(policy.flushOnBackground == false)
    }

    // MARK: - Equatable Tests

    @Test("동일 정책 비교")
    func equalPolicies() {
        // Given
        let policy1 = TraceBufferPolicy.default
        let policy2 = TraceBufferPolicy.default

        // Then
        #expect(policy1 == policy2)
    }

    @Test("다른 정책 비교")
    func differentPolicies() {
        // Given
        let policy1 = TraceBufferPolicy.default
        let policy2 = TraceBufferPolicy.realtime

        // Then
        #expect(policy1 != policy2)
    }
}
