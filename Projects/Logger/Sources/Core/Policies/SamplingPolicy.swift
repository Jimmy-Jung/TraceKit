// SamplingPolicy.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로그 샘플링 정책
/// - Note: 프로덕션 환경에서 로그 볼륨 제어
public struct SamplingPolicy: Sendable, Equatable {
    /// 기본 샘플링 비율 (0.0 ~ 1.0)
    public let defaultRate: Double
    
    /// 레벨별 샘플링 비율
    public let ratesByLevel: [LogLevel: Double]
    
    /// 카테고리별 샘플링 비율
    public let ratesByCategory: [String: Double]
    
    /// 항상 포함할 레벨 (샘플링 무시)
    public let alwaysIncludeLevels: Set<LogLevel>
    
    public init(
        defaultRate: Double = 1.0,
        ratesByLevel: [LogLevel: Double] = [:],
        ratesByCategory: [String: Double] = [:],
        alwaysIncludeLevels: Set<LogLevel> = [.error, .fatal]
    ) {
        self.defaultRate = min(max(defaultRate, 0.0), 1.0)
        self.ratesByLevel = ratesByLevel.mapValues { min(max($0, 0.0), 1.0) }
        self.ratesByCategory = ratesByCategory.mapValues { min(max($0, 0.0), 1.0) }
        self.alwaysIncludeLevels = alwaysIncludeLevels
    }
    
    /// 메시지에 대한 샘플링 비율 계산
    /// - Parameter message: 로그 메시지
    /// - Returns: 샘플링 비율 (0.0 ~ 1.0)
    public func rate(for message: LogMessage) -> Double {
        // 항상 포함할 레벨은 100%
        if alwaysIncludeLevels.contains(message.level) {
            return 1.0
        }
        
        // 레벨별 비율이 있으면 우선
        if let levelRate = ratesByLevel[message.level] {
            return levelRate
        }
        
        // 카테고리별 비율이 있으면 사용
        if let categoryRate = ratesByCategory[message.category] {
            return categoryRate
        }
        
        // 기본 비율
        return defaultRate
    }
    
    /// 디버그용 정책 (100% 수집)
    public static let debug = SamplingPolicy(
        defaultRate: 1.0,
        alwaysIncludeLevels: Set(LogLevel.allCases)
    )
    
    /// 프로덕션용 정책 (10% 기본, 에러 100%)
    public static let production = SamplingPolicy(
        defaultRate: 0.1,
        ratesByLevel: [
            .verbose: 0.01,
            .debug: 0.05,
            .info: 0.1,
            .warning: 0.5
        ],
        alwaysIncludeLevels: [.error, .fatal]
    )
    
    /// 최소 샘플링 정책 (1%)
    public static let minimal = SamplingPolicy(
        defaultRate: 0.01,
        alwaysIncludeLevels: [.error, .fatal]
    )
}

