// CrashDemoView.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-16.

import SwiftUI
import TraceKit

struct CrashDemoView: View {
    @StateObject private var viewModel = CrashDemoViewModel()
    @State private var showRecoveredLogs = false
    @State private var showCurrentLogs = false
    @State private var currentLogs: [TraceMessage] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statusSection
                    recordingSection
                    crashSection
                    managementSection
                    recoveredLogsSection
                }
                .padding()
            }
            .navigationTitle("Crash Demo")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.checkPreviousCrash()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.Colors.warning)
                    .font(.title2)

                Text("CrashTracePreserver 테스트")
                    .font(.headline)
            }

            Text("크래시 로그 보존 및 복구 기능을 테스트합니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(12)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Theme.Colors.info)

                Text("상태")
                    .font(.headline)

                Spacer()

                Button {
                    Task {
                        await viewModel.updateStatus()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Theme.Colors.accent)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                StatusRow(title: "현재 상태", value: viewModel.statusMessage)
                StatusRow(title: "기록된 로그", value: "\(viewModel.recordedLogsCount)개")
                StatusRow(
                    title: "크래시 마커",
                    value: viewModel.crashMarkerDetected ? "🔴 감지됨" : "⚪️ 없음",
                    valueColor: viewModel.crashMarkerDetected ? .red : .secondary
                )
                StatusRow(
                    title: "이전 크래시",
                    value: viewModel.hasPreviousCrash ? "✅ 있음 (\(viewModel.recoveredLogs.count)개)" : "❌ 없음",
                    valueColor: viewModel.hasPreviousCrash ? .orange : .secondary
                )
            }
        }
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(12)
    }

    // MARK: - Recording Section

    private var recordingSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "record.circle.fill")
                    .foregroundStyle(viewModel.isRecording ? .red : .secondary)

                Text("로그 기록")
                    .font(.headline)

                Spacer()
            }

            Divider()

            HStack(spacing: 12) {
                Button {
                    Task {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            await viewModel.startRecording()
                        }
                    }
                } label: {
                    Label(
                        viewModel.isRecording ? "중지" : "시작",
                        systemImage: viewModel.isRecording ? "stop.circle.fill" : "play.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isRecording ? Color.red : Theme.Colors.accent)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }

                Button {
                    Task {
                        await viewModel.saveToFile()
                    }
                } label: {
                    Label("저장", systemImage: "square.and.arrow.down.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.info)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.recordedLogsCount == 0)
            }

            Button {
                Task {
                    currentLogs = await viewModel.getCurrentLogs()
                    showCurrentLogs = true
                }
            } label: {
                Label("현재 로그 보기", systemImage: "list.bullet")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.surface)
                    .foregroundStyle(Theme.Colors.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.Colors.accent, lineWidth: 1)
                    )
                    .cornerRadius(10)
            }
            .disabled(viewModel.recordedLogsCount == 0)
        }
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(12)
        .sheet(isPresented: $showCurrentLogs) {
            LogListSheet(title: "현재 로그", logs: currentLogs)
        }
    }

    // MARK: - Crash Section

    private var crashSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)

                Text("크래시 테스트")
                    .font(.headline)

                Spacer()
            }

            Divider()

            VStack(spacing: 8) {
                // 시뮬레이션 (mmap만)
                Text("1. 시뮬레이션: persistSync()만 호출")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    Task {
                        await viewModel.simulateCrash()
                    }
                } label: {
                    Label("💥 크래시 시뮬레이션 (mmap만)", systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.recordedLogsCount == 0)

                Divider()
                    .padding(.vertical, 4)

                // 실제 크래시
                Text("2. 실제 크래시: 앱이 종료됩니다!")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    Button {
                        Task {
                            await viewModel.triggerRealCrash()
                        }
                    } label: {
                        Label("💥💥 fatalError", systemImage: "xmark.octagon.fill")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                    }
                    .disabled(viewModel.recordedLogsCount == 0)

                    HStack(spacing: 8) {
                        Button {
                            Task {
                                await viewModel.triggerForceUnwrapCrash()
                            }
                        } label: {
                            Text("nil!")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.8))
                                .foregroundStyle(.white)
                                .cornerRadius(6)
                        }
                        .disabled(viewModel.recordedLogsCount == 0)

                        Button {
                            Task {
                                await viewModel.triggerArrayCrash()
                            }
                        } label: {
                            Text("array[0]")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.8))
                                .foregroundStyle(.white)
                                .cornerRadius(6)
                        }
                        .disabled(viewModel.recordedLogsCount == 0)

                        Button {
                            Task {
                                await viewModel.triggerNSExceptionCrash()
                            }
                        } label: {
                            Text("NSException")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.8))
                                .foregroundStyle(.white)
                                .cornerRadius(6)
                        }
                        .disabled(viewModel.recordedLogsCount == 0)
                    }
                }
            }
        }
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(12)
    }

    // MARK: - Management Section

    private var managementSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "trash.circle.fill")
                    .foregroundStyle(.orange)

                Text("관리")
                    .font(.headline)

                Spacer()
            }

            Divider()

            VStack(spacing: 12) {
                Button {
                    viewModel.clearMmapData()
                } label: {
                    Label("mmap 크래시 마커 제거", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.warning)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.crashMarkerDetected)

                Button {
                    Task {
                        await viewModel.clearLogs()
                    }
                } label: {
                    Label("모든 로그 삭제", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Theme.Colors.surface)
        .cornerRadius(12)
    }

    // MARK: - Recovered Logs Section

    private var recoveredLogsSection: some View {
        Group {
            if viewModel.hasPreviousCrash {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.orange)

                        Text("복구된 로그")
                            .font(.headline)

                        Spacer()

                        Text("\(viewModel.recoveredLogs.count)개")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Button {
                        showRecoveredLogs = true
                    } label: {
                        Label("복구된 로그 보기", systemImage: "doc.text.magnifyingglass")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.Colors.accent)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Theme.Colors.surface)
                .cornerRadius(12)
                .sheet(isPresented: $showRecoveredLogs) {
                    LogListSheet(title: "복구된 로그", logs: viewModel.recoveredLogs)
                }
            }
        }
    }
}

// MARK: - Status Row

struct StatusRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - Log List Sheet

struct LogListSheet: View {
    let title: String
    let logs: [TraceMessage]
    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(logs) { log in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        TraceLevelBadge(level: log.level)

                        Text(log.timestamp, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }

                    Text(log.message)
                        .font(.body)

                    Text("\(log.fileName):\(log.line)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CrashDemoView()
        .preferredColorScheme(.dark)
}
