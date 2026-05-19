//
//  AdaptiveLayoutHelper.swift
//  SmartHealth
//
//  Lightweight landscape-aware layout helpers.
//  All views share the same breakpoint via @Environment(\.horizontalSizeClass).
//

import SwiftUI

// MARK: - Orientation State

/// Observes horizontalSizeClass and exposes a single `isLandscape` flag.
/// Usage: `@Environment(\.isLandscape) var isLandscape`
struct IsLandscapeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isLandscape: Bool {
        get { self[IsLandscapeKey.self] }
        set { self[IsLandscapeKey.self] = newValue }
    }
}

/// Bridge view — reads `horizontalSizeClass` and pushes it into the environment
/// so any child can read `@Environment(\.isLandscape)` without passing it down.
struct AdaptiveRootModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        content
            .environment(\.isLandscape, horizontalSizeClass == .regular)
    }
}

extension View {
    /// Apply at the root of the scene so all children can read `@Environment(\.isLandscape)`.
    func adaptiveRoot() -> some View {
        modifier(AdaptiveRootModifier())
    }
}

// MARK: - Adaptive Stack

/// Switches between VStack (portrait) and HStack (landscape).
struct AdaptiveStack<Content: View>: View {
    let alignment: Alignment
    let spacing: CGFloat?
    @Environment(\.isLandscape) private var isLandscape
    @ViewBuilder let content: () -> Content

    init(
        alignment: Alignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if isLandscape {
            HStack(alignment: alignment.vertical, spacing: spacing) { content() }
        } else {
            VStack(alignment: alignment.horizontal, spacing: spacing) { content() }
        }
    }
}
