// InMemoryTraceDestination.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import Foundation
import TraceKit

actor InMemoryTraceDestination: TraceDestination {
    let identifier = "in-memory"
    var minLevel: TraceLevel = .verbose
    var isEnabled: Bool = true

    private let stream: TraceStream

    init(stream: TraceStream) {
        self.stream = stream
    }

    func log(_ message: TraceMessage) async {
        guard shouldLog(message) else { return }
        await MainActor.run {
            stream.append(message)
        }
    }

    func flush(_ messages: [TraceMessage]) async {
        let filtered = messages.filter { shouldLog($0) }
        guard !filtered.isEmpty else { return }
        await MainActor.run {
            stream.append(contentsOf: filtered)
        }
    }
}
