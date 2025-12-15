// LogDestination.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로그 출력 대상 프로토콜
/// - Note: Actor 기반으로 스레드 안전성 보장
public protocol LogDestination: Actor {
    /// 목적지 고유 식별자
    var identifier: String { get }
    
    /// 최소 로그 레벨
    var minLevel: LogLevel { get set }
    
    /// 활성화 여부
    var isEnabled: Bool { get set }
    
    /// 로그 메시지 처리
    /// - Parameter message: 로그 메시지
    func log(_ message: LogMessage) async
    
    /// 버퍼된 로그 플러시 (배치 처리 지원)
    /// - Parameter messages: 로그 메시지 배열
    func flush(_ messages: [LogMessage]) async
}

// MARK: - Default Implementation

extension LogDestination {
    /// 기본 flush 구현 (개별 로그 처리)
    public func flush(_ messages: [LogMessage]) async {
        for message in messages {
            await log(message)
        }
    }
    
    /// 메시지가 로깅 가능한지 확인
    public func shouldLog(_ message: LogMessage) -> Bool {
        isEnabled && message.level >= minLevel
    }
}

