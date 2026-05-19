//
//  AppColors.swift
//  SmartHealth
//
//  iOS-native color tokens — system colors only, zero custom hex values.
//  Light/dark mode and contrast handled automatically by the system.
//

import SwiftUI

// MARK: - Semantic Accent Colors

enum AppAccent {
    /// Heart rate — warm red, matches heart.fill SF Symbol
    case heartRate
    /// Scale/weight — cool blue, medical precision feel
    case scale
    /// Generic brand accent
    case brand

    var color: Color {
        switch self {
        case .heartRate: return .red
        case .scale:      return .blue
        case .brand:      return .blue
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply accent color via semantic key
    func appAccent(_ accent: AppAccent) -> some View {
        self.tint(accent.color)
    }
}
