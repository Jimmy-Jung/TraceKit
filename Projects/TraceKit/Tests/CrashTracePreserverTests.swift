// CrashTracePreserverTests.swift
// TraceKitTests
//
// Created by jimmy on 2025-12-15.

import Foundation
import Testing
@testable import TraceKit

// MARK: - CrashTracePreserver Tests

struct CrashTracePreserverTests {
    // MARK: - Creation Tests

    @Test("기본 보존 개수 설정")
    func defaultPreserveCount() async {
        // Given & When
        let preserver = CrashTracePreserver(preserveCount: 50)

        // Then
        #expect(preserver.preserveCount == 50)
    }

    // MARK: - Record Tests

    @Test("로그 기록")
    func recordLog() async {
        // Given
        let preserver = CrashTracePreserver(preserveCount: 10)
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
        let preserver = CrashTracePreserver(preserveCount: 10)

        // When
        for i in 0 ..< 5 {
            await preserver.record(createTestMessage(level: .info, message: "Log \(i)"))
        }

        // Then
        let count = await preserver.count
        #expect(count == 5)
    }

    @Test("보존 개수 초과 시 오래된 로그 삭제")
    func overwritesOldLogsWhenFull() async {
        // Given
        let preserver = CrashTracePreserver(preserveCount: 3)

        // When
        for i in 0 ..< 5 {
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
        let preserver = CrashTracePreserver(preserveCount: 10)
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
        let preserver = CrashTracePreserver(preserveCount: 10, storageURL: tempURL)

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
        let preserver = CrashTracePreserver(preserveCount: 10, storageURL: tempURL)

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
        let preserver = CrashTracePreserver(preserveCount: 10, storageURL: tempURL)

        // When
        let recovered = try await preserver.recover()

        // Then
        #expect(recovered == nil)
    }

    // MARK: - mmap 기반 동기 저장 테스트

    @Test("persistSync 호출 시 크래시 마커 기록")
    func persistSyncWritesCrashMarker() async throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_crash_mmap_\(UUID().uuidString).json")
        let preserver = CrashTracePreserver(preserveCount: 10, storageURL: tempURL)

        await preserver.record(createTestMessage(level: .fatal, message: "Critical crash"))

        // When
        preserver.persistSync()

        // 약간의 지연 (mmap msync 시간 확보)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        // Then
        let hasCrash = preserver.hasCrashData()
        #expect(hasCrash)

        // Cleanup
        await preserver.cleanup()
        try? FileManager.default.removeItem(at: tempURL)
        let mmapURL = tempURL.deletingPathExtension().appendingPathExtension("mmap")
        try? FileManager.default.removeItem(at: mmapURL)
    }

    @Test("hasCrashData는 크래시 마커 확인")
    func hasCrashDataDetectsMarker() async throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_crash_detect_\(UUID().uuidString).json")
        let preserver = CrashTracePreserver(preserveCount: 10, storageURL: tempURL)

        // When (크래시 전)
        let beforeCrash = preserver.hasCrashData()

        // When (크래시 후)
        preserver.persistSync()
        try? await Task.sleep(nanoseconds: 100_000_000)
        let afterCrash = preserver.hasCrashData()

        // Then
        #expect(!beforeCrash)
        #expect(afterCrash)

        // Cleanup
        await preserver.cleanup()
        try? FileManager.default.removeItem(at: tempURL)
        let mmapURL = tempURL.deletingPathExtension().appendingPathExtension("mmap")
        try? FileManager.default.removeItem(at: mmapURL)
    }

    @Test("clearMmapData는 크래시 마커 제거")
    func clearMmapDataRemovesMarker() async throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_crash_clear_\(UUID().uuidString).json")
        let preserver = CrashTracePreserver(preserveCount: 10, storageURL: tempURL)

        preserver.persistSync()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        preserver.clearMmapData()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let hasCrash = preserver.hasCrashData()
        #expect(!hasCrash)

        // Cleanup
        await preserver.cleanup()
        try? FileManager.default.removeItem(at: tempURL)
        let mmapURL = tempURL.deletingPathExtension().appendingPathExtension("mmap")
        try? FileManager.default.removeItem(at: mmapURL)
    }

    @Test("recover는 mmap 크래시 데이터 확인")
    func recoverChecksMmapCrashData() async throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_crash_recover_\(UUID().uuidString).json")
        let preserver = CrashTracePreserver(preserveCount: 10, storageURL: tempURL)

        await preserver.record(createTestMessage(level: .fatal, message: "Fatal error"))
        try await preserver.persist()

        // 크래시 시뮬레이션
        preserver.persistSync()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        let recovered = try await preserver.recover()

        // Then
        #expect(recovered != nil)
        #expect(recovered?.count == 1)

        // mmap이 클리어되었는지 확인
        let hasCrash = preserver.hasCrashData()
        #expect(!hasCrash)

        // Cleanup
        await preserver.cleanup()
        try? FileManager.default.removeItem(at: tempURL)
        let mmapURL = tempURL.deletingPathExtension().appendingPathExtension("mmap")
        try? FileManager.default.removeItem(at: mmapURL)
    }

    @Test("cleanup은 mmap 리소스 정리")
    func cleanupReleasesMmapResources() async throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_cleanup_\(UUID().uuidString).json")
        let preserver = CrashTracePreserver(preserveCount: 10, storageURL: tempURL)

        preserver.persistSync()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        await preserver.cleanup()

        // Then
        // cleanup 후에는 hasCrashData가 false (mmap이 해제됨)
        let hasCrash = preserver.hasCrashData()
        #expect(!hasCrash)

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
        let mmapURL = tempURL.deletingPathExtension().appendingPathExtension("mmap")
        try? FileManager.default.removeItem(at: mmapURL)
    }

    @Test("여러 번 persistSync 호출 안전성")
    func multiplePersistSyncCallsAreSafe() async throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_multiple_sync_\(UUID().uuidString).json")
        let preserver = CrashTracePreserver(preserveCount: 10, storageURL: tempURL)

        // When
        for _ in 0 ..< 10 {
            preserver.persistSync()
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let hasCrash = preserver.hasCrashData()
        #expect(hasCrash)

        // Cleanup
        await preserver.cleanup()
        try? FileManager.default.removeItem(at: tempURL)
        let mmapURL = tempURL.deletingPathExtension().appendingPathExtension("mmap")
        try? FileManager.default.removeItem(at: mmapURL)
    }

    @Test("동시 persistSync 호출 스레드 안전성")
    func concurrentPersistSyncCallsAreThreadSafe() async throws {
        // Given
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_concurrent_sync_\(UUID().uuidString).json")
        let preserver = CrashTracePreserver(preserveCount: 10, storageURL: tempURL)

        // When - 동시에 여러 스레드에서 호출
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 5 {
                group.addTask {
                    preserver.persistSync()
                }
            }
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let hasCrash = preserver.hasCrashData()
        #expect(hasCrash)

        // Cleanup
        await preserver.cleanup()
        try? FileManager.default.removeItem(at: tempURL)
        let mmapURL = tempURL.deletingPathExtension().appendingPathExtension("mmap")
        try? FileManager.default.removeItem(at: mmapURL)
    }

    // MARK: - Helper

    private func createTestMessage(
        level: TraceLevel,
        message: String
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
