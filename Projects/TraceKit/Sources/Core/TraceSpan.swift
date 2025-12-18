// TraceSpan.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 성능 측정을 위한 추적 구간
/// - Note: 시작/종료 시간을 기록하여 구간별 성능 측정
public struct TraceSpan: Sendable, Identifiable, Codable {
    /// 고유 식별자
    public let id: UUID

    /// 추적 구간 이름
    public let name: String

    /// 카테고리
    public let category: String

    /// 시작 시간 (나노초)
    public let startTimeNanos: UInt64

    /// 종료 시간 (나노초)
    public var endTimeNanos: UInt64?

    /// 부모 span ID (중첩된 경우)
    public let parentId: UUID?

    /// 추가 메타데이터
    public var metadata: [String: AnyCodable]

    /// 소요 시간 (밀리초)
    public var durationMs: Double? {
        guard let endTimeNanos = endTimeNanos else { return nil }
        return Double(endTimeNanos - startTimeNanos) / 1_000_000
    }

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        startTimeNanos: UInt64 = DispatchTime.now().uptimeNanoseconds,
        endTimeNanos: UInt64? = nil,
        parentId: UUID? = nil,
        metadata: [String: AnyCodable] = [:]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.startTimeNanos = startTimeNanos
        self.endTimeNanos = endTimeNanos
        self.parentId = parentId
        self.metadata = metadata
    }

    /// 종료 처리된 새 TraceSpan 반환
    public func ended(metadata additionalMetadata: [String: AnyCodable] = [:]) -> TraceSpan {
        var newSpan = TraceSpan(
            id: id,
            name: name,
            category: category,
            startTimeNanos: startTimeNanos,
            endTimeNanos: DispatchTime.now().uptimeNanoseconds,
            parentId: parentId,
            metadata: metadata
        )

        for (key, value) in additionalMetadata {
            newSpan.metadata[key] = value
        }

        return newSpan
    }

    /// Dictionary로 변환
    public func toDictionary() -> [String: AnyCodable] {
        var dict: [String: AnyCodable] = [
            "spanId": AnyCodable(id.uuidString),
            "name": AnyCodable(name),
            "category": AnyCodable(category),
            "startTimeNanos": AnyCodable(Int(startTimeNanos)),
        ]

        if let endTimeNanos = endTimeNanos {
            dict["endTimeNanos"] = AnyCodable(Int(endTimeNanos))
        }

        if let durationMs = durationMs {
            dict["durationMs"] = AnyCodable(durationMs)
        }

        if let parentId = parentId {
            dict["parentId"] = AnyCodable(parentId.uuidString)
        }

        for (key, value) in metadata {
            dict[key] = value
        }

        return dict
    }
}
