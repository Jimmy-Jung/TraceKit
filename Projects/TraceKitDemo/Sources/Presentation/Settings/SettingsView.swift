// SettingsView.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import SwiftUI
import TraceKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                logFilesSection
                minLevelSection
                sanitizerSection
                samplingSection
                bufferSection
                actionSection
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .overlay(appliedFeedback)
        .sheet(isPresented: $viewModel.showingFileContent) {
            logFileContentSheet
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            if let url = viewModel.fileToShare {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Settings")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.textPrimary)

            Text("TraceKit 설정을 실시간으로 변경하세요")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Log Files Section

    private var logFilesSection: some View {
        SettingsCard(title: "Log Files") {
            VStack(spacing: Theme.Spacing.md) {
                // 요약 정보
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("\(viewModel.logFiles.count) files")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text(viewModel.totalLogSize)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.textTertiary)
                    }

                    Spacer()

                    Button {
                        viewModel.loadLogFiles()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Theme.Colors.accent)
                    }
                }

                if viewModel.logFiles.isEmpty {
                    Text("저장된 로그 파일이 없습니다")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                } else {
                    Divider()
                        .background(Theme.Colors.divider)

                    // 파일 목록
                    ForEach(viewModel.logFiles) { file in
                        logFileRow(file)

                        if file.id != viewModel.logFiles.last?.id {
                            Divider()
                                .background(Theme.Colors.divider)
                        }
                    }

                    Divider()
                        .background(Theme.Colors.divider)

                    // 액션 버튼들
                    HStack(spacing: Theme.Spacing.md) {
                        Button {
                            viewModel.shareAllLogs()
                        } label: {
                            Label("Export All", systemImage: "square.and.arrow.up")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.accent)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            viewModel.deleteAllLogs()
                        } label: {
                            Label("Delete All", systemImage: "trash")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.error)
                        }
                    }
                }
            }
        }
    }

    private func logFileRow(_ file: LogFileInfo) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(file.name)
                    .font(Theme.Typography.mono)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: Theme.Spacing.sm) {
                    Text(file.formattedSize)
                    Text("•")
                    Text(file.formattedDate)
                }
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
            }

            Spacer()

            HStack(spacing: Theme.Spacing.sm) {
                // 보기 버튼
                Button {
                    viewModel.viewFileContent(file)
                } label: {
                    Image(systemName: "doc.text")
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                // 공유 버튼
                Button {
                    viewModel.shareFile(file)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Theme.Colors.accent)
                }

                // 삭제 버튼
                Button(role: .destructive) {
                    viewModel.deleteFile(file)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(Theme.Colors.error)
                }
            }
            .font(Theme.Typography.body)
        }
    }

    // MARK: - Log File Content Sheet

    private var logFileContentSheet: some View {
        NavigationView {
            ScrollView {
                Text(viewModel.selectedFileContent ?? "")
                    .font(Theme.Typography.mono)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Log Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.showingFileContent = false
                    }
                }
            }
        }
    }

    // MARK: - Min Level

    private var minLevelSection: some View {
        SettingsCard(title: "Minimum Log Level") {
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Text(viewModel.minLevel.emoji)
                    Text(viewModel.minLevel.name)
                        .font(Theme.Typography.mono)
                        .foregroundColor(viewModel.minLevel.color)
                    Spacer()
                }

                Picker("Level", selection: $viewModel.minLevelIndex) {
                    ForEach(TraceLevel.allCases, id: \.rawValue) { level in
                        Text(level.name).tag(level.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Sanitizer

    private var sanitizerSection: some View {
        SettingsCard(title: "Sensitive Data Masking") {
            Toggle(isOn: $viewModel.isSanitizingEnabled) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("민감정보 마스킹")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text("이메일, 카드번호 등 자동 마스킹")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
            .tint(Theme.Colors.accent)
        }
    }

    // MARK: - Sampling

    private var samplingSection: some View {
        SettingsCard(title: "Sampling Rate") {
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Text("\(Int(viewModel.sampleRate * 100))%")
                        .font(Theme.Typography.mono)
                        .foregroundColor(Theme.Colors.accent)
                    Spacer()
                    Text("로그 수집 비율")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                }

                Slider(value: $viewModel.sampleRate, in: 0 ... 1, step: 0.1)
                    .tint(Theme.Colors.accent)
            }
        }
    }

    // MARK: - Buffer

    private var bufferSection: some View {
        SettingsCard(title: "Buffer Settings") {
            VStack(spacing: Theme.Spacing.md) {
                HStack {
                    Text("Buffer Size")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(viewModel.bufferSize)")
                        .font(Theme.Typography.mono)
                        .foregroundColor(Theme.Colors.accent)
                }

                Stepper("", value: $viewModel.bufferSize, in: 10 ... 500, step: 10)
                    .labelsHidden()

                Divider()
                    .background(Theme.Colors.divider)

                HStack {
                    Text("Flush Interval")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(viewModel.flushInterval, specifier: "%.1f")s")
                        .font(Theme.Typography.mono)
                        .foregroundColor(Theme.Colors.accent)
                }

                Slider(value: $viewModel.flushInterval, in: 1 ... 30, step: 1)
                    .tint(Theme.Colors.accent)
            }
        }
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button {
                viewModel.applySettings()
            } label: {
                Text("Apply Settings")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            }
            .buttonStyle(.plain)

            Button {
                viewModel.resetToDefaults()
            } label: {
                Text("Reset to Defaults")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Feedback

    @ViewBuilder
    private var appliedFeedback: some View {
        if viewModel.showAppliedFeedback {
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Settings Applied")
                }
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.background)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Colors.accent)
                .clipShape(Capsule())
                .padding(.bottom, Theme.Spacing.xl)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: viewModel.showAppliedFeedback)
        }
    }
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
                .textCase(.uppercase)

            content()
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        }
    }
}

#Preview {
    SettingsView()
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
