// RingBufferTests.swift
// TraceKitTests
//
// Created by jimmy on 2025-12-15.

import Foundation
import Testing
@testable import TraceKit

// MARK: - RingBuffer Tests

struct RingBufferTests {
    // MARK: - Creation Tests

    @Test("빈 버퍼 생성")
    func createEmptyBuffer() {
        // Given & When
        let buffer = RingBuffer<Int>(capacity: 5)

        // Then
        #expect(buffer.isEmpty)
        #expect(buffer.currentCount == 0)
        #expect(buffer.capacity == 5)
        #expect(!buffer.isFull)
    }

    // MARK: - Append Tests

    @Test("요소 추가 시 카운트 증가")
    func appendIncreasesCount() {
        // Given
        var buffer = RingBuffer<Int>(capacity: 5)

        // When
        buffer.append(1)

        // Then
        #expect(buffer.currentCount == 1)
        #expect(!buffer.isEmpty)
    }

    @Test("용량까지 채우면 isFull")
    func fullWhenAtCapacity() {
        // Given
        var buffer = RingBuffer<Int>(capacity: 3)

        // When
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)

        // Then
        #expect(buffer.isFull)
        #expect(buffer.currentCount == 3)
    }

    // MARK: - Overwrite Tests

    @Test("가득 찬 후 추가 시 오래된 요소 덮어쓰기")
    func overwritesOldestWhenFull() {
        // Given
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)

        // When
        buffer.append(4)

        // Then
        #expect(buffer.currentCount == 3)
        let array = buffer.toArray()
        #expect(array == [2, 3, 4])
    }

    @Test("여러 번 순환 후에도 순서 유지")
    func maintainsOrderAfterMultipleWraps() {
        // Given
        var buffer = RingBuffer<Int>(capacity: 3)

        // When
        for i in 1 ... 6 {
            buffer.append(i)
        }

        // Then
        let array = buffer.toArray()
        #expect(array == [4, 5, 6])
    }

    // MARK: - toArray Tests

    @Test("빈 버퍼의 toArray는 빈 배열")
    func toArrayEmptyBuffer() {
        // Given
        let buffer = RingBuffer<Int>(capacity: 5)

        // When
        let array = buffer.toArray()

        // Then
        #expect(array.isEmpty)
    }

    @Test("부분적으로 채워진 버퍼의 toArray")
    func toArrayPartiallyFilled() {
        // Given
        var buffer = RingBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)

        // When
        let array = buffer.toArray()

        // Then
        #expect(array == [1, 2])
    }

    // MARK: - Clear Tests

    @Test("clear 후 빈 상태")
    func clearMakesEmpty() {
        // Given
        var buffer = RingBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)

        // When
        buffer.clear()

        // Then
        #expect(buffer.isEmpty)
        #expect(buffer.currentCount == 0)
        #expect(buffer.toArray().isEmpty)
    }

    @Test("clear 후 다시 사용 가능")
    func canReuseAfterClear() {
        // Given
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.clear()

        // When
        buffer.append(10)
        buffer.append(20)

        // Then
        #expect(buffer.currentCount == 2)
        #expect(buffer.toArray() == [10, 20])
    }

    // MARK: - Generic Type Tests

    @Test("String 타입 지원")
    func supportsStringType() {
        // Given
        var buffer = RingBuffer<String>(capacity: 2)

        // When
        buffer.append("hello")
        buffer.append("world")

        // Then
        #expect(buffer.toArray() == ["hello", "world"])
    }

    @Test("커스텀 Sendable 타입 지원")
    func supportsCustomSendableType() {
        // Given
        struct Item: Sendable, Equatable {
            let id: Int
            let name: String
        }

        var buffer = RingBuffer<Item>(capacity: 2)

        // When
        buffer.append(Item(id: 1, name: "A"))
        buffer.append(Item(id: 2, name: "B"))

        // Then
        let array = buffer.toArray()
        #expect(array.count == 2)
        #expect(array[0].id == 1)
        #expect(array[1].id == 2)
    }
}
