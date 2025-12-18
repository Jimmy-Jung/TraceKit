// LogViewerViewModel.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import Combine
import Foundation
import TraceKit

@MainActor
final class LogViewerViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var filterLevel: TraceLevel?
    @Published var filterCategory: String?
    @Published var isAutoScrollEnabled: Bool = true

    private let logStream = TraceStream.shared
    private var cancellables = Set<AnyCancellable>()

    var logs: [TraceMessage] {
        logStream.logs
    }

    var filteredLogs: [TraceMessage] {
        logs.filter { message in
            // Level filter
            if let filterLevel = filterLevel, message.level != filterLevel {
                return false
            }

            // Category filter
            if let filterCategory = filterCategory, message.category != filterCategory {
                return false
            }

            // Search text
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let messageMatch = message.message.lowercased().contains(searchLower)
                let categoryMatch = message.category.lowercased().contains(searchLower)
                if !messageMatch, !categoryMatch {
                    return false
                }
            }

            return true
        }
    }

    var availableCategories: [String] {
        Array(Set(logs.map(\.category))).sorted()
    }

    var logCount: Int {
        logs.count
    }

    var filteredCount: Int {
        filteredLogs.count
    }

    init() {
        logStream.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func clearLogs() {
        logStream.clear()
    }

    func clearFilters() {
        searchText = ""
        filterLevel = nil
        filterCategory = nil
    }
}
