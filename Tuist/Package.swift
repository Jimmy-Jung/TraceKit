// swift-tools-version: 6.0
// Package.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        // 특정 패키지 프로덕트의 타입을 커스터마이징
        // 기본값은 .staticFramework
        // productTypes: ["Alamofire": .framework]
        productTypes: [:]
    )
#endif

let package = Package(
    name: "Logger",
    dependencies: [
        // Firebase SDK
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
        // Sentry SDK
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0"),
        // Datadog SDK
        .package(url: "https://github.com/DataDog/dd-sdk-ios", from: "2.0.0")
    ]
)

