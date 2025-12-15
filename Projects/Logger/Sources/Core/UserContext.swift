// UserContext.swift
// Logger
//
// Created by jimmy on 2025-12-15.

import Foundation

/// 앱 실행 환경
public enum Environment: String, Codable, Sendable {
    case debug
    case release
    case production
}

/// 사용자 컨텍스트 정보
/// - Note: 모든 로그에 자동으로 첨부되는 컨텍스트 정보
public struct UserContext: Codable, Sendable, Equatable {
    /// 로그인한 사용자 ID
    public var userId: String?
    
    /// 현재 세션 ID
    public var sessionId: String?
    
    /// 디바이스 고유 ID
    public let deviceId: String
    
    /// 앱 버전
    public let appVersion: String
    
    /// 앱 빌드 번호
    public let buildNumber: String
    
    /// OS 버전
    public let osVersion: String
    
    /// 디바이스 모델
    public let deviceModel: String
    
    /// 실행 환경
    public let environment: Environment
    
    /// 커스텀 속성
    public var customAttributes: [String: AnyCodable]
    
    public init(
        userId: String? = nil,
        sessionId: String? = nil,
        deviceId: String,
        appVersion: String,
        buildNumber: String,
        osVersion: String,
        deviceModel: String,
        environment: Environment,
        customAttributes: [String: AnyCodable] = [:]
    ) {
        self.userId = userId
        self.sessionId = sessionId
        self.deviceId = deviceId
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.environment = environment
        self.customAttributes = customAttributes
    }
    
    /// Dictionary로 변환
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "deviceId": deviceId,
            "appVersion": appVersion,
            "buildNumber": buildNumber,
            "osVersion": osVersion,
            "deviceModel": deviceModel,
            "environment": environment.rawValue
        ]
        
        if let userId = userId {
            dict["userId"] = userId
        }
        
        if let sessionId = sessionId {
            dict["sessionId"] = sessionId
        }
        
        for (key, value) in customAttributes {
            dict[key] = value.value
        }
        
        return dict
    }
}

