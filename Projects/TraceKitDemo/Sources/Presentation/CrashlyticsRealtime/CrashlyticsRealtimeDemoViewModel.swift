// CrashlyticsRealtimeDemoViewModel.swift
// TraceKitDemo
//
// Created by jimmy on 2026-01-22.

import Foundation
import TraceKit
import UIKit
import FirebaseCrashlytics

/// Breadcrumb 이벤트 기록
struct BreadcrumbEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: TraceLevel
    let category: String
    let message: String
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

/// 시나리오 실행 상태
enum ScenarioState {
    case idle
    case running
    case waitingForBackground
    case completed
    
    var displayText: String {
        switch self {
        case .idle: return "대기 중"
        case .running: return "실행 중..."
        case .waitingForBackground: return "백그라운드 전환 대기 중"
        case .completed: return "완료"
        }
    }
}

/// Crashlytics Realtime Demo ViewModel
///
/// Firebase Crashlytics Breadcrumb 추적을 시연합니다.
/// 크래시 발생 전 사용자 행동 패턴을 기록하고
/// Console에서 30초~1분 후 확인할 수 있습니다.
@MainActor
final class CrashlyticsRealtimeDemoViewModel: ObservableObject {
    @Published var breadcrumbs: [BreadcrumbEvent] = []
    @Published var scenarioState: ScenarioState = .idle
    @Published var backgroundTimer: Int = 0
    @Published var isTimerRunning: Bool = false
    
    private var timerTask: Task<Void, Never>?
    
    /// 쇼핑 시나리오 실행
    func startShoppingScenario() async {
        guard scenarioState == .idle else { return }
        
        scenarioState = .running
        breadcrumbs.removeAll()
        
        // 1. 상품 추가
        await addBreadcrumb(
            level: .info,
            category: "Cart",
            message: "상품을 장바구니에 추가했습니다"
        )
        TraceKit.info("상품을 장바구니에 추가했습니다", category: "Cart")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 2. 장바구니 확인
        await addBreadcrumb(
            level: .info,
            category: "Cart",
            message: "장바구니 화면을 열었습니다"
        )
        TraceKit.info("장바구니 화면을 열었습니다", category: "Cart")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 3. 결제 시작
        await addBreadcrumb(
            level: .info,
            category: "Cart",
            message: "결제 프로세스를 시작했습니다"
        )
        TraceKit.info("결제 프로세스를 시작했습니다", category: "Cart")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 4. 카드 검증
        await addBreadcrumb(
            level: .warning,
            category: "Payment",
            message: "카드 정보를 검증하고 있습니다"
        )
        TraceKit.warning("카드 정보를 검증하고 있습니다", category: "Payment")
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // 5. 결제 실패
        await addBreadcrumb(
            level: .error,
            category: "Payment",
            message: "결제 실패: 카드 한도 초과"
        )
        TraceKit.error(
            "결제 실패: 카드 한도 초과",
            category: "Payment",
            ("errorCode", "CARD_LIMIT_EXCEEDED"),
            ("amount", 59800),
            ("cardType", "credit")
        )
        
        // Crashlytics 데이터 즉시 전송 (디버그 모드)
        #if DEBUG
        Crashlytics.crashlytics().sendUnsentReports()
        print("🔥 [Crashlytics] Breadcrumb 즉시 전송 완료")
        #endif
        
        scenarioState = .waitingForBackground
    }
    
