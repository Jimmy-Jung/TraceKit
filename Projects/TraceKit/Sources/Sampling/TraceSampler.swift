// TraceSampler.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로그 샘플러
/// - Note: 샘플링 정책에 따라 로그를 필터링
public struct TraceSampler: Sendable {
    /// 샘플링 정책
    public let policy: SamplingPolicy

    public init(policy: SamplingPolicy = .debug) {
        self.policy = policy
    }

    /// 메시지가 로깅되어야 하는지 결정
    /// - Parameter message: 로그 메시지
    /// - Returns: 로깅 여부
    public func shouldLog(_ message: TraceMessage) -> Bool {
        let rate = policy.rate(for: message)

        // 100%면 무조건 로깅
        if rate >= 1.0 {
            return true
        }

        // 0%면 무조건 스킵
        if rate <= 0.0 {
            return false
        }

        // 확률적 샘플링
        return Double.random(in: 0.0 ..< 1.0) < rate
    }
}
