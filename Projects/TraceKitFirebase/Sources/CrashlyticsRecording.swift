// CrashlyticsRecording.swift
// TraceKitFirebase
//
// Created by jimmy on 2026-04-21.

import Foundation

@preconcurrency import FirebaseCrashlytics

/// Crashlytics SDK 호출을 테스트 가능하게 분리한 추상화.
public protocol CrashlyticsRecording: Sendable {
    func log(_ message: String)
    func record(error: Error)
    func setUserID(_ userID: String?)
    func setCustomValue(_ value: Any?, forKey key: String)
}

/// Firebase Crashlytics SDK 기본 recorder.
public final class FirebaseCrashlyticsRecorder: CrashlyticsRecording, @unchecked Sendable {
    private let crashlytics: Crashlytics

    public init(crashlytics: Crashlytics = Crashlytics.crashlytics()) {
        self.crashlytics = crashlytics
    }

    public func log(_ message: String) {
        crashlytics.log(message)
    }

    public func record(error: Error) {
        crashlytics.record(error: error)
    }

    public func setUserID(_ userID: String?) {
        crashlytics.setUserID(userID)
    }

    public func setCustomValue(_ value: Any?, forKey key: String) {
        crashlytics.setCustomValue(value, forKey: key)
    }
}