    /// 로그인 실패 시나리오 실행
    func startLoginFailureScenario() async {
        guard scenarioState == .idle else { return }
        
        scenarioState = .running
        breadcrumbs.removeAll()
        
        // 1. 앱 시작
        await addBreadcrumb(
            level: .info,
            category: "App",
            message: "앱이 시작되었습니다"
        )
        TraceKit.info("앱이 시작되었습니다", category: "App")
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // 2. 로그인 화면 진입
        await addBreadcrumb(
            level: .info,
            category: "Auth",
            message: "로그인 화면에 진입했습니다"
        )
        TraceKit.info("로그인 화면에 진입했습니다", category: "Auth")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 3. 이메일 입력
        await addBreadcrumb(
            level: .debug,
            category: "Auth",
            message: "이메일 입력: user@example.com"
        )
        TraceKit.debug("이메일 입력: user@example.com", category: "Auth")
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // 4. 비밀번호 입력
        await addBreadcrumb(
            level: .debug,
            category: "Auth",
            message: "비밀번호 입력 완료"
        )
        TraceKit.debug("비밀번호 입력 완료", category: "Auth")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 5. 로그인 시도
        await addBreadcrumb(
            level: .info,
            category: "Auth",
            message: "로그인 요청 전송 중"
        )
        TraceKit.info("로그인 요청 전송 중", category: "Auth")
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // 6. 인증 실패
        await addBreadcrumb(
            level: .error,
            category: "Auth",
            message: "로그인 실패: 잘못된 비밀번호"
        )
        TraceKit.error(
            "로그인 실패: 잘못된 비밀번호",
            category: "Auth",
            ("errorCode", "INVALID_PASSWORD"),
            ("attemptCount", 3),
            ("email", "user@example.com")
        )
        
        // Crashlytics 데이터 즉시 전송 (디버그 모드)
        #if DEBUG
        Crashlytics.crashlytics().sendUnsentReports()
        print("🔥 [Crashlytics] Breadcrumb 즉시 전송 완료")
        #endif
        
        scenarioState = .waitingForBackground
    }
    
    /// 데이터 로딩 크래시 시나리오
    func startDataCrashScenario() async {
        guard scenarioState == .idle else { return }
        
        scenarioState = .running
        breadcrumbs.removeAll()
        
        // 1. 데이터 로딩 시작
        await addBreadcrumb(
            level: .info,
            category: "Database",
            message: "사용자 데이터 로딩 시작"
        )
        TraceKit.info("사용자 데이터 로딩 시작", category: "Database")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 2. 캐시 확인
        await addBreadcrumb(
            level: .debug,
            category: "Database",
            message: "로컬 캐시 확인 중"
        )
        TraceKit.debug("로컬 캐시 확인 중", category: "Database")
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // 3. 네트워크 요청
        await addBreadcrumb(
            level: .info,
            category: "Network",
            message: "서버에서 데이터 가져오는 중"
        )
        TraceKit.info("서버에서 데이터 가져오는 중", category: "Network")
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // 4. 파싱 시작
        await addBreadcrumb(
            level: .debug,
            category: "Database",
            message: "응답 데이터 파싱 중"
        )
        TraceKit.debug("응답 데이터 파싱 중", category: "Database")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 5. Fatal 에러 발생
        await addBreadcrumb(
            level: .fatal,
            category: "Database",
            message: "치명적 오류: 데이터 손상 감지"
        )
        TraceKit.fatal(
            "치명적 오류: 데이터 손상 감지",
            category: "Database",
            ("errorCode", "DATA_CORRUPTION"),
            ("recordCount", 0),
            ("expectedCount", 150)
        )
        
        // Crashlytics 데이터 즉시 전송 (디버그 모드)
        #if DEBUG
        Crashlytics.crashlytics().sendUnsentReports()
        print("🔥 [Crashlytics] Breadcrumb 즉시 전송 완료")
        #endif
        
        scenarioState = .waitingForBackground
    }
    
    /// 백그라운드로 이동 (30초 타이머)
    func moveToBackground() {
        isTimerRunning = true
        backgroundTimer = 30
        
        timerTask?.cancel()
        timerTask = Task {
            for i in stride(from: 30, to: 0, by: -1) {
                if Task.isCancelled { break }
                
                backgroundTimer = i
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            if !Task.isCancelled {
                backgroundTimer = 0
                isTimerRunning = false
                scenarioState = .completed
            }
        }
        
        // 실제 백그라운드 전환 유도
        if UIApplication.shared.connectedScenes.first is UIWindowScene {
            // 사용자에게 백그라운드 전환 안내
            Task { @MainActor in
                // UI에서 안내 표시
            }
        }
    }
    
    /// 시나리오 초기화
    func resetScenario() {
        timerTask?.cancel()
        scenarioState = .idle
        breadcrumbs.removeAll()
        backgroundTimer = 0
        isTimerRunning = false
    }
    
    /// Breadcrumb 추가
    private func addBreadcrumb(
        level: TraceLevel,
        category: String,
        message: String
    ) async {
        let event = BreadcrumbEvent(
            timestamp: Date(),
            level: level,
            category: category,
            message: message
        )
        
        breadcrumbs.append(event)
    }
}
