// LogGeneratorView.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import SwiftUI
import TraceKit

struct LogGeneratorView: View {
    @StateObject private var viewModel = LogGeneratorViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                categorySection
                messageSection
                logButtonsSection
                quickActionsSection
                networkLoggingSection
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
            Text("Log Generator")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.textPrimary)

            Text("각 로그 레벨을 테스트하세요")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Category")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
                .textCase(.uppercase)

            CategoryPicker(
                selected: $viewModel.selectedCategory,
                categories: viewModel.categories
            )
            .padding(.horizontal, -Theme.Spacing.md)
        }
    }

    // MARK: - Message Input

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Message (Optional)")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
                .textCase(.uppercase)

            TextField("커스텀 메시지 입력...", text: $viewModel.customMessage)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )

            Toggle(isOn: $viewModel.includeMetadata) {
                Text("메타데이터 포함")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .tint(Theme.Colors.accent)
        }
    }

    // MARK: - Log Buttons

    private var logButtonsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Log Levels")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
                .textCase(.uppercase)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: Theme.Spacing.sm) {
                ForEach(TraceLevel.allCases, id: \.self) { level in
                    TraceLevelButton(
                        level: level,
                        isHighlighted: viewModel.lastLoggedLevel == level
                    ) {
                        viewModel.log(level: level)
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Quick Actions")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
                .textCase(.uppercase)

            Button {
                viewModel.logAllLevels()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("모든 레벨 순차 출력")
                }
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.background)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Network Logging Section

    private var networkLoggingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Network Logging (JSON)")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
                .textCase(.uppercase)

            VStack(spacing: Theme.Spacing.sm) {
                NetworkLogButton(
                    title: "Request 로깅",
                    subtitle: "GET /users/123",
                    icon: "arrow.up.circle",
                    color: Theme.Colors.debug
                ) {
                    viewModel.logNetworkRequest()
                }

                NetworkLogButton(
                    title: "Response 로깅",
                    subtitle: "200 OK + JSON Body",
                    icon: "arrow.down.circle",
                    color: Theme.Colors.info
                ) {
                    viewModel.logNetworkResponse()
                }

                NetworkLogButton(
                    title: "Error 로깅",
                    subtitle: "401 Unauthorized",
                    icon: "xmark.circle",
                    color: Theme.Colors.error
                ) {
                    viewModel.logNetworkError()
                }

                NetworkLogButton(
                    title: "전체 사이클",
                    subtitle: "Request → Response → Complete",
                    icon: "arrow.triangle.2.circlepath",
                    color: Theme.Colors.accent
                ) {
                    viewModel.logNetworkFullCycle()
                }
            }
        }
    }
}

// MARK: - Network Log Button

struct NetworkLogButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Log Level Button

struct TraceLevelButton: View {
    let level: TraceLevel
    let isHighlighted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Text(level.emoji)
                Text(level.name)
                    .font(Theme.Typography.mono)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(isHighlighted ? level.color.opacity(0.3) : Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(level.color.opacity(isHighlighted ? 1 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
    }
}

#Preview {
    LogGeneratorView()
}
