// TraceStream.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import Combine
import Foundation
import TraceKit

@MainActor
final class TraceStream: ObservableObject {
    static let shared = TraceStream()

    @Published private(set) var logs: [TraceMessage] = []

    private let maxLogs = 500

    private init() {}

    func append(_ message: TraceMessage) {
        logs.append(message)

        if logs.count > maxLogs {
            logs.removeFirst(logs.count - maxLogs)
        }
    }

    func append(contentsOf messages: [TraceMessage]) {
        for message in messages {
            append(message)
        }
    }

    func clear() {
        logs.removeAll()
    }
}
