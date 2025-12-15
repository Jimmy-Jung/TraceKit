// CrashLogPreserver.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 크래시 로그 보존기
/// - Note: 크래시 직전 로그를 저장하고 다음 실행 시 복구
public actor CrashLogPreserver {
    /// 링 버퍼 (최근 N개 로그 보관)
    private var ringBuffer: RingBuffer<LogMessage>
    
    /// 보존할 로그 수
    public nonisolated let preserveCount: Int
    
    /// 저장 파일 URL
    private let storageURL: URL
    
    /// 파일 매니저
    private let fm = FileManager.default
    
    /// JSON 인코더/디코더
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init(
        preserveCount: Int = 50,
        storageURL: URL? = nil
    ) {
        self.preserveCount = preserveCount
        self.ringBuffer = RingBuffer(capacity: preserveCount)
        
        if let storageURL = storageURL {
            self.storageURL = storageURL
        } else {
            let cachesDir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
            self.storageURL = cachesDir.appendingPathComponent("crash_logs.json")
        }
    }
    
    /// 로그 기록
    public func record(_ message: LogMessage) {
        ringBuffer.append(message)
    }
    
    /// 현재 버퍼를 파일에 저장 (크래시 전 호출)
    public func persist() throws {
        let messages = ringBuffer.toArray()
        guard !messages.isEmpty else { return }
        
        let data = try encoder.encode(messages)
        try data.write(to: storageURL, options: .atomic)
    }
    
    /// 저장된 로그 복구 (앱 시작 시 호출)
    public func recover() throws -> [LogMessage]? {
        guard fm.fileExists(atPath: storageURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: storageURL)
        let messages = try decoder.decode([LogMessage].self, from: data)
        
        return messages.isEmpty ? nil : messages
    }
    
    /// 저장된 로그 삭제
    public func clear() throws {
        if fm.fileExists(atPath: storageURL.path) {
            try fm.removeItem(at: storageURL)
        }
        ringBuffer.clear()
    }
    
    /// 현재 버퍼 내용 확인
    public func currentLogs() -> [LogMessage] {
        ringBuffer.toArray()
    }
    
    /// 현재 버퍼 크기
    public var count: Int {
        ringBuffer.currentCount
    }
    
    /// 동기적으로 저장 (Signal Handler용)
    /// - Note: Actor isolation을 우회하므로 주의해서 사용
    public nonisolated func persistSync() {
        // Signal handler에서는 async 사용 불가
        // 최소한의 동기 작업만 수행
        let messages = Task {
            await self.ringBuffer.toArray()
        }
        
        // 동기적 저장은 제한적
        // 실제 구현에서는 mmap이나 dispatch_sync 사용 고려
    }
}

// MARK: - Signal Handler 등록

extension CrashLogPreserver {
    /// 크래시 시그널 핸들러 등록
    /// - Note: SIGABRT, SIGSEGV 등 처리
    public static func registerSignalHandlers(preserver: CrashLogPreserver) {
        // Signal handler에서는 async-safe 함수만 사용 가능
        // 실제 구현에서는 전역 변수를 통해 접근
        
        let signals: [Int32] = [SIGABRT, SIGSEGV, SIGBUS, SIGFPE, SIGILL, SIGTRAP]
        
        for sig in signals {
            signal(sig) { signalNumber in
                // Signal handler에서는 제한된 작업만 가능
                // 실제로는 이전에 열어둔 파일 디스크립터에 직접 쓰기
                // 여기서는 간단히 처리
                exit(signalNumber)
            }
        }
    }
}

