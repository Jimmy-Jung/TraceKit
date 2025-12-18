// Theme.swift
// TraceKitDemo
//
// Created by jimmy on 2025-12-15.

import SwiftUI

enum Theme {
    // MARK: - Colors

    enum Colors {
        static let background = Color(hex: 0x0F0F0F)
        static let surface = Color(hex: 0x1A1A1A)
        static let surfaceElevated = Color(hex: 0x252525)

        static let textPrimary = Color(hex: 0xF5F5F5)
        static let textSecondary = Color(hex: 0x9E9E9E)
        static let textTertiary = Color(hex: 0x616161)

        static let accent = Color(hex: 0x00D4AA)
        static let accentMuted = Color(hex: 0x00D4AA).opacity(0.2)

        static let border = Color(hex: 0x2A2A2A)
        static let divider = Color(hex: 0x1F1F1F)

        // Log Level Colors
        static let verbose = Color(hex: 0x757575)
        static let debug = Color(hex: 0x64B5F6)
        static let info = Color(hex: 0x81C784)
        static let warning = Color(hex: 0xFFD54F)
        static let error = Color(hex: 0xE57373)
        static let fatal = Color(hex: 0xF44336)
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
        static let title = Font.system(size: 20, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 15, weight: .regular, design: .default)
        static let caption = Font.system(size: 13, weight: .regular, design: .default)
        static let mono = Font.system(size: 13, weight: .regular, design: .monospaced)
        static let monoSmall = Font.system(size: 11, weight: .regular, design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Radius

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 16
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - TraceLevel Color Extension

import TraceKit

extension TraceLevel {
    var color: Color {
        switch self {
        case .verbose: return Theme.Colors.verbose
        case .debug: return Theme.Colors.debug
        case .info: return Theme.Colors.info
        case .warning: return Theme.Colors.warning
        case .error: return Theme.Colors.error
        case .fatal: return Theme.Colors.fatal
        }
    }
}
