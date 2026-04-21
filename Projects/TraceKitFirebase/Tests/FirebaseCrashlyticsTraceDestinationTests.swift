// FirebaseCrashlyticsTraceDestinationTests.swift
// TraceKitFirebaseTests
//
// Created by jimmy on 2026-04-21.

import Foundation
import Testing
import TraceKit
import TraceKitFirebase

@Suite("FirebaseCrashlyticsTraceDestination")
struct FirebaseCrashlyticsTraceDestinationTests {
    @Test("verbose 레벨은 기본 minLevel에서 무시된다")
    func verboseLevelIsIgnoredByDefault() async {
        let spy = SpyCrashlyticsRecording()
        let destination = FirebaseCrashlyticsTraceDestination(crashlytics: spy)

        await destination.log(Self.makeMessage(level: .verbose, category: "Test", text: "verbose"))

        #expect(spy.logs.isEmpty)
        #expect(spy.errors.isEmpty)
    }

    @Test("debug, info, warning 레벨은 breadcrumb만 기록한다", arguments: [TraceLevel.debug, .info, .warning])
    func nonErrorLevelsRecordBreadcrumbOnly(level: TraceLevel) async {
        let spy = SpyCrashlyticsRecording()
        let destination = FirebaseCrashlyticsTraceDestination(crashlytics: spy)

        await destination.log(Self.makeMessage(level: level, category: "Test", text: "hello"))

        #expect(spy.logs == ["[\(level.name)] [Test] hello"])
        #expect(spy.errors.isEmpty)
    }

    @Test("error, fatal 레벨은 breadcrumb와 error를 함께 기록한다", arguments: [TraceLevel.error, .fatal])
    func errorLevelsRecordBreadcrumbAndError(level: TraceLevel) async throws {
        let spy = SpyCrashlyticsRecording()
        let destination = FirebaseCrashlyticsTraceDestination(crashlytics: spy)
        let timestamp = try #require(Self.makeTimestampFormatter().date(from: "2026-04-21T12:34:56.000Z"))

        await destination.log(
            Self.makeMessage(
                level: level,
                category: "Network",
                text: "timeout",
                timestamp: timestamp
            )
        )

        #expect(spy.logs == ["[\(level.name)] [Network] timeout"])

        let error = try #require(spy.errors.first)
        #expect(error.domain == "com.tracekit.firebase.crashlytics.Network")
        #expect(error.code == FirebaseCrashlyticsTraceDestination.stableCode(from: "timeout"))
        #expect(error.userInfo[NSLocalizedDescriptionKey] as? String == "timeout")
        #expect(error.userInfo["category"] as? String == "Network")
        #expect(error.userInfo["level"] as? String == level.name.lowercased())
        #expect((error.userInfo["timestamp"] as? String)?.hasPrefix("2026-04-21T12:34:56") == true)
        #expect(error.userInfo["file"] as? String == "FirebaseCrashlyticsTraceDestinationTests.swift")
        #expect(error.userInfo["function"] as? String != nil)
        #expect(error.userInfo["line"] as? Int != nil)
    }

    @Test("errorDomainPrefix를 앱별로 지정할 수 있다")
    func customErrorDomainPrefixIsUsed() async throws {
        let spy = SpyCrashlyticsRecording()
        let destination = FirebaseCrashlyticsTraceDestination(
            errorDomainPrefix: "com.example.app.crashlytics",
            crashlytics: spy
        )

        await destination.log(Self.makeMessage(level: .error, category: "Auth", text: "failed"))

        let error = try #require(spy.errors.first)
        #expect(error.domain == "com.example.app.crashlytics.Auth")
    }

    @Test("category는 NSError domain에 안전한 문자열로 정규화된다")
    func categoryIsSanitizedForErrorDomain() async throws {
        let spy = SpyCrashlyticsRecording()
        let destination = FirebaseCrashlyticsTraceDestination(crashlytics: spy)

        await destination.log(Self.makeMessage(level: .error, category: "결제 / API Error!", text: "failed"))

        let error = try #require(spy.errors.first)
        #expect(error.domain == "com.tracekit.firebase.crashlytics.API_Error")
        #expect(error.userInfo["category"] as? String == "결제 / API Error!")
    }

    @Test("category 정규화 결과가 비어 있으면 uncategorized를 사용한다")
    func emptySanitizedCategoryUsesFallback() {
        #expect(FirebaseCrashlyticsTraceDestination.sanitizeCategoryForDomain("!!!") == "uncategorized")
    }

    @Test("같은 정규화 메시지는 같은 error code를 사용한다")
    func sameNormalizedMessageUsesSameCode() async {
        let spy = SpyCrashlyticsRecording()
        let destination = FirebaseCrashlyticsTraceDestination(crashlytics: spy)

        for id in [1_234, 5_678, 9_999, 123_456, 777_777] {
            await destination.log(Self.makeMessage(level: .error, category: "Network", text: "userId=\(id) failed"))
        }

        #expect(Set(spy.errors.map(\.code)).count == 1)
    }

