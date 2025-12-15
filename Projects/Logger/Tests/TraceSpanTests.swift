// TraceSpanTests.swift
// LoggerTests
//
// Created by jimmy on 2025-12-15.

import Testing
import Foundation
@testable import Logger

// MARK: - TraceSpan Tests

struct TraceSpanTests {
    
    // MARK: - Creation Tests
    
    @Test("TraceSpan 기본 생성")
    func createBasicTraceSpan() {
        // Given & When
        let span = TraceSpan(
            name: "fetchUser",
            category: "API"
        )
        
        // Then
        #expect(span.name == "fetchUser")
        #expect(span.category == "API")
        #expect(span.endTimeNanos == nil)
        #expect(span.parentId == nil)
    }
    
    @Test("TraceSpan parentId 설정")
    func createWithParentId() {
        // Given
        let parentId = UUID()
        
        // When
        let span = TraceSpan(
            name: "child",
            category: "API",
            parentId: parentId
        )
        
        // Then
        #expect(span.parentId == parentId)
    }
    
    // MARK: - Duration Tests
    
    @Test("종료되지 않은 span의 duration은 nil")
    func durationIsNilBeforeEnd() {
        // Given
        let span = TraceSpan(name: "test", category: "Test")
        
        // Then
        #expect(span.durationMs == nil)
    }
    
    @Test("ended() 호출 후 duration 계산")
    func durationAfterEnded() {
        // Given
        let span = TraceSpan(name: "test", category: "Test")
        
        // When
        let endedSpan = span.ended()
        
        // Then
        #expect(endedSpan.endTimeNanos != nil)
        #expect(endedSpan.durationMs != nil)
        #expect(endedSpan.durationMs! >= 0)
    }
    
    // MARK: - Metadata Tests
    
    @Test("ended()에 메타데이터 추가")
    func endedWithMetadata() {
        // Given
        let span = TraceSpan(name: "api", category: "Network")
        
        // When
        let endedSpan = span.ended(metadata: [
            "statusCode": AnyCodable(200),
            "cached": AnyCodable(false)
        ])
        
        // Then
        #expect(endedSpan.metadata["statusCode"] != nil)
        #expect(endedSpan.metadata["cached"] != nil)
    }
    
    @Test("기존 메타데이터 유지")
    func existingMetadataPreserved() {
        // Given
        let span = TraceSpan(
            name: "api",
            category: "Network",
            metadata: ["requestId": AnyCodable("req123")]
        )
        
        // When
        let endedSpan = span.ended(metadata: ["statusCode": AnyCodable(200)])
        
        // Then
        #expect(endedSpan.metadata["requestId"] != nil)
        #expect(endedSpan.metadata["statusCode"] != nil)
    }
    
    // MARK: - toDictionary Tests
    
    @Test("toDictionary가 필수 필드 포함")
    func toDictionaryContainsRequiredFields() {
        // Given
        let span = TraceSpan(name: "test", category: "Test")
        
        // When
        let dict = span.toDictionary()
        
        // Then
        #expect(dict["spanId"] != nil)
        #expect(dict["name"] != nil)
        #expect(dict["category"] != nil)
        #expect(dict["startTimeNanos"] != nil)
    }
    
    @Test("종료된 span의 toDictionary가 duration 포함")
    func toDictionaryContainsDurationAfterEnd() {
        // Given
        let span = TraceSpan(name: "test", category: "Test").ended()
        
        // When
        let dict = span.toDictionary()
        
        // Then
        #expect(dict["endTimeNanos"] != nil)
        #expect(dict["durationMs"] != nil)
    }
    
    // MARK: - Identifiable Tests
    
    @Test("각 span은 고유 ID 보유")
    func uniqueIds() {
        // Given & When
        let span1 = TraceSpan(name: "test1", category: "Test")
        let span2 = TraceSpan(name: "test2", category: "Test")
        
        // Then
        #expect(span1.id != span2.id)
    }
    
    // MARK: - Codable Tests
    
    @Test("TraceSpan Codable 인코딩/디코딩")
    func codableEncodingDecoding() throws {
        // Given
        let original = TraceSpan(
            name: "api",
            category: "Network",
            metadata: ["key": AnyCodable("value")]
        ).ended()
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(TraceSpan.self, from: data)
        
        // Then
        #expect(decoded.name == original.name)
        #expect(decoded.category == original.category)
        #expect(decoded.endTimeNanos != nil)
    }
}

