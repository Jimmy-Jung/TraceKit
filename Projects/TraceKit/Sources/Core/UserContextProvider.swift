// UserContextProvider.swift
// TraceKit
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 사용자 컨텍스트 제공 프로토콜
/// - Note: 현재 사용자/세션 정보를 제공
public protocol UserContextProvider: Sendable {
    /// 현재 사용자 컨텍스트 반환
    func currentContext() async -> UserContext
}
