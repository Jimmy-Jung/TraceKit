// Project.swift
// TraceKitSentry
//
// Created by jimmy on 2025-12-15.

import ProjectDescription

let project = Project(
    name: "TraceKitSentry",
    organizationName: "com.tracekit",
    targets: [
        .target(
            name: "TraceKitSentry",
            destinations: [.iPhone, .iPad, .mac, .appleWatch, .appleTv, .appleVision],
            product: .framework,
            bundleId: "com.tracekit.TraceKitSentry",
            deploymentTargets: .multiplatform(
                iOS: "15.0",
                macOS: "12.0",
                watchOS: "8.0",
                tvOS: "15.0",
                visionOS: "1.0"
            ),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "TraceKit", path: "../TraceKit"),
                .package(product: "Sentry"),
            ]
        ),
    ]
)
