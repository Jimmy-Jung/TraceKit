// CrashDemoViewModel.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-16.

import Combine
import Foundation
import TraceKit

@MainActor
final class CrashDemoViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isRecording: Bool = false
    @Published var recordedLogsCount: Int = 0
    @Published var hasPreviousCrash: Bool = false
    @Published var recoveredLogs: [TraceMessage] = []
    @Published var crashMarkerDetected: Bool = false
    @Published var statusMessage: String = ""

    // MARK: - Private Properties

    private let preserver: CrashTracePreserver
    private var logTimer: Timer?

    // MARK: - Initialization

    init() {
        preserver = CrashTracePreserver(preserveCount: 50)

        Task {
            await checkPreviousCrash()
            await updateStatus()
        }
    }

    // MARK: - Public Methods

    /// 이전 크래시 확인
    func checkPreviousCrash() async {
        do {
            // mmap 크래시 마커 확인
            crashMarkerDetected = preserver.hasCrashData()

            // 저장된 로그 복구
            if let logs = try await preserver.recover() {
                recoveredLogs = logs
                hasPreviousCrash = true
                statusMessage = "✅ 이전 크래시 감지: \(logs.count)개 로그 복구됨"

                // 로그 내용 출력
                await TraceKit.async.warning("이전 크래시 복구: \(logs.count)개 로그", category: "Crash")
            } else {
                hasPreviousCrash = false
                statusMessage = "ℹ️ 이전 크래시 없음"
            }
        } catch {
            statusMessage = "⚠️ 복구 실패: \(error.localizedDescription)"
            await TraceKit.async.error("크래시 로그 복구 실패: \(error)", category: "Crash")
        }
    }

    /// 로그 기록 시작
    func startRecording() async {
        isRecording = true
        statusMessage = "📝 로그 기록 중..."

        // 1초마다 로그 생성
        logTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                let messages = [
                    "사용자가 버튼을 클릭했습니다",
                    "네트워크 요청 시작",
                    "데이터 로딩 완료",
                    "화면 전환 발생",
                    "백그라운드 작업 시작",
                ]

                let message = messages.randomElement() ?? "로그"
                let level: TraceLevel = [.debug, .info, .warning].randomElement() ?? .info

                let logMessage = TraceMessage(
                    level: level,
                    message: message,
                    category: "CrashDemo",
                    file: #file,
                    function: #function,
                    line: #line
                )

                await self.preserver.record(logMessage)
                self.recordedLogsCount = await self.preserver.count

                await TraceKit.async.log(level: level, message, category: "CrashDemo")
            }
        }
    }

    /// 로그 기록 중지
    func stopRecording() {
        logTimer?.invalidate()
        logTimer = nil
        isRecording = false
        statusMessage = "⏸️ 기록 중지됨"
    }

    /// 일반 저장 (persist)
    func saveToFile() async {
        do {
            try await preserver.persist()
            statusMessage = "✅ \(recordedLogsCount)개 로그 파일로 저장 완료"
            await TraceKit.async.info("로그 파일 저장 완료", category: "Crash")
        } catch {
            statusMessage = "⚠️ 저장 실패: \(error.localizedDescription)"
            await TraceKit.async.error("로그 저장 실패: \(error)", category: "Crash")
        }
    }

    /// 크래시 시뮬레이션 (persistSync만 호출)
    func simulateCrash() async {
        // 크래시 직전 로그 추가
        let crashLog = TraceMessage(
            level: .fatal,
            message: "💥 CRASH SIMULATED - App is about to crash",
            category: "CrashDemo",
            file: #file,
            function: #function,
            line: #line
        )
        await preserver.record(crashLog)

        // 일반 저장
        try? await preserver.persist()

        // 크래시 마커 기록 (Signal Handler 시뮬레이션)
        preserver.persistSync()

        statusMessage = "💥 크래시 시뮬레이션 완료 (mmap 마커만)"

        await TraceKit.async.fatal("크래시 시뮬레이션 실행", category: "Crash")

        // 상태 업데이트
        try? await Task.sleep(nanoseconds: 100_000_000)
        await updateStatus()
    }

    /// 실제 크래시 발생 (SIGABRT)
    func triggerRealCrash() async {
        // 크래시 직전 로그 추가
        let crashLog = TraceMessage(
            level: .fatal,
            message: "💥💥💥 REAL CRASH - App will terminate NOW",
            category: "CrashDemo",
            file: #file,
            function: #function,
            line: #line
        )
        await preserver.record(crashLog)

        // 일반 저장
        try? await preserver.persist()

        // 크래시 마커 기록
        preserver.persistSync()

        await TraceKit.async.fatal("실제 크래시 발생!", category: "Crash")

        // 약간의 지연 (로그 저장 시간 확보)
        try? await Task.sleep(nanoseconds: 200_000_000)

        // 실제 크래시 발생!
        fatalError("💥 Intentional crash for testing CrashTracePreserver")
    }

    /// NSException 크래시
    func triggerNSExceptionCrash() async {
        // 크래시 직전 로그
        let crashLog = TraceMessage(
            level: .fatal,
            message: "💥 NSException CRASH",
            category: "CrashDemo",
            file: #file,
            function: #function,
            line: #line
        )
        await preserver.record(crashLog)
        try? await preserver.persist()
        preserver.persistSync()

        await TraceKit.async.fatal("NSException 크래시 발생!", category: "Crash")
        try? await Task.sleep(nanoseconds: 200_000_000)

        // NSException 발생
        NSException(
            name: .internalInconsistencyException,
            reason: "Intentional crash for testing",
            userInfo: nil
        ).raise()
    }

    /// 강제 언래핑 크래시
    func triggerForceUnwrapCrash() async {
        // 크래시 직전 로그
        let crashLog = TraceMessage(
            level: .fatal,
            message: "💥 Force Unwrap CRASH",
            category: "CrashDemo",
            file: #file,
            function: #function,
            line: #line
        )
        await preserver.record(crashLog)
        try? await preserver.persist()
        preserver.persistSync()

        await TraceKit.async.fatal("Force Unwrap 크래시 발생!", category: "Crash")
        try? await Task.sleep(nanoseconds: 200_000_000)

        // 강제 언래핑 크래시
        let nilValue: String? = nil
        _ = nilValue!
    }

    /// 배열 인덱스 오버플로우 크래시
    func triggerArrayCrash() async {
        // 크래시 직전 로그
        let crashLog = TraceMessage(
            level: .fatal,
            message: "💥 Array Index CRASH",
            category: "CrashDemo",
            file: #file,
            function: #function,
            line: #line
        )
        await preserver.record(crashLog)
        try? await preserver.persist()
        preserver.persistSync()

        await TraceKit.async.fatal("Array Index 크래시 발생!", category: "Crash")
        try? await Task.sleep(nanoseconds: 200_000_000)

        // 배열 인덱스 오버플로우
        let array: [Int] = []
        _ = array[0]
    }

    /// 로그 클리어
    func clearLogs() async {
        do {
            try await preserver.clear()
            recordedLogsCount = 0
            recoveredLogs = []
            hasPreviousCrash = false
            statusMessage = "🗑️ 로그 클리어 완료"

            await TraceKit.async.info("로그 클리어됨", category: "Crash")
        } catch {
            statusMessage = "⚠️ 클리어 실패: \(error.localizedDescription)"
        }
    }

    /// mmap 데이터 클리어
    func clearMmapData() {
        preserver.clearMmapData()
        crashMarkerDetected = false
        statusMessage = "🗑️ mmap 크래시 마커 제거됨"
    }

    /// 현재 상태 업데이트
    func updateStatus() async {
        recordedLogsCount = await preserver.count
        crashMarkerDetected = preserver.hasCrashData()

        if crashMarkerDetected {
            statusMessage = "⚠️ 크래시 마커 감지됨!"
        } else if recordedLogsCount > 0 {
            statusMessage = "📝 \(recordedLogsCount)개 로그 기록됨"
        } else {
            statusMessage = "ℹ️ 준비 완료"
        }
    }

    /// 현재 로그 목록 가져오기
    func getCurrentLogs() async -> [TraceMessage] {
        await preserver.currentLogs()
    }

    /// 리소스 정리
    func cleanup() async {
        stopRecording()
        await preserver.cleanup()
    }
}
