// TraceLevel.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로그 심각도를 나타내는 열거형
/// - Note: Comparable을 구현하여 레벨 비교 가능
public enum TraceLevel: Int, Comparable, Codable, Sendable, CaseIterable {
    /// 가장 상세한 추적 로그
    case verbose = 0
    /// 디버깅 목적의 로그
    case debug = 1
    /// 일반 정보성 로그
    case info = 2
    /// 잠재적 문제 경고
    case warning = 3
    /// 오류 발생
    case error = 4
    /// 치명적 오류 (앱 크래시 가능)
    case fatal = 5

    public static func < (lhs: TraceLevel, rhs: TraceLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// 로그 레벨의 문자열 표현
    public var name: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .fatal: return "FATAL"
        }
    }

    /// 로그 레벨 이모지
    public var emoji: String {
        switch self {
        case .verbose: return "📝"
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fatal: return "💀"
        }
    }

    /// 문자열로부터 TraceLevel 생성
    /// - Parameter string: 대소문자 무관한 레벨 문자열
    /// - Returns: 해당하는 TraceLevel, 없으면 nil
    public static func from(_ string: String) -> TraceLevel? {
        switch string.uppercased() {
        case "VERBOSE": return .verbose
        case "DEBUG": return .debug
        case "INFO": return .info
        case "WARNING", "WARN": return .warning
        case "ERROR": return .error
        case "FATAL": return .fatal
        default: return nil
        }
    }
}
