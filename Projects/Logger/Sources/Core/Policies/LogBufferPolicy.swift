// LogBufferPolicy.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로그 버퍼링 정책
/// - Note: 버퍼 크기, 플러시 간격 등을 정의
public struct LogBufferPolicy: Sendable, Equatable {
    /// 최대 버퍼 크기 (이 크기에 도달하면 자동 플러시)
    public let maxSize: Int
    
    /// 자동 플러시 간격 (초)
    public let flushInterval: TimeInterval
    
    /// 특정 레벨 이상일 때 즉시 플러시
    public let flushOnLevel: LogLevel?
    
    /// 앱 백그라운드 진입 시 플러시 여부
    public let flushOnBackground: Bool
    
    public init(
        maxSize: Int = 100,
        flushInterval: TimeInterval = 5.0,
        flushOnLevel: LogLevel? = .error,
        flushOnBackground: Bool = true
    ) {
        self.maxSize = maxSize
        self.flushInterval = flushInterval
        self.flushOnLevel = flushOnLevel
        self.flushOnBackground = flushOnBackground
    }
    
    /// 기본 정책
    public static let `default` = LogBufferPolicy()
    
    /// 실시간 출력 정책 (버퍼링 없음)
    public static let realtime = LogBufferPolicy(
        maxSize: 1,
        flushInterval: 0,
        flushOnLevel: nil,
        flushOnBackground: true
    )
    
    /// 배터리 절약 정책 (긴 간격)
    public static let batterySaver = LogBufferPolicy(
        maxSize: 200,
        flushInterval: 30.0,
        flushOnLevel: .error,
        flushOnBackground: true
    )
}

