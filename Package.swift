// swift-tools-version: 6.0
// Package.swift
// TraceKit
//
// Created by jimmy on 2024-12-18.

import PackageDescription

let package = Package(
    name: "TraceKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        // 코어 TraceKit 프레임워크
        .library(
            name: "TraceKit",
            targets: ["TraceKit"]
        ),
        // Datadog 연동 모듈
        .library(
            name: "TraceKitDatadog",
            targets: ["TraceKitDatadog"]
        ),
        // Firebase 연동 모듈
        .library(
            name: "TraceKitFirebase",
            targets: ["TraceKitFirebase"]
        ),
        // Sentry 연동 모듈
        .library(
            name: "TraceKitSentry",
            targets: ["TraceKitSentry"]
        )
    ],
    dependencies: [
        // Firebase SDK
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            from: "11.0.0"
        ),
        // Sentry SDK
        .package(
            url: "https://github.com/getsentry/sentry-cocoa",
            from: "8.0.0"
        ),
        // Datadog SDK
        .package(
            url: "https://github.com/DataDog/dd-sdk-ios",
            from: "2.0.0"
        )
    ],
    targets: [
        // MARK: - Core TraceKit Target
        .target(
            name: "TraceKit",
            dependencies: [],
            path: "Projects/TraceKit/Sources",
            exclude: [
                "Crash/CRASH_PRESERVER_GUIDE.md"
            ]
        ),
        
        // MARK: - TraceKit Tests
        .testTarget(
            name: "TraceKitTests",
            dependencies: ["TraceKit"],
            path: "Projects/TraceKit/Tests"
        ),
        
        // MARK: - Datadog Integration
        .target(
            name: "TraceKitDatadog",
            dependencies: [
                "TraceKit",
                .product(name: "DatadogLogs", package: "dd-sdk-ios")
            ],
            path: "Projects/TraceKitDatadog/Sources"
        ),
        
        // MARK: - Firebase Integration
        .target(
            name: "TraceKitFirebase",
            dependencies: [
                "TraceKit",
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")
            ],
            path: "Projects/TraceKitFirebase/Sources"
        ),
        
        // MARK: - Sentry Integration
        .target(
            name: "TraceKitSentry",
            dependencies: [
                "TraceKit",
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path: "Projects/TraceKitSentry/Sources"
        )
    ]
)