    @Test("메시지 내 숫자, UUID, timestamp를 정규화한다")
    func normalizesDynamicValues() {
        let uuidA = "550e8400-e29b-41d4-a716-446655440000"
        let uuidB = "550e8400-e29b-41d4-a716-446655440001"
        let messageA = "userId=1234 request=\(uuidA) at 2026-04-21T12:34:56Z failed"
        let messageB = "userId=5678 request=\(uuidB) at 2026-04-21T13:34:56+0900 failed"

        let normalizedA = FirebaseCrashlyticsTraceDestination.normalizeMessage(messageA)
        let normalizedB = FirebaseCrashlyticsTraceDestination.normalizeMessage(messageB)

        #expect(normalizedA == normalizedB)
        #expect(normalizedA.contains("{n}"))
        #expect(normalizedA.contains("{uuid}"))
        #expect(normalizedA.contains("{ts}"))
        #expect(FirebaseCrashlyticsTraceDestination.stableCode(from: normalizedA) == FirebaseCrashlyticsTraceDestination.stableCode(from: normalizedB))
    }

    @Test("정규화 입력은 2000자로 제한된다")
    func normalizeMessageCapsInputLength() {
        let message = String(repeating: "a", count: 3_000)

        #expect(FirebaseCrashlyticsTraceDestination.normalizeMessage(message).count == 2_000)
    }

    @Test("UserContext nil이면 사용자 정보를 동기화하지 않는다")
    func nilUserContextDoesNotSyncUserInfo() async {
        let spy = SpyCrashlyticsRecording()
        let destination = FirebaseCrashlyticsTraceDestination(crashlytics: spy)

        await destination.log(Self.makeMessage(level: .info, category: "Test", text: "hello"))

        #expect(spy.userIDs.isEmpty)
        #expect(spy.customValues.isEmpty)
    }

    @Test("UserContext userId를 동기화한다")
    func userContextWithUserIdSyncsUserId() async {
        let spy = SpyCrashlyticsRecording()
        let destination = FirebaseCrashlyticsTraceDestination(crashlytics: spy)
        let context = Self.makeUserContext(userId: "user-1")

        await destination.log(Self.makeMessage(level: .info, category: "Test", text: "hello", userContext: context))

        #expect(spy.userIDs == ["user-1"])
    }

    @Test("UserContext customAttributes를 setCustomValue로 동기화한다")
    func userContextCustomAttributesSyncToCrashlytics() async {
        let spy = SpyCrashlyticsRecording()
        let destination = FirebaseCrashlyticsTraceDestination(crashlytics: spy)
        let context = Self.makeUserContext(customAttributes: [
            "serverMode": AnyCodable("prod"),
            "retryCount": AnyCodable(3)
        ])

        await destination.log(Self.makeMessage(level: .info, category: "Test", text: "hello", userContext: context))

        #expect(spy.customValues.count == 2)
        #expect(spy.customValues.contains { $0.key == "serverMode" && String(describing: $0.value) == "prod" })
        #expect(spy.customValues.contains { $0.key == "retryCount" && String(describing: $0.value) == "3" })
    }

    // MARK: - Helpers

    private static func makeTimestampFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    private static func makeMessage(
        level: TraceLevel,
        category: String,
        text: String,
        userContext: UserContext? = nil,
        timestamp: Date = Date()
    ) -> TraceMessage {
        TraceMessage(
            id: UUID(),
            level: level,
            message: text,
            category: category,
            metadata: nil,
            userContext: userContext,
            timestamp: timestamp,
            file: #file,
            function: #function,
            line: #line
        )
    }

    private static func makeUserContext(
        userId: String? = nil,
        customAttributes: [String: AnyCodable] = [:]
    ) -> UserContext {
        UserContext(
            userId: userId,
            sessionId: "session-1",
            deviceId: "device-1",
            appVersion: "1.0.0",
            buildNumber: "1",
            osVersion: "iOS 26.0",
            deviceModel: "iPhone",
            environment: .production,
            customAttributes: customAttributes
        )
    }
}

private final class SpyCrashlyticsRecording: CrashlyticsRecording, @unchecked Sendable {
    private let lock = NSLock()
    private var _logs: [String] = []
    private var _errors: [NSError] = []
    private var _userIDs: [String] = []
    private var _customValues: [(value: Any, key: String)] = []

    var logs: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _logs
    }

    var errors: [NSError] {
        lock.lock()
        defer { lock.unlock() }
        return _errors
    }

    var userIDs: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _userIDs
    }

    var customValues: [(value: Any, key: String)] {
        lock.lock()
        defer { lock.unlock() }
        return _customValues
    }

    func log(_ message: String) {
        lock.lock()
        _logs.append(message)
        lock.unlock()
    }

    func record(error: Error) {
        lock.lock()
        _errors.append(error as NSError)
        lock.unlock()
    }

    func setUserID(_ userID: String?) {
        lock.lock()
        if let userID {
            _userIDs.append(userID)
        }
        lock.unlock()
    }

    func setCustomValue(_ value: Any?, forKey key: String) {
        lock.lock()
        _customValues.append((value ?? NSNull(), key))
        lock.unlock()
    }
}
