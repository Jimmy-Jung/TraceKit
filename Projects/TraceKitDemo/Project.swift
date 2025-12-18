// Project.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import ProjectDescription

let project = Project(
    name: "TraceKitDemo",
    organizationName: "com.tracekit",
    targets: [
        .target(
            name: "TraceKitDemo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.tracekit.TraceKitDemo",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [
                    "UIColorName": "LaunchBackground",
                ],
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                ],
            ]),
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
                .project(target: "TraceKit", path: "../TraceKit"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "TraceKitDemo",
            shared: true,
            buildAction: .buildAction(targets: ["TraceKitDemo"]),
            runAction: .runAction(
                configuration: .debug,
                arguments: .arguments(
                    launchArguments: [
                        .launchArgument(name: "-logLevel DEBUG", isEnabled: false),
                        .launchArgument(name: "-logFilter Network,Auth", isEnabled: false),
                        .launchArgument(name: "-sampleRate 1.0", isEnabled: false),
                        .launchArgument(name: "-bufferSize 100", isEnabled: false),
                        .launchArgument(name: "-flushInterval 5.0", isEnabled: false),
                        .launchArgument(name: "-disableConsole", isEnabled: false),
                        .launchArgument(name: "-disableOSLog", isEnabled: false),
                        .launchArgument(name: "-disableFile", isEnabled: false),
                        .launchArgument(name: "-disableMasking", isEnabled: false),
                        .launchArgument(name: "-enableMasking", isEnabled: false),
                    ]
                )
            ),
            archiveAction: .archiveAction(configuration: .release)
        ),
    ]
)
