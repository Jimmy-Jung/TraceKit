// PrettyTraceFormatter.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 가독성 좋은 콘솔 출력용 포맷터
/// - Note: 개발 시 콘솔에서 읽기 쉬운 형태로 포맷
public struct PrettyTraceFormatter: TraceFormatter {
    /// 타임스탬프 포함 여부
    public let includeTimestamp: Bool

    /// 파일/라인 정보 포함 여부
    public let includeLocation: Bool

    /// 메타데이터 포함 여부
    public let includeMetadata: Bool

    /// 이모지 사용 여부
    public let useEmoji: Bool

    /// 메타데이터 줄바꿈 출력 여부
    public let prettyPrintMetadata: Bool

    /// 날짜 포맷터
    private let dateFormatter: DateFormatter

    public init(
        includeTimestamp: Bool = true,
        includeLocation: Bool = true,
        includeMetadata: Bool = true,
        useEmoji: Bool = true,
        prettyPrintMetadata: Bool = true
    ) {
        self.includeTimestamp = includeTimestamp
        self.includeLocation = includeLocation
        self.includeMetadata = includeMetadata
        self.useEmoji = useEmoji
        self.prettyPrintMetadata = prettyPrintMetadata

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }

    public func format(_ message: TraceMessage) -> String {
        var components: [String] = []

        // 타임스탬프
        if includeTimestamp {
            components.append(dateFormatter.string(from: message.timestamp))
        }

        // 레벨
        if useEmoji {
            components.append("\(message.level.emoji) \(message.level.name)")
        } else {
            components.append("[\(message.level.name)]")
        }

        // 카테고리
        components.append("[\(message.category)]")

        // 메시지
        components.append(message.message)

        // 위치 정보
        if includeLocation {
            components.append("(\(message.fileName):\(message.line))")
        }

        var result = components.joined(separator: " ")

        // 메타데이터
        if includeMetadata, let metadata = message.metadata, !metadata.isEmpty {
            if prettyPrintMetadata {
                result += "\n" + formatMetadataPretty(metadata, indent: "  ")
            } else {
                let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
                result += " {\(metadataString)}"
            }
        }

        return result
    }

    // MARK: - Private

    private func formatMetadataPretty(_ metadata: [String: AnyCodable], indent: String) -> String {
        var lines: [String] = []
        let sortedKeys = metadata.keys.sorted()

        for key in sortedKeys {
            guard let value = metadata[key] else { continue }
            let formattedValue = formatValue(value.value, indent: indent + "  ")
            lines.append("\(indent)\(key): \(formattedValue)")
        }

        return lines.joined(separator: "\n")
    }

    private func formatValue(_ value: Any, indent: String) -> String {
        switch value {
        case let dict as [String: Any]:
            if dict.isEmpty { return "{}" }
            var lines: [String] = []
            let sortedKeys = dict.keys.sorted()
            for key in sortedKeys {
                guard let val = dict[key] else { continue }
                let formattedVal = formatValue(val, indent: indent + "  ")
                lines.append("\(indent)\(key): \(formattedVal)")
            }
            return "\n" + lines.joined(separator: "\n")

        case let array as [Any]:
            if array.isEmpty { return "[]" }
            let items = array.map { formatValue($0, indent: indent) }
            return "[\(items.joined(separator: ", "))]"

        case let string as String:
            return string

        case let number as NSNumber:
            return "\(number)"

        default:
            return String(describing: value)
        }
    }
}

// MARK: - 프리셋

public extension PrettyTraceFormatter {
    /// 최소 출력 (레벨 + 메시지만)
    static let minimal = PrettyTraceFormatter(
        includeTimestamp: false,
        includeLocation: false,
        includeMetadata: false,
        useEmoji: true
    )

    /// 표준 출력
    static let standard = PrettyTraceFormatter()

    /// 상세 출력 (모든 정보)
    static let verbose = PrettyTraceFormatter(
        includeTimestamp: true,
        includeLocation: true,
        includeMetadata: true,
        useEmoji: true
    )
}
