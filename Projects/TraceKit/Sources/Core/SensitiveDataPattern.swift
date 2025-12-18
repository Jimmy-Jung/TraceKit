// SensitiveDataPattern.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 민감 정보 패턴 정의
/// - Note: 정규식 기반으로 민감 정보를 탐지하고 마스킹
public struct SensitiveDataPattern: Sendable {
    /// 패턴 이름
    public let name: String

    /// 정규식 패턴
    public let regex: NSRegularExpression

    /// 대체 문자열
    public let replacement: String

    public init(name: String, pattern: String, replacement: String) throws {
        self.name = name
        regex = try NSRegularExpression(pattern: pattern, options: [])
        self.replacement = replacement
    }
}

// MARK: - 기본 제공 패턴

public extension SensitiveDataPattern {
    /// 이메일 패턴
    static let email: SensitiveDataPattern = try! SensitiveDataPattern(
        name: "email",
        pattern: #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#,
        replacement: "[EMAIL_REDACTED]"
    )

    /// 전화번호 패턴 (한국)
    static let phoneNumberKR: SensitiveDataPattern = try! SensitiveDataPattern(
        name: "phoneNumberKR",
        pattern: #"01[0-9]-?[0-9]{3,4}-?[0-9]{4}"#,
        replacement: "[PHONE_REDACTED]"
    )

    /// 전화번호 패턴 (국제)
    static let phoneNumberIntl: SensitiveDataPattern = try! SensitiveDataPattern(
        name: "phoneNumberIntl",
        pattern: #"\+?[1-9]\d{1,14}"#,
        replacement: "[PHONE_REDACTED]"
    )

    /// JWT 토큰 패턴
    static let jwtToken: SensitiveDataPattern = try! SensitiveDataPattern(
        name: "jwtToken",
        pattern: #"eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*"#,
        replacement: "[JWT_REDACTED]"
    )

    /// Bearer 토큰 패턴
    static let bearerToken: SensitiveDataPattern = try! SensitiveDataPattern(
        name: "bearerToken",
        pattern: #"Bearer\s+[A-Za-z0-9_-]+"#,
        replacement: "Bearer [TOKEN_REDACTED]"
    )

    /// API 키 패턴 (일반적인 형태)
    static let apiKey: SensitiveDataPattern = try! SensitiveDataPattern(
        name: "apiKey",
        pattern: #"(?i)(api[_-]?key|apikey|api_secret|secret[_-]?key)\s*[:=]\s*['\"]?[A-Za-z0-9_-]{16,}['\"]?"#,
        replacement: "[API_KEY_REDACTED]"
    )

    /// 신용카드 번호 패턴
    static let creditCard: SensitiveDataPattern = try! SensitiveDataPattern(
        name: "creditCard",
        pattern: #"\b(?:\d{4}[- ]?){3}\d{4}\b"#,
        replacement: "[CARD_REDACTED]"
    )

    /// 주민등록번호 패턴 (한국)
    static let koreanSSN: SensitiveDataPattern = try! SensitiveDataPattern(
        name: "koreanSSN",
        pattern: #"\d{6}[- ]?\d{7}"#,
        replacement: "[SSN_REDACTED]"
    )

    /// 비밀번호 필드 패턴
    static let password: SensitiveDataPattern = try! SensitiveDataPattern(
        name: "password",
        pattern: #"(?i)(password|passwd|pwd)\s*[:=]\s*['\"]?[^\s'\",}]+['\"]?"#,
        replacement: "[PASSWORD_REDACTED]"
    )

    /// IPv4 주소 패턴
    static let ipAddress: SensitiveDataPattern = try! SensitiveDataPattern(
        name: "ipAddress",
        pattern: #"\b(?:\d{1,3}\.){3}\d{1,3}\b"#,
        replacement: "[IP_REDACTED]"
    )

    /// 기본 패턴 세트
    static let defaults: [SensitiveDataPattern] = [
        .email,
        .phoneNumberKR,
        .jwtToken,
        .bearerToken,
        .apiKey,
        .creditCard,
        .koreanSSN,
        .password,
    ]
}
