// PerformanceTracerTests.swift
// LoggerTests
//
// Created by jimmy on 2025-12-15.

import Testing
import Foundation
@testable import Logger

// MARK: - PerformanceTracer Tests

struct PerformanceTracerTests {
    
    // MARK: - Start Span Tests
    
    @Test("span 시작 시 ID 반환")
    func startSpanReturnsId() async {
        // Given
        let tracer = PerformanceTracer()
        
        // When
        let spanId = await tracer.startSpan(name: "test")
        
        // Then
        #expect(spanId != UUID())
    }
    
    @Test("span 시작 시 활성 카운트 증가")
    func startSpanIncreasesActiveCount() async {
        // Given
        let tracer = PerformanceTracer()
        
        // When
        _ = await tracer.startSpan(name: "test1")
        _ = await tracer.startSpan(name: "test2")
        
        // Then
        let count = await tracer.activeSpanCount
        #expect(count == 2)
    }
    
    // MARK: - End Span Tests
    
    @Test("span 종료 시 활성 카운트 감소")
    func endSpanDecreasesActiveCount() async {
        // Given
        let tracer = PerformanceTracer()
        let spanId = await tracer.startSpan(name: "test")
        
        // When
        _ = await tracer.endSpan(id: spanId)
        
        // Then
        let count = await tracer.activeSpanCount
        #expect(count == 0)
    }
    
    @Test("span 종료 시 완료된 span 반환")
    func endSpanReturnsCompletedSpan() async {
        // Given
        let tracer = PerformanceTracer()
        let spanId = await tracer.startSpan(name: "fetchUser")
        
        // When
        let completedSpan = await tracer.endSpan(id: spanId)
        
        // Then
        #expect(completedSpan != nil)
        #expect(completedSpan?.name == "fetchUser")
        #expect(completedSpan?.durationMs != nil)
    }
    
    @Test("존재하지 않는 span 종료 시 nil")
    func endNonExistentSpanReturnsNil() async {
        // Given
        let tracer = PerformanceTracer()
        let fakeId = UUID()
        
        // When
        let result = await tracer.endSpan(id: fakeId)
        
        // Then
        #expect(result == nil)
    }
    
    @Test("span 종료 시 메타데이터 추가")
    func endSpanWithMetadata() async {
        // Given
        let tracer = PerformanceTracer()
        let spanId = await tracer.startSpan(name: "api")
        
        // When
        let completedSpan = await tracer.endSpan(
            id: spanId,
            metadata: ["statusCode": AnyCodable(200)]
        )
        
        // Then
        #expect(completedSpan?.metadata["statusCode"] != nil)
    }
    
    // MARK: - Measure Tests
    
    @Test("measure로 비동기 작업 측정")
    func measureAsyncOperation() async {
        // Given
        let tracer = PerformanceTracer()
        
        // When
        let result = await tracer.measure(name: "compute") {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return 42
        }
        
        // Then
        #expect(result == 42)
        
        let count = await tracer.activeSpanCount
        #expect(count == 0)
    }
    
    @Test("measure에서 에러 발생 시 span 종료")
    func measureEndsSpanOnError() async throws {
        // Given
        let tracer = PerformanceTracer()
        
        struct TestError: Error {}
        
        // When & Then
        do {
            _ = try await tracer.measure(name: "failing") {
                throw TestError()
            }
            Issue.record("Expected error to be thrown")
        } catch {
            // 에러 발생해도 span은 종료되어야 함
            let count = await tracer.activeSpanCount
            #expect(count == 0)
        }
    }
    
    // MARK: - Cancel All Spans Tests
    
    @Test("모든 span 취소")
    func cancelAllSpans() async {
        // Given
        let tracer = PerformanceTracer()
        _ = await tracer.startSpan(name: "span1")
        _ = await tracer.startSpan(name: "span2")
        _ = await tracer.startSpan(name: "span3")
        
        // When
        await tracer.cancelAllSpans()
        
        // Then
        let count = await tracer.activeSpanCount
        #expect(count == 0)
    }
    
    // MARK: - Parent Span Tests
    
    @Test("부모 span ID 설정")
    func parentSpanId() async {
        // Given
        let tracer = PerformanceTracer()
        let parentId = await tracer.startSpan(name: "parent")
        
        // When
        let childId = await tracer.startSpan(name: "child", parentId: parentId)
        
        // Then
        #expect(childId != parentId)
        
        let count = await tracer.activeSpanCount
        #expect(count == 2)
    }
}

