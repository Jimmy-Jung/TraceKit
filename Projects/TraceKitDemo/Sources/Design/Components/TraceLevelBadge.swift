// TraceLevelBadge.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import SwiftUI
import TraceKit

struct TraceLevelBadge: View {
    let level: TraceLevel

    var body: some View {
        Text(level.name)
            .font(Theme.Typography.monoSmall)
            .fontWeight(.medium)
            .foregroundColor(level.color)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(level.color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.sm) {
        TraceLevelBadge(level: .verbose)
        TraceLevelBadge(level: .debug)
        TraceLevelBadge(level: .info)
        TraceLevelBadge(level: .warning)
        TraceLevelBadge(level: .error)
        TraceLevelBadge(level: .fatal)
    }
    .padding()
    .background(Theme.Colors.background)
}
