// Project.swift
// LoggerSentry
//
// Created by jimmy on 2025-12-15.

import ProjectDescription

let project = Project(
    name: "LoggerSentry",
    organizationName: "com.logger",
    packages: [
        .remote(
            url: "https://github.com/getsentry/sentry-cocoa",
            requirement: .upToNextMajor(from: "8.0.0")
        )
    ],
    targets: [
        .target(
            name: "LoggerSentry",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.logger.LoggerSentry",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Logger", path: "../Logger"),
                .package(product: "Sentry")
            ]
        )
    ]
)

