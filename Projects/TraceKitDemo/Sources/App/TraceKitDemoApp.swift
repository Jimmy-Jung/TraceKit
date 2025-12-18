// TraceKitDemoApp.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import SwiftUI
import TraceKit

@main
struct TraceKitDemoApp: App {
    init() {
        Task {
            await TraceKitSetup.configure()
            await TraceKit.async.info("TraceKitDemo 앱이 시작되었습니다", category: "App")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }
}
