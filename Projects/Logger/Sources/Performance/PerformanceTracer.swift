// PerformanceTracer.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 성능 측정 추적기
/// - Note: 구간별 성능 측정 및 자동 로깅
public actor PerformanceTracer {
    /// 활성화된 span 목록
    private var activeSpans: [UUID: TraceSpan] = [:]
    
    /// 로거 참조 (weak 대신 클로저 사용)
    private let logHandler: ((LogLevel, String, String, [String: AnyCodable]) async -> Void)?
    
    /// 카테고리
    private let category: String
    
    public init(
        category: String = "Performance",
        logHandler: ((LogLevel, String, String, [String: AnyCodable]) async -> Void)? = nil
    ) {
        self.category = category
        self.logHandler = logHandler
    }
    
    /// Span 시작
    /// - Parameters:
    ///   - name: Span 이름
    ///   - parentId: 부모 Span ID (중첩 시)
    /// - Returns: 생성된 Span ID
    public func startSpan(name: String, parentId: UUID? = nil) -> UUID {
        let span = TraceSpan(
            name: name,
            category: category,
            parentId: parentId
        )
        
        activeSpans[span.id] = span
        return span.id
    }
    
    /// Span 종료
    /// - Parameters:
    ///   - id: Span ID
    ///   - metadata: 추가 메타데이터
    /// - Returns: 완료된 Span (없으면 nil)
    @discardableResult
    public func endSpan(id: UUID, metadata: [String: AnyCodable] = [:]) async -> TraceSpan? {
        guard let span = activeSpans.removeValue(forKey: id) else {
            return nil
        }
        
        let completedSpan = span.ended(metadata: metadata)
        
        // 자동 로깅
        if let logHandler = logHandler, let durationMs = completedSpan.durationMs {
            let message = "[\(completedSpan.name)] completed in \(String(format: "%.2f", durationMs))ms"
            await logHandler(.debug, message, category, completedSpan.toDictionary())
        }
        
        return completedSpan
    }
    
    /// 측정 블록 실행
    /// - Parameters:
    ///   - name: Span 이름
    ///   - operation: 측정할 작업
    /// - Returns: 작업 결과
    public func measure<T: Sendable>(
        name: String,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        let spanId = startSpan(name: name)
        
        do {
            let result = try await operation()
            await endSpan(id: spanId, metadata: ["success": true])
            return result
        } catch {
            await endSpan(id: spanId, metadata: [
                "success": false,
                "error": AnyCodable(error.localizedDescription)
            ])
            throw error
        }
    }
    
    /// 동기 측정 블록 실행
    public func measureSync<T>(
        name: String,
        operation: () throws -> T
    ) async rethrows -> T {
        let spanId = startSpan(name: name)
        
        do {
            let result = try operation()
            await endSpan(id: spanId, metadata: ["success": true])
            return result
        } catch {
            await endSpan(id: spanId, metadata: [
                "success": false,
                "error": AnyCodable(error.localizedDescription)
            ])
            throw error
        }
    }
    
    /// 활성 Span 수
    public var activeSpanCount: Int {
        activeSpans.count
    }
    
    /// 모든 활성 Span 취소
    public func cancelAllSpans() {
        activeSpans.removeAll()
    }
}

