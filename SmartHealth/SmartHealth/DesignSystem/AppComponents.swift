//
//  AppComponents.swift
//  SmartHealth
//
//  Lightweight reusable UI components — ≤3 total, everything else uses native SwiftUI.
//  1. StatusPill  — connection/pairing status badge
//  2. MeasureCard — measurement value display card
//  3. SummaryCard — small stat card for history summaries
//

import SwiftUI

// MARK: - Status Pill

/// SF Symbol + label in a capsule shape. Replaces old StatusBadge.
struct StatusPill: View {
    let icon: String
    let label: String
    var color: Color = .secondary

    var body: some View {
        Label(label, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Measurement Card

/// Large measurement display with material background.
struct MeasureCard<Extra: View>: View {
    let value: String
    let unit: String
    let subtitle: String?
    let accent: AppAccent
    @Environment(\.isLandscape) private var isLandscape
    @ViewBuilder let extra: () -> Extra

    init(
        value: String,
        unit: String,
        subtitle: String? = nil,
        accent: AppAccent,
        @ViewBuilder extra: @escaping () -> Extra = { EmptyView() }
    ) {
        self.value = value
        self.unit = unit
        self.subtitle = subtitle
        self.accent = accent
        self.extra = extra
    }

    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.width > geo.size.height
            let valueSize: CGFloat = isCompact ? 64 : 96
            let unitSize: CGFloat = isCompact ? 20 : 26

            VStack(spacing: 8) {
                Text(value)
                    .appMeasurement(size: valueSize)
                    .foregroundStyle(accent.color)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(unit)
                    .font(.system(size: unitSize, weight: .semibold, design: .default))
                    .foregroundStyle(.secondary)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }

                extra()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, isCompact ? 16 : 32)
            .padding(.horizontal, isCompact ? 24 : 40)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(accent.color.opacity(0.15), lineWidth: 2)
            )
        }
        .frame(height: isLandscape ? 180 : 220)
    }
}

// MARK: - Summary Card

/// Small stat card used in history views.
struct SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Device Info Section

/// Expandable device info using native DisclosureGroup.
struct DeviceInfoGroup: View {
    let name: String
    let macAddress: String
    let lastUpdated: String

    var body: some View {
        DisclosureGroup {
            VStack(spacing: 8) {
                LabeledContent("名稱", value: name)
                Divider()
                LabeledContent("MAC", value: macAddress)
                Divider()
                LabeledContent("最後更新", value: lastUpdated)
            }
            .font(.subheadline)
            .padding(.top, 8)
        } label: {
            Label("裝置資訊", systemImage: "info.circle")
                .font(.headline)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
