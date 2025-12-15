// PrettyLogFormatter.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 가독성 좋은 콘솔 출력용 포맷터
/// - Note: 개발 시 콘솔에서 읽기 쉬운 형태로 포맷
public struct PrettyLogFormatter: LogFormatter {
    /// 타임스탬프 포함 여부
    public let includeTimestamp: Bool
    
    /// 파일/라인 정보 포함 여부
    public let includeLocation: Bool
    
    /// 메타데이터 포함 여부
    public let includeMetadata: Bool
    
    /// 이모지 사용 여부
    public let useEmoji: Bool
    
    /// 날짜 포맷터
    private let dateFormatter: DateFormatter
    
    public init(
        includeTimestamp: Bool = true,
        includeLocation: Bool = true,
        includeMetadata: Bool = true,
        useEmoji: Bool = true
    ) {
        self.includeTimestamp = includeTimestamp
        self.includeLocation = includeLocation
        self.includeMetadata = includeMetadata
        self.useEmoji = useEmoji
        
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }
    
    public func format(_ message: LogMessage) -> String {
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
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            result += " {\(metadataString)}"
        }
        
        return result
    }
}

// MARK: - 프리셋

extension PrettyLogFormatter {
    /// 최소 출력 (레벨 + 메시지만)
    public static let minimal = PrettyLogFormatter(
        includeTimestamp: false,
        includeLocation: false,
        includeMetadata: false,
        useEmoji: true
    )
    
    /// 표준 출력
    public static let standard = PrettyLogFormatter()
    
    /// 상세 출력 (모든 정보)
    public static let verbose = PrettyLogFormatter(
        includeTimestamp: true,
        includeLocation: true,
        includeMetadata: true,
        useEmoji: true
    )
}

