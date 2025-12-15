// Project.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import ProjectDescription

let project = Project(
    name: "Logger",
    organizationName: "com.logger",
    targets: [
        .target(
            name: "Logger",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.logger.Logger",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: []
        ),
        .target(
            name: "LoggerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.logger.LoggerTests",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: "Logger")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "Logger",
            shared: true,
            buildAction: .buildAction(targets: ["Logger", "LoggerTests"]),
            testAction: .targets(
                [.testableTarget(target: "LoggerTests")],
                options: .options(coverage: true, codeCoverageTargets: ["Logger"])
            ),
            runAction: .runAction(configuration: .debug),
            archiveAction: .archiveAction(configuration: .release)
        )
    ]
)

