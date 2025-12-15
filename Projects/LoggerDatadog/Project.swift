// Project.swift
// LoggerDatadog
//
// Created by jimmy on 2025-12-15.

import ProjectDescription

let project = Project(
    name: "LoggerDatadog",
    organizationName: "com.logger",
    packages: [
        .remote(
            url: "https://github.com/DataDog/dd-sdk-ios",
            requirement: .upToNextMajor(from: "2.0.0")
        )
    ],
    targets: [
        .target(
            name: "LoggerDatadog",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.logger.LoggerDatadog",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Logger", path: "../Logger"),
                .package(product: "DatadogLogs")
            ]
        )
    ]
)

