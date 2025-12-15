// UserContextTests.swift
// LoggerTests
//
// Created by jimmy on 2025-12-15.

import Testing
import Foundation
@testable import Logger

// MARK: - UserContext Tests

struct UserContextTests {
    
    // MARK: - Creation Tests
    
    @Test("UserContext 기본 생성")
    func createBasicUserContext() {
        // Given & When
        let context = UserContext(
            userId: "user123",
            sessionId: "session456",
            deviceId: "device789",
            appVersion: "1.0.0",
            buildNumber: "100",
            osVersion: "17.0",
            deviceModel: "iPhone15,2",
            environment: .debug
        )
        
        // Then
        #expect(context.userId == "user123")
        #expect(context.sessionId == "session456")
        #expect(context.deviceId == "device789")
        #expect(context.appVersion == "1.0.0")
        #expect(context.environment == .debug)
    }
    
    @Test("UserContext userId/sessionId 옵셔널")
    func userIdAndSessionIdAreOptional() {
        // Given & When
        let context = UserContext(
            deviceId: "device",
            appVersion: "1.0",
            buildNumber: "1",
            osVersion: "17.0",
            deviceModel: "iPhone",
            environment: .production
        )
        
        // Then
        #expect(context.userId == nil)
        #expect(context.sessionId == nil)
    }
    
    // MARK: - toDictionary Tests
    
    @Test("toDictionary가 필수 필드 포함")
    func toDictionaryContainsRequiredFields() {
        // Given
        let context = UserContext(
            deviceId: "device123",
            appVersion: "2.0.0",
            buildNumber: "200",
            osVersion: "17.0",
            deviceModel: "iPhone14,3",
            environment: .release
        )
        
        // When
        let dict = context.toDictionary()
        
        // Then
        #expect(dict["deviceId"] as? String == "device123")
        #expect(dict["appVersion"] as? String == "2.0.0")
        #expect(dict["osVersion"] as? String == "17.0")
        #expect(dict["environment"] as? String == "release")
    }
    
    @Test("toDictionary가 userId 포함")
    func toDictionaryContainsUserId() {
        // Given
        let context = UserContext(
            userId: "user999",
            deviceId: "device",
            appVersion: "1.0",
            buildNumber: "1",
            osVersion: "17.0",
            deviceModel: "iPhone",
            environment: .debug
        )
        
        // When
        let dict = context.toDictionary()
        
        // Then
        #expect(dict["userId"] as? String == "user999")
    }
    
    @Test("toDictionary가 customAttributes 포함")
    func toDictionaryContainsCustomAttributes() {
        // Given
        var context = UserContext(
            deviceId: "device",
            appVersion: "1.0",
            buildNumber: "1",
            osVersion: "17.0",
            deviceModel: "iPhone",
            environment: .debug,
            customAttributes: ["plan": AnyCodable("premium")]
        )
        
        // When
        let dict = context.toDictionary()
        
        // Then
        #expect(dict["plan"] != nil)
    }
    
    // MARK: - Environment Tests
    
    @Test("Environment rawValue 검증", arguments: [
        (Environment.debug, "debug"),
        (Environment.release, "release"),
        (Environment.production, "production")
    ])
    func environmentRawValue(env: Environment, expected: String) {
        #expect(env.rawValue == expected)
    }
    
    // MARK: - Codable Tests
    
    @Test("UserContext Codable 인코딩/디코딩")
    func codableEncodingDecoding() throws {
        // Given
        let original = UserContext(
            userId: "user",
            sessionId: "session",
            deviceId: "device",
            appVersion: "1.0",
            buildNumber: "1",
            osVersion: "17.0",
            deviceModel: "iPhone",
            environment: .production
        )
        
        // When
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(UserContext.self, from: data)
        
        // Then
        #expect(decoded.userId == original.userId)
        #expect(decoded.deviceId == original.deviceId)
        #expect(decoded.environment == original.environment)
    }
    
    // MARK: - Mutability Tests
    
    @Test("userId 변경 가능")
    func userIdIsMutable() {
        // Given
        var context = UserContext(
            deviceId: "device",
            appVersion: "1.0",
            buildNumber: "1",
            osVersion: "17.0",
            deviceModel: "iPhone",
            environment: .debug
        )
        
        // When
        context.userId = "newUser"
        
        // Then
        #expect(context.userId == "newUser")
    }
    
    @Test("customAttributes 추가 가능")
    func customAttributesAreMutable() {
        // Given
        var context = UserContext(
            deviceId: "device",
            appVersion: "1.0",
            buildNumber: "1",
            osVersion: "17.0",
            deviceModel: "iPhone",
            environment: .debug
        )
        
        // When
        context.customAttributes["newKey"] = AnyCodable("newValue")
        
        // Then
        #expect(context.customAttributes["newKey"] != nil)
    }
}

