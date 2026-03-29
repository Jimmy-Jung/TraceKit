// RemoteConfigControlView.swift
// TraceKitDemo
//
// Created by jimmy on 2026-01-22.

import SwiftUI
import TraceKit

struct RemoteConfigControlView: View {
    @StateObject private var viewModel = RemoteConfigControlViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                consoleGuideSection
                fetchControlSection
                configurationSection
                scenarioSection
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Colors.background)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.accent)
                
                Text("Remote Config Control")
                    .font(Theme.Typography.largeTitle)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            Text("Firebase Console에서 설정 변경 → 앱에서 즉시 반영")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Console Guide
    
    private var consoleGuideSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Theme.Colors.accent)
                
                Text("Firebase Console 사용 가이드")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                RemoteConfigGuideStep(number: 1, text: "Firebase Console 열기")
                RemoteConfigGuideStep(number: 2, text: "Remote Config > Parameters 클릭")
                RemoteConfigGuideStep(number: 3, text: "아래에서 현재 값 확인")
                RemoteConfigGuideStep(number: 4, text: "Console에서 값 수정")
                RemoteConfigGuideStep(number: 5, text: "\"Publish changes\" 클릭")
                RemoteConfigGuideStep(number: 6, text: "앱에서 \"새로고침\" 버튼 클릭")
                RemoteConfigGuideStep(number: 7, text: "변경된 값 즉시 반영 확인! 🎉")
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        }
    }
    
    // MARK: - Fetch Control
    
    private var fetchControlSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button {
                Task {
                    await viewModel.fetchAndActivate()
                }
            } label: {
                HStack {
                    if viewModel.isFetching {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text("지금 새로고침")
            }
            .font(Theme.Typography.body)
            .foregroundColor(Theme.Colors.background)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.accent)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isFetching || !viewModel.isRemoteConfigAvailable)
            
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
                
                Text("마지막 갱신: \(viewModel.lastFetchTimeDisplay)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            if viewModel.lastFetchStatus == .success {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.info)
                    
                    Text("설정을 성공적으로 가져왔습니다")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.info)
                }
            } else if viewModel.lastFetchStatus == .failed {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.error)
                    
                    Text(viewModel.errorMessage ?? "설정을 가져오는데 실패했습니다")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.error)
                }
            } else if !viewModel.isRemoteConfigAvailable {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text(viewModel.errorMessage ?? "Firebase 설정이 없어 Remote Config가 비활성화되었습니다")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Configuration
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "gearshape.2")
                    .foregroundColor(Theme.Colors.accent)
                
                Text("현재 Remote Config 설정")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            if let config = viewModel.currentConfig {
                VStack(spacing: Theme.Spacing.xs) {
                    ConfigRow(
                        key: "tracekit_min_level",
                        value: config.minLevel.name,
                        icon: "text.alignleft",
                        color: config.minLevel.color
                    )
                    
                    ConfigRow(
                        key: "tracekit_sampling_rate",
                        value: config.samplingRatePercentage,
                        icon: "percent",
                        color: Theme.Colors.info
                    )
                    
                    ConfigRow(
                        key: "tracekit_enable_crashlytics",
                        value: config.isCrashlyticsEnabled ? "활성화" : "비활성화",
                        icon: config.isCrashlyticsEnabled ? "checkmark.circle.fill" : "xmark.circle",
                        color: config.isCrashlyticsEnabled ? Theme.Colors.info : Theme.Colors.textTertiary
                    )
                    
                    ConfigRow(
                        key: "tracekit_enable_analytics",
                        value: config.isAnalyticsEnabled ? "활성화" : "비활성화",
                        icon: config.isAnalyticsEnabled ? "checkmark.circle.fill" : "xmark.circle",
                        color: config.isAnalyticsEnabled ? Theme.Colors.info : Theme.Colors.textTertiary
                    )
                    
                    ConfigRow(
                        key: "tracekit_enable_performance",
                        value: config.isPerformanceEnabled ? "활성화" : "비활성화",
                        icon: config.isPerformanceEnabled ? "checkmark.circle.fill" : "xmark.circle",
                        color: config.isPerformanceEnabled ? Theme.Colors.info : Theme.Colors.textTertiary
                    )
                    
                    ConfigRow(
                        key: "tracekit_enable_sanitizer",
                        value: config.isSanitizerEnabled ? "활성화" : "비활성화",
                        icon: config.isSanitizerEnabled ? "checkmark.circle.fill" : "xmark.circle",
                        color: config.isSanitizerEnabled ? Theme.Colors.info : Theme.Colors.textTertiary
                    )
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.xl)
            }
        }
    }
    
    // MARK: - Scenarios
    
    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "theatermasks")
                    .foregroundColor(Theme.Colors.accent)
                
                Text("실무 시나리오 테스트")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            VStack(spacing: Theme.Spacing.sm) {
                ScenarioCard(
                    title: "긴급 디버깅 모드",
                    description: "프로덕션에서 특정 사용자에게 버그 발생 시",
                    steps: [
                        "Console에서 tracekit_min_level을 'verbose'로 변경",
                        "앱에서 새로고침",
                        "상세 로그 수집 시작",
                        "버그 원인 파악 후 다시 'info'로 복원"
                    ],
                    icon: "ladybug",
                    color: Theme.Colors.warning
                ) {
                    viewModel.demonstrateEmergencyDebug()
                }
                
                ScenarioCard(
                    title: "A/B 테스트",
                    description: "샘플링 비율에 따른 성능/비용 영향 분석",
                    steps: [
                        "조건 A (50%): sampling_rate = 1.0",
                        "조건 B (50%): sampling_rate = 0.5",
                        "성능 데이터 수집 및 비교",
                        "최적값 결정 후 전체 배포"
                    ],
                    icon: "square.split.2x1",
                    color: Theme.Colors.info
                ) {
                    viewModel.demonstrateABTest()
                }
                
                ScenarioCard(
                    title: "단계적 기능 배포",
                    description: "새 기능을 점진적으로 사용자에게 배포",
                    steps: [
                        "초기: enable_performance = false (10%)",
                        "1주 후: true (50%)",
                        "2주 후: true (100%)",
                        "영향 모니터링 후 전체 활성화"
                    ],
                    icon: "chart.line.uptrend.xyaxis",
                    color: Theme.Colors.accent
                ) {
                    // 로그만 출력
                    TraceKit.info(
                        "단계적 배포 시나리오",
                        category: "RemoteConfig",
                        metadata: [
                            "scenario": AnyCodable("gradual_rollout"),
                            "action": AnyCodable("Firebase Console에서 조건부 배포 설정")
                        ]
                    )
                }
            }
        }
    }
}

// MARK: - Remote Config Guide Step

struct RemoteConfigGuideStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("\(number)")
                .font(Theme.Typography.mono)
                .foregroundColor(Theme.Colors.background)
                .frame(width: 24, height: 24)
                .background(Theme.Colors.accent)
                .clipShape(Circle())
            
            Text(text)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Config Row

struct ConfigRow: View {
    let key: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(key)
                    .font(Theme.Typography.mono)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Text(value)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

// MARK: - Scenario Card

struct ScenarioCard: View {
    let title: String
    let description: String
    let steps: [String]
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text(description)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                .padding(Theme.Spacing.md)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Text("\(index + 1).")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.textTertiary)
                            
                            Text(step)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.md)
            }
        }
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    RemoteConfigControlView()
}
