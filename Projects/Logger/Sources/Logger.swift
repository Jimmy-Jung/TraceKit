// Logger.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 메인 로거 클래스
/// - Note: 로그 수집, 필터링, 분배를 담당하는 파사드
@LoggerActor
public final class Logger {
    
    // MARK: - Singleton
    
    /// 공유 인스턴스
    public static var shared: Logger = Logger()
    
    // MARK: - Properties
    
    /// 로그 목적지 목록
    private var destinations: [any LogDestination] = []
    
    /// 설정
    private var configuration: LoggerConfiguration
    
    /// 로그 버퍼
    private var buffer: LogBuffer?
    
    /// 샘플러
    private var sampler: LogSampler?
    
    /// 정제기
    private var sanitizer: LogSanitizer?
    
    /// 사용자 컨텍스트 제공자
    private var contextProvider: (any UserContextProvider)?
    
    /// 크래시 로그 보존기
    private var crashPreserver: CrashLogPreserver?
    
    /// 성능 추적기
    public private(set) var tracer: PerformanceTracer
    
    // MARK: - Init
    
    public init(configuration: LoggerConfiguration = .default) {
        self.configuration = configuration
        self.tracer = PerformanceTracer()
    }
    
    // MARK: - Configuration
    
    /// 설정 업데이트
    public func configure(_ newConfiguration: LoggerConfiguration) {
        self.configuration = newConfiguration
        
        // 버퍼 정책 업데이트
        if let buffer = buffer {
            Task {
                await buffer.stopAutoFlush()
                // 새 정책으로 버퍼 재시작 필요 시 처리
            }
        }
    }
    
    /// Destination 추가
    public func addDestination(_ destination: any LogDestination) {
        destinations.append(destination)
    }
    
    /// Destination 제거
    public func removeDestination(identifier: String) {
        destinations.removeAll { destination in
            // Actor isolated property 접근을 위해 Task 사용
            false // 실제로는 identifier 비교 필요
        }
    }
    
    /// 버퍼 설정
    public func setBuffer(_ buffer: LogBuffer) {
        self.buffer = buffer
        
        Task {
            await buffer.startAutoFlush { [weak self] messages in
                await self?.dispatchToDestinations(messages)
            }
        }
    }
    
    /// 샘플러 설정
    public func setSampler(_ sampler: LogSampler) {
        self.sampler = sampler
    }
    
    /// 정제기 설정
    public func setSanitizer(_ sanitizer: LogSanitizer) {
        self.sanitizer = sanitizer
    }
    
    /// 컨텍스트 제공자 설정
    public func setContextProvider(_ provider: any UserContextProvider) {
        self.contextProvider = provider
    }
    
    /// 크래시 보존기 설정
    public func setCrashPreserver(_ preserver: CrashLogPreserver) {
        self.crashPreserver = preserver
    }
    
    // MARK: - Logging Methods
    
