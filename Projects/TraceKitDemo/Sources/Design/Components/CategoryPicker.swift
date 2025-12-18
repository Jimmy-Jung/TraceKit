// CategoryPicker.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import SwiftUI

struct CategoryPicker: View {
    @Binding var selected: String
    let categories: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: selected == category
                    ) {
                        selected = category
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(isSelected ? Theme.Colors.background : Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(isSelected ? Theme.Colors.accent : Theme.Colors.surfaceElevated)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CategoryPicker(
        selected: .constant("Network"),
        categories: ["Default", "Network", "Auth", "UI", "Database"]
    )
    .padding()
    .background(Theme.Colors.background)
}
