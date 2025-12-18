// MainTabView.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .generator

    enum Tab: String, CaseIterable {
        case generator
        case settings
        case viewer
        case performance
        case sanitizer
        case crash

        var title: String {
            switch self {
            case .generator: return "Generator"
            case .settings: return "Settings"
            case .viewer: return "Viewer"
            case .performance: return "Performance"
            case .sanitizer: return "Sanitizer"
            case .crash: return "Crash"
            }
        }

        var icon: String {
            switch self {
            case .generator: return "play.circle"
            case .settings: return "gearshape"
            case .viewer: return "list.bullet.rectangle"
            case .performance: return "timer"
            case .sanitizer: return "lock.shield"
            case .crash: return "exclamationmark.triangle"
            }
        }

        var selectedIcon: String {
            switch self {
            case .generator: return "play.circle.fill"
            case .settings: return "gearshape.fill"
            case .viewer: return "list.bullet.rectangle.fill"
            case .performance: return "timer"
            case .sanitizer: return "lock.shield.fill"
            case .crash: return "exclamationmark.triangle.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LogGeneratorView()
                .tag(Tab.generator)
                .tabItem {
                    Label(Tab.generator.title, systemImage: selectedTab == .generator ? Tab.generator.selectedIcon : Tab.generator.icon)
                }

            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label(Tab.settings.title, systemImage: selectedTab == .settings ? Tab.settings.selectedIcon : Tab.settings.icon)
                }

            LogViewerView()
                .tag(Tab.viewer)
                .tabItem {
                    Label(Tab.viewer.title, systemImage: selectedTab == .viewer ? Tab.viewer.selectedIcon : Tab.viewer.icon)
                }

            PerformanceView()
                .tag(Tab.performance)
                .tabItem {
                    Label(Tab.performance.title, systemImage: selectedTab == .performance ? Tab.performance.selectedIcon : Tab.performance.icon)
                }

            SanitizerDemoView()
                .tag(Tab.sanitizer)
                .tabItem {
                    Label(Tab.sanitizer.title, systemImage: selectedTab == .sanitizer ? Tab.sanitizer.selectedIcon : Tab.sanitizer.icon)
                }

            CrashDemoView()
                .tag(Tab.crash)
                .tabItem {
                    Label(Tab.crash.title, systemImage: selectedTab == .crash ? Tab.crash.selectedIcon : Tab.crash.icon)
                }
        }
        .tint(Theme.Colors.accent)
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
