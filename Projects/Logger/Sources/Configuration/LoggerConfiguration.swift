// LoggerConfiguration.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로거 설정
/// - Note: Launch Argument와 런타임 설정을 통합 관리
public struct LoggerConfiguration: Sendable, Equatable {
    /// 최소 로그 레벨
    public var minLevel: LogLevel
    
    /// 활성화된 카테고리 (nil이면 모든 카테고리)
    public var enabledCategories: Set<String>?
    
    /// 비활성화된 destination 식별자
    public var disabledDestinations: Set<String>
    
    /// 민감정보 마스킹 활성화
    public var isSanitizingEnabled: Bool
    
    /// 샘플링 비율 (0.0 ~ 1.0)
    public var sampleRate: Double
    
    /// 버퍼 크기
    public var bufferSize: Int
    
    /// 플러시 간격 (초)
    public var flushInterval: TimeInterval
    
    public init(
        minLevel: LogLevel = .verbose,
        enabledCategories: Set<String>? = nil,
        disabledDestinations: Set<String> = [],
        isSanitizingEnabled: Bool = true,
        sampleRate: Double = 1.0,
        bufferSize: Int = 100,
        flushInterval: TimeInterval = 5.0
    ) {
        self.minLevel = minLevel
        self.enabledCategories = enabledCategories
        self.disabledDestinations = disabledDestinations
        self.isSanitizingEnabled = isSanitizingEnabled
        self.sampleRate = min(max(sampleRate, 0.0), 1.0)
        self.bufferSize = bufferSize
        self.flushInterval = flushInterval
    }
    
    /// 다른 설정과 병합 (other가 우선)
    public func merged(with other: LoggerConfiguration) -> LoggerConfiguration {
        LoggerConfiguration(
            minLevel: other.minLevel,
            enabledCategories: other.enabledCategories ?? enabledCategories,
            disabledDestinations: disabledDestinations.union(other.disabledDestinations),
            isSanitizingEnabled: other.isSanitizingEnabled,
            sampleRate: other.sampleRate,
            bufferSize: other.bufferSize,
            flushInterval: other.flushInterval
        )
    }
    
    /// 기본 설정
    public static let `default` = LoggerConfiguration()
    
    /// 디버그용 설정
    public static let debug = LoggerConfiguration(
        minLevel: .verbose,
        isSanitizingEnabled: false,
        sampleRate: 1.0
    )
    
    /// 프로덕션용 설정
    public static let production = LoggerConfiguration(
        minLevel: .info,
        isSanitizingEnabled: true,
        sampleRate: 0.1
    )
}