    /// 로그 출력
    public func log(
        level: LogLevel,
        _ message: @autoclosure () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        // 레벨 필터링
        guard level >= configuration.minLevel else { return }
        
        // 카테고리 필터링
        if let enabledCategories = configuration.enabledCategories,
           !enabledCategories.contains(category) {
            return
        }
        
        // 메시지 생성 (lazy evaluation)
        var logMessage = LogMessage(
            level: level,
            message: message(),
            category: category,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
        
        // 샘플링
        if let sampler = sampler, !sampler.shouldLog(logMessage) {
            return
        }
        
        // 사용자 컨텍스트 추가
        if let contextProvider = contextProvider {
            let context = await contextProvider.currentContext()
            logMessage = logMessage.withUserContext(context)
        }
        
        // 정제 (민감정보 마스킹)
        if configuration.isSanitizingEnabled, let sanitizer = sanitizer {
            logMessage = sanitizer.sanitize(logMessage)
        }
        
        // 크래시 보존
        if let crashPreserver = crashPreserver {
            await crashPreserver.record(logMessage)
        }
        
        // 버퍼링 또는 즉시 출력
        if let buffer = buffer {
            await buffer.append(logMessage)
        } else {
            await dispatchToDestinations([logMessage])
        }
    }
    
    // MARK: - Convenience Methods
    
    public func verbose(
        _ message: @autoclosure () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(
            level: .verbose,
            message(),
            category: category,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
    
    public func debug(
        _ message: @autoclosure () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(
            level: .debug,
            message(),
            category: category,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
    
    public func info(
        _ message: @autoclosure () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(
            level: .info,
            message(),
            category: category,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
    
    public func warning(
        _ message: @autoclosure () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(
            level: .warning,
            message(),
            category: category,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
    
    public func error(
        _ message: @autoclosure () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(
            level: .error,
            message(),
            category: category,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
    
    public func fatal(
        _ message: @autoclosure () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await log(
            level: .fatal,
            message(),
            category: category,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
    
    // MARK: - Performance Tracing
    
    /// 성능 측정 시작
    public func startSpan(name: String, parentId: UUID? = nil) async -> UUID {
        await tracer.startSpan(name: name, parentId: parentId)
    }
    
    /// 성능 측정 종료
    public func endSpan(id: UUID, metadata: [String: AnyCodable] = [:]) async {
        await tracer.endSpan(id: id, metadata: metadata)
    }
    
    /// 측정 블록 실행
    public func measure<T: Sendable>(
        name: String,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        try await tracer.measure(name: name, operation: operation)
    }
    
    // MARK: - Crash Recovery
    
    /// 크래시 로그 복구
    public func recoverCrashLogs() async -> [LogMessage]? {
        guard let crashPreserver = crashPreserver else { return nil }
        return try? await crashPreserver.recover()
    }
    
    /// 크래시 로그 정리
    public func clearCrashLogs() async {
        try? await crashPreserver?.clear()
    }
    
    // MARK: - Flush
    
    /// 버퍼 플러시
    public func flush() async {
        guard let buffer = buffer else { return }
        let messages = await buffer.flush()
        await dispatchToDestinations(messages)
    }
    
    // MARK: - Private
    
    private func dispatchToDestinations(_ messages: [LogMessage]) async {
        guard !messages.isEmpty else { return }
        
        for destination in destinations {
            let identifier = await destination.identifier
            
            // 비활성화된 destination 스킵
            if configuration.disabledDestinations.contains(identifier) {
                continue
            }
            
            await destination.flush(messages)
        }
    }
}

// MARK: - Static Convenience (Async)

extension Logger {
    /// 정적 로깅 메서드 (shared 인스턴스 사용)
    public static func log(
        level: LogLevel,
        _ message: @autoclosure () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        await shared.log(
            level: level,
            message(),
            category: category,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }
}

// MARK: - Fire-and-Forget API (No await required)

extension Logger {
    
    /// 동기 로그 출력 (Fire-and-Forget)
    /// - Note: await 없이 호출 가능. 내부적으로 Task를 생성하여 비동기 처리
    @_disfavoredOverload
    public nonisolated func log(
        level: LogLevel,
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let capturedMessage = message()
        Task { @LoggerActor in
            await self.log(
                level: level,
                capturedMessage,
                category: category,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )
        }
    }
    
    /// 동기 verbose 로그 (Fire-and-Forget)
    @_disfavoredOverload
    public nonisolated func verbose(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .verbose, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    /// 동기 debug 로그 (Fire-and-Forget)
    @_disfavoredOverload
    public nonisolated func debug(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    /// 동기 info 로그 (Fire-and-Forget)
    @_disfavoredOverload
    public nonisolated func info(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    /// 동기 warning 로그 (Fire-and-Forget)
    @_disfavoredOverload
    public nonisolated func warning(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    /// 동기 error 로그 (Fire-and-Forget)
    @_disfavoredOverload
    public nonisolated func error(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    /// 동기 fatal 로그 (Fire-and-Forget)
    @_disfavoredOverload
    public nonisolated func fatal(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .fatal, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
}

// MARK: - Static Fire-and-Forget API

extension Logger {
    
    /// 정적 동기 로그 출력 (Fire-and-Forget)
    @_disfavoredOverload
    public nonisolated static func log(
        level: LogLevel,
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let capturedMessage = message()
        Task { @LoggerActor in
            await shared.log(
                level: level,
                capturedMessage,
                category: category,
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )
        }
    }
    
    /// 정적 동기 verbose (Fire-and-Forget)
    public nonisolated static func verbose(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .verbose, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    /// 정적 동기 debug (Fire-and-Forget)
    public nonisolated static func debug(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    /// 정적 동기 info (Fire-and-Forget)
    public nonisolated static func info(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    /// 정적 동기 warning (Fire-and-Forget)
    public nonisolated static func warning(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    /// 정적 동기 error (Fire-and-Forget)
    public nonisolated static func error(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
    
    /// 정적 동기 fatal (Fire-and-Forget)
    public nonisolated static func fatal(
        _ message: @autoclosure @escaping @Sendable () -> String,
        category: String = "Default",
        metadata: [String: AnyCodable]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .fatal, message(), category: category, metadata: metadata, file: file, function: function, line: line)
    }
}

