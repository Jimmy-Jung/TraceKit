// DefaultTraceSanitizer.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 기본 로그 정제기
/// - Note: 정규식 기반으로 민감 정보를 마스킹
public struct DefaultTraceSanitizer: TraceSanitizer {
    /// 활성화 여부
    public let isEnabled: Bool

    /// 민감 정보 패턴 목록
    private let patterns: [SensitiveDataPattern]

    public init(
        isEnabled: Bool = true,
        patterns: [SensitiveDataPattern] = SensitiveDataPattern.defaults
    ) {
        self.isEnabled = isEnabled
        self.patterns = patterns
    }

    public func sanitize(_ message: TraceMessage) -> TraceMessage {
        guard isEnabled else { return message }

        let sanitizedText = sanitizeText(message.message)

        // 메시지가 변경되지 않았으면 원본 반환
        if sanitizedText == message.message {
            return message
        }

        return message.withSanitizedMessage(sanitizedText)
    }

    /// 텍스트에서 민감 정보 마스킹
    /// - Parameter text: 원본 텍스트
    /// - Returns: 마스킹된 텍스트
    private func sanitizeText(_ text: String) -> String {
        var result = text

        for pattern in patterns {
            let range = NSRange(result.startIndex..., in: result)
            result = pattern.regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: range,
                withTemplate: pattern.replacement
            )
        }

        return result
    }
}

// MARK: - Builder

public extension DefaultTraceSanitizer {
    /// 빌더로 커스텀 패턴 추가
    struct Builder {
        private var patterns: [SensitiveDataPattern]
        private var isEnabled: Bool

        public init() {
            patterns = SensitiveDataPattern.defaults
            isEnabled = true
        }

        /// 기본 패턴 없이 시작
        public static func empty() -> Builder {
            var builder = Builder()
            builder.patterns = []
            return builder
        }

        /// 패턴 추가
        public func add(_ pattern: SensitiveDataPattern) -> Builder {
            var builder = self
            builder.patterns.append(pattern)
            return builder
        }

        /// 커스텀 패턴 추가
        public func add(
            name: String,
            pattern: String,
            replacement: String
        ) throws -> Builder {
            let customPattern = try SensitiveDataPattern(
                name: name,
                pattern: pattern,
                replacement: replacement
            )
            return add(customPattern)
        }

        /// 활성화 상태 설정
        public func enabled(_ isEnabled: Bool) -> Builder {
            var builder = self
            builder.isEnabled = isEnabled
            return builder
        }

        /// 빌드
        public func build() -> DefaultTraceSanitizer {
            DefaultTraceSanitizer(
                isEnabled: isEnabled,
                patterns: patterns
            )
        }
    }
}
