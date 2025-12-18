// TraceBuffer.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로그 버퍼 액터
/// - Note: 로그를 일시 저장하고 배치로 플러시
public actor TraceBuffer {
    /// 버퍼 정책
    private let policy: TraceBufferPolicy

    /// 내부 버퍼
    private var buffer: [TraceMessage] = []

    /// 자동 플러시 타이머 태스크
    private var autoFlushTask: Task<Void, Never>?

    /// 플러시 핸들러
    private var flushHandler: (([TraceMessage]) async -> Void)?

    public init(policy: TraceBufferPolicy = .default) {
        self.policy = policy
    }

    /// 로그 추가
    /// - Parameter message: 로그 메시지
    /// - Returns: 즉시 플러시가 필요한 경우 true
    @discardableResult
    public func append(_ message: TraceMessage) async -> Bool {
        buffer.append(message)

        // 즉시 플러시 조건 확인
        let shouldFlushImmediately = shouldFlushImmediately(for: message)

        if shouldFlushImmediately || buffer.count >= policy.maxSize {
            await performFlush()
            return true
        }

        return false
    }

    /// 여러 로그 추가
    public func append(contentsOf messages: [TraceMessage]) async {
        buffer.append(contentsOf: messages)

        if buffer.count >= policy.maxSize {
            await performFlush()
        }
    }

    /// 수동 플러시
    public func flush() async -> [TraceMessage] {
        let messages = buffer
        buffer.removeAll()
        return messages
    }

    /// 자동 플러시 시작
    public func startAutoFlush(handler: @escaping ([TraceMessage]) async -> Void) {
        flushHandler = handler

        guard policy.flushInterval > 0 else { return }

        autoFlushTask?.cancel()
        autoFlushTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self?.policy.flushInterval ?? 0 * 1_000_000_000))

                guard !Task.isCancelled else { break }
                await self?.performFlush()
            }
        }
    }

    /// 자동 플러시 중지
    public func stopAutoFlush() {
        autoFlushTask?.cancel()
        autoFlushTask = nil
    }

    /// 현재 버퍼 크기
    public var count: Int {
        buffer.count
    }

    /// 버퍼가 비어있는지
    public var isEmpty: Bool {
        buffer.isEmpty
    }

    // MARK: - Private

    private func shouldFlushImmediately(for message: TraceMessage) -> Bool {
        guard let flushOnLevel = policy.flushOnLevel else { return false }
        return message.level >= flushOnLevel
    }

    private func performFlush() async {
        guard !buffer.isEmpty else { return }

        let messages = buffer
        buffer.removeAll()

        await flushHandler?(messages)
    }

    deinit {
        autoFlushTask?.cancel()
    }
}
