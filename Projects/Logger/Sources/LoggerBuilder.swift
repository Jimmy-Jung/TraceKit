// LoggerBuilder.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로거 빌더
/// - Note: 빌더 패턴으로 Logger 구성
public final class LoggerBuilder: @unchecked Sendable {
    
    // MARK: - Properties
    
    private var destinations: [any LogDestination] = []
    private var configuration: LoggerConfiguration = .default
    private var bufferPolicy: LogBufferPolicy?
    private var samplingPolicy: SamplingPolicy?
    private var sanitizer: LogSanitizer?
    private var contextProvider: (any UserContextProvider)?
    private var crashPreserveCount: Int?
    private var applyLaunchArgs: Bool = false
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Builder Methods
    
    /// Destination 추가
    @discardableResult
    public func addDestination(_ destination: any LogDestination) -> Self {
        destinations.append(destination)
        return self
    }
    
    /// 콘솔 Destination 추가
    @discardableResult
    public func addConsole(
        minLevel: LogLevel = .verbose,
        formatter: LogFormatter = PrettyLogFormatter.standard
    ) -> Self {
        let console = ConsoleLogDestination(
            minLevel: minLevel,
            formatter: formatter
        )
        return addDestination(console)
    }
    
    /// OSLog Destination 추가
    @available(iOS 14.0, *)
    @discardableResult
    public func addOSLog(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.logger",
        minLevel: LogLevel = .verbose
    ) -> Self {
        let oslog = OSLogDestination(
            subsystem: subsystem,
            minLevel: minLevel
        )
        return addDestination(oslog)
    }
    
    /// 파일 Destination 추가
    @discardableResult
    public func addFile(
        minLevel: LogLevel = .verbose,
        retentionPolicy: LogFileRetentionPolicy = .default
    ) -> Self {
        let fileManager = LogFileManager(retentionPolicy: retentionPolicy)
        let file = FileLogDestination(
            minLevel: minLevel,
            fileManager: fileManager
        )
        return addDestination(file)
    }
    
    /// 설정 적용
    @discardableResult
    public func with(configuration: LoggerConfiguration) -> Self {
        self.configuration = configuration
        return self
    }
    
    /// 버퍼 정책 설정
    @discardableResult
    public func withBuffer(policy: LogBufferPolicy = .default) -> Self {
        self.bufferPolicy = policy
        return self
    }
    
    /// 샘플링 정책 설정
    @discardableResult
    public func withSampling(policy: SamplingPolicy) -> Self {
        self.samplingPolicy = policy
        return self
    }
    
    /// 정제기 설정
    @discardableResult
    public func withSanitizer(_ sanitizer: LogSanitizer) -> Self {
        self.sanitizer = sanitizer
        return self
    }
    
    /// 기본 정제기 사용
    @discardableResult
    public func withDefaultSanitizer() -> Self {
        self.sanitizer = DefaultLogSanitizer()
        return self
    }
    
    /// 컨텍스트 제공자 설정
    @discardableResult
    public func withContextProvider(_ provider: any UserContextProvider) -> Self {
        self.contextProvider = provider
        return self
    }
    
    /// 기본 컨텍스트 제공자 사용
    @discardableResult
    public func withDefaultContextProvider(environment: Environment = .debug) -> Self {
        self.contextProvider = DefaultUserContextProvider(environment: environment)
        return self
    }
    
    /// 크래시 로그 보존 활성화
    @discardableResult
    public func withCrashPreservation(count: Int = 50) -> Self {
        self.crashPreserveCount = count
        return self
    }
    
    /// Launch Argument 오버라이드 적용
    @discardableResult
    public func applyLaunchArguments() -> Self {
        self.applyLaunchArgs = true
        return self
    }
    
    // MARK: - Build
    
    /// Logger 빌드
    @LoggerActor
    public func build() async -> Logger {
        // Launch Argument 적용
        var finalConfig = configuration
        if applyLaunchArgs, let launchConfig = LaunchArgumentParser.parse() {
            finalConfig = finalConfig.merged(with: launchConfig)
        }
        
        let logger = Logger(configuration: finalConfig)
        
        // Destinations 추가
        for destination in destinations {
            logger.addDestination(destination)
        }
        
        // 버퍼 설정
        if let bufferPolicy = bufferPolicy {
            let buffer = LogBuffer(policy: bufferPolicy)
            logger.setBuffer(buffer)
        }
        
        // 샘플러 설정
        if let samplingPolicy = samplingPolicy {
            let sampler = LogSampler(policy: samplingPolicy)
            logger.setSampler(sampler)
        }
        
        // 정제기 설정
        if let sanitizer = sanitizer {
            logger.setSanitizer(sanitizer)
        }
        
        // 컨텍스트 제공자 설정
        if let contextProvider = contextProvider {
            logger.setContextProvider(contextProvider)
        }
        
        // 크래시 보존기 설정
        if let crashPreserveCount = crashPreserveCount {
            let crashPreserver = CrashLogPreserver(preserveCount: crashPreserveCount)
            logger.setCrashPreserver(crashPreserver)
        }
        
        return logger
    }
    
    /// 공유 인스턴스로 빌드
    @LoggerActor
    public func buildAsShared() async -> Logger {
        let logger = await build()
        Logger.shared = logger
        return logger
    }
}

// MARK: - Convenience

extension LoggerBuilder {
    /// 디버그용 기본 설정
    public static func debug() -> LoggerBuilder {
        LoggerBuilder()
            .addConsole(formatter: PrettyLogFormatter.verbose)
            .with(configuration: .debug)
            .withDefaultSanitizer()
            .applyLaunchArguments()
    }
    
    /// 프로덕션용 기본 설정
    @available(iOS 14.0, *)
    public static func production() -> LoggerBuilder {
        LoggerBuilder()
            .addConsole(minLevel: .warning)
            .addOSLog(minLevel: .info)
            .addFile(minLevel: .info)
            .with(configuration: .production)
            .withBuffer(policy: .default)
            .withSampling(policy: .production)
            .withDefaultSanitizer()
            .withCrashPreservation()
            .applyLaunchArguments()
    }
}

