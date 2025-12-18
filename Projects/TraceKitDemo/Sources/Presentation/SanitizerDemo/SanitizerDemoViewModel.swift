// SanitizerDemoViewModel.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import Foundation
import TraceKit

@MainActor
final class SanitizerDemoViewModel: ObservableObject {
    struct SampleData: Identifiable {
        let id = UUID()
        let name: String
        let original: String
        let pattern: SensitiveDataPattern
    }

    @Published var customInput: String = ""
    @Published var sanitizedOutput: String = ""

    let sampleDataList: [SampleData] = [
        SampleData(
            name: "이메일",
            original: "사용자 이메일: john.doe@example.com",
            pattern: .email
        ),
        SampleData(
            name: "신용카드",
            original: "카드번호: 1234-5678-9012-3456",
            pattern: .creditCard
        ),
        SampleData(
            name: "전화번호",
            original: "연락처: 010-1234-5678",
            pattern: .phoneNumberKR
        ),
        SampleData(
            name: "IP 주소",
            original: "접속 IP: 192.168.1.100",
            pattern: .ipAddress
        ),
        SampleData(
            name: "JWT 토큰",
            original: "Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U",
            pattern: .jwtToken
        ),
        SampleData(
            name: "비밀번호",
            original: "password=mySecretPass123!",
            pattern: .password
        ),
    ]

    let patterns: [SensitiveDataPattern] = SensitiveDataPattern.defaults + [.ipAddress, .phoneNumberIntl]

    private let sanitizer = DefaultTraceSanitizer()

    func sanitize(_ input: String) -> String {
        let message = TraceMessage(
            level: .info,
            message: input,
            category: "Demo",
            file: #file,
            function: #function,
            line: #line
        )
        return sanitizer.sanitize(message).message
    }

    func updateOutput() {
        guard !customInput.isEmpty else {
            sanitizedOutput = ""
            return
        }
        sanitizedOutput = sanitize(customInput)
    }

    func logOriginal(_ data: SampleData) {
        TraceKit.info(
            "[원본] \(data.original)",
            category: "Sanitizer"
        )
    }

    func logSanitized(_ data: SampleData) {
        let sanitized = sanitize(data.original)
        TraceKit.info(
            "[마스킹] \(sanitized)",
            category: "Sanitizer"
        )
    }
}
