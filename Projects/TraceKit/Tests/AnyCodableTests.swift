// AnyCodableTests.swift
// TraceKitTests
//
// Created by jimmy on 2025-12-15.

import Foundation
import Testing
@testable import TraceKit

// MARK: - AnyCodable Tests

struct AnyCodableTests {
    // MARK: - Literal Initialization Tests

    @Test("정수 리터럴 초기화")
    func initWithIntegerLiteral() {
        let value: AnyCodable = 42
        #expect(value.value as? Int == 42)
    }

    @Test("실수 리터럴 초기화")
    func initWithFloatLiteral() {
        let value: AnyCodable = 3.14
        #expect(value.value as? Double == 3.14)
    }

    @Test("문자열 리터럴 초기화")
    func initWithStringLiteral() {
        let value: AnyCodable = "hello"
        #expect(value.value as? String == "hello")
    }

    @Test("불리언 리터럴 초기화")
    func initWithBooleanLiteral() {
        let trueValue: AnyCodable = true
        let falseValue: AnyCodable = false

        #expect(trueValue.value as? Bool == true)
        #expect(falseValue.value as? Bool == false)
    }

    @Test("nil 리터럴 초기화")
    func initWithNilLiteral() {
        let value: AnyCodable = nil
        #expect(value.value is NSNull)
    }

    // MARK: - Encoding Tests

    @Test("정수 인코딩")
    func encodeInteger() throws {
        // Given
        let value = AnyCodable(42)
        let encoder = JSONEncoder()

        // When
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)

        // Then
        #expect(json == "42")
    }

    @Test("문자열 인코딩")
    func encodeString() throws {
        // Given
        let value = AnyCodable("test")
        let encoder = JSONEncoder()

        // When
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)

        // Then
        #expect(json == "\"test\"")
    }

    @Test("배열 인코딩")
    func encodeArray() throws {
        // Given
        let value = AnyCodable([1, 2, 3])
        let encoder = JSONEncoder()

        // When
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)

        // Then
        #expect(json == "[1,2,3]")
    }

    @Test("딕셔너리 인코딩")
    func encodeDictionary() throws {
        // Given
        let value = AnyCodable(["key": "value"])
        let encoder = JSONEncoder()

        // When
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)

        // Then
        #expect(json?.contains("key") == true)
        #expect(json?.contains("value") == true)
    }

    // MARK: - Decoding Tests

    @Test("정수 디코딩")
    func decodeInteger() throws {
        // Given
        let json = "42".data(using: .utf8)!
        let decoder = JSONDecoder()

        // When
        let value = try decoder.decode(AnyCodable.self, from: json)

        // Then
        #expect(value.value as? Int == 42)
    }

    @Test("문자열 디코딩")
    func decodeString() throws {
        // Given
        let json = "\"test\"".data(using: .utf8)!
        let decoder = JSONDecoder()

        // When
        let value = try decoder.decode(AnyCodable.self, from: json)

        // Then
        #expect(value.value as? String == "test")
    }

    @Test("불리언 디코딩")
    func decodeBoolean() throws {
        // Given
        let json = "true".data(using: .utf8)!
        let decoder = JSONDecoder()

        // When
        let value = try decoder.decode(AnyCodable.self, from: json)

        // Then
        #expect(value.value as? Bool == true)
    }

    @Test("null 디코딩")
    func decodeNull() throws {
        // Given
        let json = "null".data(using: .utf8)!
        let decoder = JSONDecoder()

        // When
        let value = try decoder.decode(AnyCodable.self, from: json)

        // Then
        #expect(value.value is NSNull)
    }

    // MARK: - Equality Tests

    @Test("동일 정수 값 비교")
    func equalIntegers() {
        let a = AnyCodable(42)
        let b = AnyCodable(42)
        #expect(a == b)
    }

    @Test("다른 정수 값 비교")
    func differentIntegers() {
        let a = AnyCodable(42)
        let b = AnyCodable(43)
        #expect(a != b)
    }

    @Test("동일 문자열 값 비교")
    func equalStrings() {
        let a = AnyCodable("hello")
        let b = AnyCodable("hello")
        #expect(a == b)
    }

    // MARK: - Description Tests

    @Test("description이 값을 표현")
    func descriptionRepresentsValue() {
        let intValue = AnyCodable(42)
        let stringValue = AnyCodable("test")

        #expect(intValue.description == "42")
        #expect(stringValue.description == "test")
    }
}
