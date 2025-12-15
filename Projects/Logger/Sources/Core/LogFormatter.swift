// LogFormatter.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로그 포맷터 프로토콜
/// - Note: 로그 메시지를 문자열로 변환
public protocol LogFormatter: Sendable {
    /// 로그 메시지를 문자열로 포맷
    /// - Parameter message: 로그 메시지
    /// - Returns: 포맷된 문자열
    func format(_ message: LogMessage) -> String
}

