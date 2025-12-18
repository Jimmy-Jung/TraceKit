// LogViewerView.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import SwiftUI
import TraceKit

struct LogViewerView: View {
    @StateObject private var viewModel = LogViewerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            filterSection
            logListSection
        }
        .background(Theme.Colors.background)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Log Viewer")
                        .font(Theme.Typography.largeTitle)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("\(viewModel.filteredCount) / \(viewModel.logCount) logs")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                }

                Spacer()

                HStack(spacing: Theme.Spacing.sm) {
                    Button {
                        viewModel.isAutoScrollEnabled.toggle()
                    } label: {
                        Image(systemName: viewModel.isAutoScrollEnabled ? "arrow.down.circle.fill" : "arrow.down.circle")
                            .font(.title3)
                            .foregroundColor(viewModel.isAutoScrollEnabled ? Theme.Colors.accent : Theme.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.clearLogs()
                    } label: {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(Theme.Colors.error)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Filter

    private var filterSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.textTertiary)

                TextField("Search logs...", text: $viewModel.searchText)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.textPrimary)

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
            .padding(.horizontal, Theme.Spacing.md)

            // Level Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    FilterChip(title: "All", isSelected: viewModel.filterLevel == nil) {
                        viewModel.filterLevel = nil
                    }

                    ForEach(TraceLevel.allCases, id: \.self) { level in
                        FilterChip(
                            title: level.emoji + " " + level.name,
                            isSelected: viewModel.filterLevel == level,
                            color: level.color
                        ) {
                            viewModel.filterLevel = level
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Log List

    private var logListSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.filteredLogs) { log in
                        LogRowView(message: log)
                            .id(log.id)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.lg)
            }
            .onChange(of: viewModel.logs.count) { _ in
                if viewModel.isAutoScrollEnabled, let lastLog = viewModel.filteredLogs.last {
                    withAnimation {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = Theme.Colors.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(isSelected ? Theme.Colors.background : Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(isSelected ? color : Theme.Colors.surfaceElevated)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LogViewerView()
}
