// LaunchArgumentParser.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// Launch Argument 파서
/// - Note: Xcode의 launch argument를 파싱하여 TraceKitConfiguration 생성
public struct LaunchArgumentParser: Sendable {
    // MARK: - Argument Keys

    private enum ArgumentKey: String {
        case logLevel = "-logLevel"
        case logFilter = "-logFilter"
        case sampleRate = "-sampleRate"
        case bufferSize = "-bufferSize"
        case flushInterval = "-flushInterval"

        // Enable flags
        case enableConsole = "-enableConsole"
        case enableOSLog = "-enableOSLog"
        case enableFile = "-enableFile"
        case enableSentry = "-enableSentry"
        case enableDatadog = "-enableDatadog"
        case enableCrashlytics = "-enableCrashlytics"
        case enableMasking = "-enableMasking"

        // Disable flags
        case disableConsole = "-disableConsole"
        case disableOSLog = "-disableOSLog"
        case disableFile = "-disableFile"
        case disableSentry = "-disableSentry"
        case disableDatadog = "-disableDatadog"
        case disableCrashlytics = "-disableCrashlytics"
        case disableMasking = "-disableMasking"
    }

    // MARK: - Destination Identifiers

    public enum DestinationId: String, Sendable {
        case console
        case oslog
        case file
        case sentry
        case datadog
        case crashlytics
    }

    // MARK: - Parse

    /// Launch Argument 파싱
    /// - Parameter arguments: 인자 배열 (기본: ProcessInfo.processInfo.arguments)
    /// - Returns: 파싱된 설정 (없으면 nil)
    public static func parse(
        from arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> TraceKitConfiguration? {
        var hasAnyArgument = false

        var minLevel: TraceLevel = .verbose
        var enabledCategories: Set<String>? = nil
        var disabledDestinations: Set<String> = []
        var isSanitizingEnabled = true
        var sampleRate = 1.0
        var bufferSize = 100
        var flushInterval: TimeInterval = 5.0

        // 인자 인덱스 맵 생성
        let argMap = Dictionary(
            uniqueKeysWithValues: arguments.enumerated().map { ($1, $0) }
        )

        // -logLevel <LEVEL>
        if let index = argMap[ArgumentKey.logLevel.rawValue],
           index + 1 < arguments.count,
           let level = TraceLevel.from(arguments[index + 1])
        {
            minLevel = level
            hasAnyArgument = true
        }

        // -logFilter <categories>
        if let index = argMap[ArgumentKey.logFilter.rawValue],
           index + 1 < arguments.count
        {
            let categories = arguments[index + 1]
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
            enabledCategories = Set(categories)
            hasAnyArgument = true
        }

        // -sampleRate <rate>
        if let index = argMap[ArgumentKey.sampleRate.rawValue],
           index + 1 < arguments.count,
           let rate = Double(arguments[index + 1])
        {
            sampleRate = min(max(rate, 0.0), 1.0)
            hasAnyArgument = true
        }

        // -bufferSize <size>
        if let index = argMap[ArgumentKey.bufferSize.rawValue],
           index + 1 < arguments.count,
           let size = Int(arguments[index + 1])
        {
            bufferSize = max(size, 1)
            hasAnyArgument = true
        }

        // -flushInterval <seconds>
        if let index = argMap[ArgumentKey.flushInterval.rawValue],
           index + 1 < arguments.count,
           let interval = Double(arguments[index + 1])
        {
            flushInterval = max(interval, 0)
            hasAnyArgument = true
        }

        // Disable flags
        let disableMap: [ArgumentKey: DestinationId] = [
            .disableConsole: .console,
            .disableOSLog: .oslog,
            .disableFile: .file,
            .disableSentry: .sentry,
            .disableDatadog: .datadog,
            .disableCrashlytics: .crashlytics,
        ]

        for (argKey, destId) in disableMap {
            if arguments.contains(argKey.rawValue) {
                disabledDestinations.insert(destId.rawValue)
                hasAnyArgument = true
            }
        }

        // Masking flags
        if arguments.contains(ArgumentKey.disableMasking.rawValue) {
            isSanitizingEnabled = false
            hasAnyArgument = true
        } else if arguments.contains(ArgumentKey.enableMasking.rawValue) {
            isSanitizingEnabled = true
            hasAnyArgument = true
        }

        guard hasAnyArgument else { return nil }

        return TraceKitConfiguration(
            minLevel: minLevel,
            enabledCategories: enabledCategories,
            disabledDestinations: disabledDestinations,
            isSanitizingEnabled: isSanitizingEnabled,
            sampleRate: sampleRate,
            bufferSize: bufferSize,
            flushInterval: flushInterval
        )
    }

    /// 특정 destination이 활성화되었는지 확인
    public static func isDestinationEnabled(
        _ destination: DestinationId,
        in arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> Bool? {
        let enableKey = "-enable\(destination.rawValue.capitalized)"
        let disableKey = "-disable\(destination.rawValue.capitalized)"

        if arguments.contains(disableKey) {
            return false
        } else if arguments.contains(enableKey) {
            return true
        }

        return nil
    }
}
