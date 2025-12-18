// RingBuffer.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 고정 크기 순환 버퍼
/// - Note: 크래시 로그 보존 등에 사용되는 FIFO 버퍼
public struct RingBuffer<T: Sendable>: Sendable {
    private var buffer: [T?]
    private var writeIndex: Int = 0
    private var count: Int = 0

    /// 버퍼 용량
    public let capacity: Int

    /// 현재 저장된 요소 수
    public var currentCount: Int { count }

    /// 버퍼가 비어있는지
    public var isEmpty: Bool { count == 0 }

    /// 버퍼가 가득 찼는지
    public var isFull: Bool { count == capacity }

    public init(capacity: Int) {
        precondition(capacity > 0, "Capacity must be greater than 0")
        self.capacity = capacity
        buffer = Array(repeating: nil, count: capacity)
    }

    /// 요소 추가 (가득 차면 가장 오래된 요소 덮어쓰기)
    public mutating func append(_ element: T) {
        buffer[writeIndex] = element
        writeIndex = (writeIndex + 1) % capacity

        if count < capacity {
            count += 1
        }
    }

    /// 모든 요소를 배열로 변환 (오래된 순서)
    public func toArray() -> [T] {
        guard count > 0 else { return [] }

        var result: [T] = []
        result.reserveCapacity(count)

        if count < capacity {
            // 버퍼가 아직 한 바퀴 안 돌았음
            for i in 0 ..< count {
                if let element = buffer[i] {
                    result.append(element)
                }
            }
        } else {
            // 버퍼가 한 바퀴 이상 돌았음
            for i in 0 ..< capacity {
                let index = (writeIndex + i) % capacity
                if let element = buffer[index] {
                    result.append(element)
                }
            }
        }

        return result
    }

    /// 버퍼 비우기
    public mutating func clear() {
        buffer = Array(repeating: nil, count: capacity)
        writeIndex = 0
        count = 0
    }
}
