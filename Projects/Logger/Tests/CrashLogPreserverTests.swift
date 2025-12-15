// CrashLogPreserverTests.swift
// LoggerTests
//
// Created by jimmy on 2025-12-15.

import Testing
import Foundation
@testable import Logger

// MARK: - CrashLogPreserver Tests

struct CrashLogPreserverTests {
    
    // MARK: - Creation Tests
    
    @Test("기본 보존 개수 설정")
    func defaultPreserveCount() async {
        // Given & When
        let preserver = CrashLogPreserver(preserveCount: 50)
        
        // Then
        #expect(preserver.preserveCount == 50)
    }
    
    // MARK: - Record Tests
    
    @Test("로그 기록")
    func recordLog() async {
        // Given
        let preserver = CrashLogPreserver(preserveCount: 10)
        let message = createTestMessage(level: .error, message: "Error occurred")
        
        // When
        await preserver.record(message)
        
        // Then
        let count = await preserver.count
        #expect(count == 1)
    }
    
    @Test("여러 로그 기록")
    func recordMultipleLogs() async {
        // Given
        let preserver = CrashLogPreserver(preserveCount: 10)
        
        // When
        for i in 0..<5 {
            await preserver.record(createTestMessage(level: .info, message: "Log \(i)"))
        }
        
        // Then
        let count = await preserver.count
        #expect(count == 5)
    }
    
    @Test("보존 개수 초과 시 오래된 로그 삭제")
    func overwritesOldLogsWhenFull() async {
        // Given
        let preserver = CrashLogPreserver(preserveCount: 3)
        
        // When
        for i in 0..<5 {
            await preserver.record(createTestMessage(level: .info, message: "Log \(i)"))
        }
        
        // Then
        let logs = await preserver.currentLogs()
        #expect(logs.count == 3)
        
        // 최신 3개 (Log 2, 3, 4)만 남아야 함
        #expect(logs[0].message == "Log 2")
        #expect(logs[2].message == "Log 4")
    }
    
    // MARK: - Current Logs Tests
    
    @Test("현재 로그 확인")
    func currentLogs() async {
        // Given
        let preserver = CrashLogPreserver(preserveCount: 10)
        await preserver.record(createTestMessage(level: .error, message: "Error 1"))
        await preserver.record(createTestMessage(level: .warning, message: "Warning 1"))
        
        // When
        let logs = await preserver.currentLogs()
        
        // Then
        #expect(logs.count == 2)
        #expect(logs[0].message == "Error 1")
        #expect(logs[1].message == "Warning 1")
    }
    
    // MARK: - Persist & Recover Tests
    
    @Test("저장 및 복구")
    func persistAndRecover() async throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_crash_logs_\(UUID().uuidString).json")
        let preserver = CrashLogPreserver(preserveCount: 10, storageURL: tempURL)
        
        await preserver.record(createTestMessage(level: .error, message: "Critical error"))
        await preserver.record(createTestMessage(level: .fatal, message: "Fatal crash"))
        
        // When
        try await preserver.persist()
        let recovered = try await preserver.recover()
        
        // Then
        #expect(recovered != nil)
        #expect(recovered?.count == 2)
        #expect(recovered?[0].message == "Critical error")
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Clear Tests
    
    @Test("클리어 후 빈 상태")
    func clearMakesEmpty() async throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_crash_logs_clear_\(UUID().uuidString).json")
        let preserver = CrashLogPreserver(preserveCount: 10, storageURL: tempURL)
        
        await preserver.record(createTestMessage(level: .error, message: "Error"))
        try await preserver.persist()
        
        // When
        try await preserver.clear()
        
        // Then
        let count = await preserver.count
        #expect(count == 0)
        
        let recovered = try await preserver.recover()
        #expect(recovered == nil)
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Recover Without Persist Tests
    
    @Test("저장 없이 복구 시 nil")
    func recoverWithoutPersistReturnsNil() async throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent_\(UUID().uuidString).json")
        let preserver = CrashLogPreserver(preserveCount: 10, storageURL: tempURL)
        
        // When
        let recovered = try await preserver.recover()
        
        // Then
        #expect(recovered == nil)
    }
    
    // MARK: - Helper
    
    private func createTestMessage(
        level: LogLevel,
        message: String
    ) -> LogMessage {
        LogMessage(
            level: level,
            message: message,
            category: "Test",
            file: #file,
            function: #function,
            line: #line
        )
    }
}

