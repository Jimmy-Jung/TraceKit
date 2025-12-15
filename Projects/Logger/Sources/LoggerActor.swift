// LoggerActor.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 로거 전용 Global Actor
/// - Note: 모든 로깅 작업이 이 Actor에서 격리되어 실행
@globalActor
public actor LoggerActor {
    public static let shared = LoggerActor()
    
    private init() {}
}

