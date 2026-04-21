// FirebaseCrashlyticsTraceDestination.swift
// TraceKitFirebase
//
// Created by jimmy on 2026-04-21.

import Foundation
import TraceKit

/// TraceKit 로그를 Firebase Crashlytics로 전송하는 Destination.
///
/// `.debug`, `.info`, `.warning` 레벨은 Crashlytics breadcrumb로 기록하고,
/// `.error`, `.fatal` 레벨은 non-fatal error로도 기록합니다.
public actor FirebaseCrashlyticsTraceDestination: TraceDestination {
    private let crashlytics: any CrashlyticsRecording
    private let errorDomainPrefix: String

    // MARK: - TraceDestination

    public nonisolated var identifier: String { "firebase.crashlytics" }
    public var minLevel: TraceLevel
    public var isEnabled: Bool

    // MARK: - Init

    public init(
        minLevel: TraceLevel = .debug,
        isEnabled: Bool = true,
        errorDomainPrefix: String = "com.tracekit.firebase.crashlytics",
        crashlytics: any CrashlyticsRecording = FirebaseCrashlyticsRecorder()
    ) {
        self.minLevel = minLevel
        self.isEnabled = isEnabled
        self.errorDomainPrefix = errorDomainPrefix
        self.crashlytics = crashlytics
    }

    // MARK: - Log

    public func log(_ message: TraceMessage) async {
        guard shouldLog(message) else { return }

        crashlytics.log(Self.formatBreadcrumb(message))

        if message.level >= .error {
            recordError(message)
        }

        updateUserContext(message.userContext)
    }

    // MARK: - Helpers

    public nonisolated static func formatBreadcrumb(_ message: TraceMessage) -> String {
        "[\(message.level.name)] [\(message.category)] \(message.message)"
    }

    private func recordError(_ message: TraceMessage) {
        let normalizedMessage = Self.normalizeMessage(message.message)
        let error = NSError(
            domain: "\(errorDomainPrefix).\(message.category)",
            code: Self.stableCode(from: normalizedMessage),
            userInfo: [
                NSLocalizedDescriptionKey: message.message,
                "category": message.category,
                "level": message.level.name.lowercased(),
                "timestamp": Self.makeTimestampFormatter().string(from: message.timestamp),
                "file": message.fileName,
                "function": message.function,
                "line": message.line
            ]
        )

        crashlytics.record(error: error)
    }

    private func updateUserContext(_ context: UserContext?) {
        guard let context else { return }

        if let userId = context.userId {
            crashlytics.setUserID(userId)
        }

        for (key, value) in context.customAttributes {
            crashlytics.setCustomValue(value.value, forKey: key)
        }
    }

    /// 메시지 내 동적 값을 치환해 Crashlytics 이슈 그룹화가 과도하게 쪼개지지 않도록 합니다.
    ///
    /// - UUID: `{uuid}`
    /// - ISO8601 timestamp: `{ts}`
    /// - 3자리 이상 숫자 시퀀스: `{n}`
    /// - 입력 길이: 최대 2,000자
    public nonisolated static func normalizeMessage(_ message: String) -> String {
        let truncated = String(message.prefix(2_000))
        var result = truncated

        result = result.replacingOccurrences(
            of: #"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"#,
            with: "{uuid}",
            options: .regularExpression
        )

        result = result.replacingOccurrences(
            of: #"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:?\d{2})?"#,
            with: "{ts}",
            options: .regularExpression
        )

        result = result.replacingOccurrences(
            of: #"\d{3,}"#,
            with: "{n}",
            options: .regularExpression
        )

        return result
    }

    /// deterministic error code. Crashlytics grouping 보조 정보로 사용합니다.
    public nonisolated static func stableCode(from normalized: String) -> Int {
        var hash: UInt64 = 0
        for byte in normalized.utf8 {
            hash = UInt64(byte) &+ (hash << 6) &+ (hash << 16) &- hash
        }
        return Int(hash & 0x7FFF_FFFF)
    }

    private nonisolated static func makeTimestampFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}
