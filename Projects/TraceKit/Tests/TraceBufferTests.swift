// TraceBufferTests.swift
// TraceKitTests
//
// Created by jimmy on 2025-12-15.

import Foundation
import Testing
@testable import TraceKit

// MARK: - TraceBuffer Tests

struct TraceBufferTests {
    // MARK: - Creation Tests

    @Test("빈 버퍼 생성")
    func createEmptyBuffer() async {
        // Given & When
        let buffer = TraceBuffer()

        // Then
        let isEmpty = await buffer.isEmpty
        let count = await buffer.count

        #expect(isEmpty)
        #expect(count == 0)
    }

    // MARK: - Append Tests

    @Test("메시지 추가")
    func appendMessage() async {
        // Given
        let buffer = TraceBuffer(policy: .default)
        let message = createTestMessage(level: .info)

        // When
        await buffer.append(message)

        // Then
        let count = await buffer.count
        #expect(count == 1)
    }

    @Test("여러 메시지 추가")
    func appendMultipleMessages() async {
        // Given
        let buffer = TraceBuffer(policy: .default)

        // When
        for i in 0 ..< 5 {
            await buffer.append(createTestMessage(level: .info, message: "Message \(i)"))
        }

        // Then
        let count = await buffer.count
        #expect(count == 5)
    }

    // MARK: - Flush Tests

    @Test("플러시 시 모든 메시지 반환")
    func flushReturnsAllMessages() async {
        // Given
        let buffer = TraceBuffer(policy: .default)
        for i in 0 ..< 3 {
            await buffer.append(createTestMessage(level: .info, message: "Message \(i)"))
        }

        // When
        let flushed = await buffer.flush()

        // Then
        #expect(flushed.count == 3)

        let isEmpty = await buffer.isEmpty
        #expect(isEmpty)
    }

    @Test("플러시 후 버퍼 비어있음")
    func bufferEmptyAfterFlush() async {
        // Given
        let buffer = TraceBuffer(policy: .default)
        await buffer.append(createTestMessage(level: .info))

        // When
        _ = await buffer.flush()

        // Then
        let count = await buffer.count
        #expect(count == 0)
    }

    // MARK: - Max Size Tests

    @Test("최대 크기 도달 시 자동 플러시 트리거")
    func autoFlushOnMaxSize() async {
        // Given
        let policy = TraceBufferPolicy(maxSize: 3, flushInterval: 0, flushOnLevel: nil)
        let buffer = TraceBuffer(policy: policy)

        var flushedCount = 0
        await buffer.startAutoFlush { messages in
            flushedCount = messages.count
        }

        // When
        for i in 0 ..< 3 {
            await buffer.append(createTestMessage(level: .info, message: "Message \(i)"))
        }

        // 잠시 대기 (비동기 플러시 처리)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(flushedCount == 3)

        await buffer.stopAutoFlush()
    }

    // MARK: - Flush On Level Tests

    @Test("특정 레벨 이상에서 즉시 플러시")
    func immediateFlushOnLevel() async {
        // Given
        let policy = TraceBufferPolicy(
            maxSize: 100,
            flushInterval: 0,
            flushOnLevel: .error
        )
        let buffer = TraceBuffer(policy: policy)

        // When
        let shouldFlush = await buffer.append(createTestMessage(level: .error))

        // Then
        #expect(shouldFlush == true)
    }

    @Test("낮은 레벨에서는 즉시 플러시 안 함")
    func noImmediateFlushOnLowerLevel() async {
        // Given
        let policy = TraceBufferPolicy(
            maxSize: 100,
            flushInterval: 0,
            flushOnLevel: .error
        )
        let buffer = TraceBuffer(policy: policy)

        // When
        let shouldFlush = await buffer.append(createTestMessage(level: .info))

        // Then
        #expect(shouldFlush == false)
    }

    // MARK: - Append ContentsOf Tests

    @Test("여러 메시지 한 번에 추가")
    func appendContentsOf() async {
        // Given
        let buffer = TraceBuffer(policy: .default)
        let messages = (0 ..< 5).map { createTestMessage(level: .info, message: "Message \($0)") }

        // When
        await buffer.append(contentsOf: messages)

        // Then
        let count = await buffer.count
        #expect(count == 5)
    }

    // MARK: - Helper

    private func createTestMessage(
        level: TraceLevel,
        message: String = "Test"
    ) -> TraceMessage {
        TraceMessage(
            level: level,
            message: message,
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
    }
}
