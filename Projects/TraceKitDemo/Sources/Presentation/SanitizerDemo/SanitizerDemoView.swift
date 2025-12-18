// SanitizerDemoView.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import SwiftUI
import TraceKit

struct SanitizerDemoView: View {
    @StateObject private var viewModel = SanitizerDemoViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                customInputSection
                sampleDataSection
                patternListSection
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Sanitizer")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.textPrimary)

            Text("민감정보 자동 마스킹을 확인하세요")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Custom Input

    private var customInputSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Custom Test")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
                .textCase(.uppercase)

            VStack(spacing: Theme.Spacing.sm) {
                TextField("민감정보가 포함된 텍스트 입력...", text: $viewModel.customInput)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    .onChange(of: viewModel.customInput) { _ in
                        viewModel.updateOutput()
                    }

                if !viewModel.sanitizedOutput.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Result")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.textTertiary)

                        Text(viewModel.sanitizedOutput)
                            .font(Theme.Typography.mono)
                            .foregroundColor(Theme.Colors.accent)
                            .padding(Theme.Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.Colors.accentMuted)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        }
    }

    // MARK: - Sample Data

    private var sampleDataSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Sample Data")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
                .textCase(.uppercase)

            ForEach(viewModel.sampleDataList) { sample in
                SampleDataRow(
                    sample: sample,
                    sanitized: viewModel.sanitize(sample.original),
                    onLogOriginal: { viewModel.logOriginal(sample) },
                    onLogSanitized: { viewModel.logSanitized(sample) }
                )
            }
        }
    }

    // MARK: - Pattern List

    private var patternListSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Supported Patterns")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
                .textCase(.uppercase)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: Theme.Spacing.sm) {
                ForEach(viewModel.patterns, id: \.name) { pattern in
                    PatternChip(pattern: pattern)
                }
            }
        }
    }
}

// MARK: - Sample Data Row

struct SampleDataRow: View {
    let sample: SanitizerDemoViewModel.SampleData
    let sanitized: String
    let onLogOriginal: () -> Void
    let onLogSanitized: () -> Void

    @State private var showSanitized: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(sample.name)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Text(sample.pattern.replacement)
                    .font(Theme.Typography.monoSmall)
                    .foregroundColor(Theme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Original")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textTertiary)

                Text(sample.original)
                    .font(Theme.Typography.mono)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }

            if showSanitized {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Sanitized")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.accent)

                    Text(sanitized)
                        .font(Theme.Typography.mono)
                        .foregroundColor(Theme.Colors.accent)
                        .lineLimit(2)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack(spacing: Theme.Spacing.sm) {
                Button {
                    withAnimation { showSanitized.toggle() }
                } label: {
                    Text(showSanitized ? "Hide" : "Show Result")
                        .font(Theme.Typography.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.Colors.accent)

                Spacer()

                Button {
                    onLogOriginal()
                } label: {
                    Image(systemName: "doc.text")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.Colors.textTertiary)

                Button {
                    onLogSanitized()
                } label: {
                    Image(systemName: "lock.shield")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.Colors.accent)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

// MARK: - Pattern Chip

struct PatternChip: View {
    let pattern: SensitiveDataPattern

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(pattern.replacement)
                .font(Theme.Typography.mono)
                .foregroundColor(Theme.Colors.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(pattern.name)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

#Preview {
    SanitizerDemoView()
}
