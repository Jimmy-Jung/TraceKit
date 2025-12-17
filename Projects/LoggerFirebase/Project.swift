// Project.swift
// LoggerFirebase
//
// Created by jimmy on 2025-12-15.

import ProjectDescription

let project = Project(
    name: "LoggerFirebase",
    organizationName: "com.logger",
    targets: [
        .target(
            name: "LoggerFirebase",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.logger.LoggerFirebase",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Logger", path: "../Logger"),
                .package(product: "FirebaseCrashlytics"),
                .package(product: "FirebaseAnalytics")
            ]
        )
    ]
)

