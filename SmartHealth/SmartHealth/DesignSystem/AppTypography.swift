//
//  AppTypography.swift
//  SmartHealth
//
//  Typography system — pure SF Pro, Dynamic Type via semantic font styles.
//  Elderly-friendly: all semantic styles, system handles scaling.
//  Measurement display uses fixed large sizes with minimumScaleFactor.
//

import SwiftUI

// MARK: - View Modifiers

struct AppBodyModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.body.weight(.medium))
    }
}

struct AppHeadlineModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.headline.weight(.semibold))
    }
}

struct AppTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.title.weight(.bold))
    }
}

struct AppLargeTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.largeTitle.weight(.bold))
    }
}

// MARK: - Measurement Display

struct AppMeasurementModifier: ViewModifier {
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .bold, design: .default))
            .monospacedDigit()
    }
}

// MARK: - View Extensions

extension View {
    func appBody() -> some View {
        modifier(AppBodyModifier())
    }

    func appHeadline() -> some View {
        modifier(AppHeadlineModifier())
    }

    func appTitle() -> some View {
        modifier(AppTitleModifier())
    }

    func appLargeTitle() -> some View {
        modifier(AppLargeTitleModifier())
    }

    /// Huge measurement number — uses monospaced digits to prevent layout shift
    func appMeasurement(size: CGFloat = 88) -> some View {
        modifier(AppMeasurementModifier(size: size))
    }
}
