// TraceSanitizer.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로그 민감정보 처리 프로토콜
/// - Note: 로그 내 민감 정보를 마스킹
public protocol TraceSanitizer: Sendable {
    /// 활성화 여부
    var isEnabled: Bool { get }

    /// 로그 메시지 정제 (민감정보 마스킹)
    /// - Parameter message: 원본 로그 메시지
    /// - Returns: 정제된 로그 메시지
    func sanitize(_ message: TraceMessage) -> TraceMessage
}
