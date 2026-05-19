//
//  ScaleView.swift
//  SmartHealth
//
//  Smart scale monitoring — iOS native, HIG-compliant.
//  .regularMaterial card, system buttons, SF Symbols.
//

import SwiftUI
import Combine
import iREdFramework

struct ScaleView: View {
    @StateObject private var ble = iREdBluetooth.shared
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.isLandscape) private var isLandscape
    @State private var hasSavedCurrent = false

    private var isPairing: Bool {
        ble.iredDeviceData.scaleData.state.isPairing
    }
    private var isPaired: Bool {
        ble.iredDeviceData.scaleData.state.isPaired
    }
    private var isConnected: Bool {
        ble.iredDeviceData.scaleData.state.isConnected
    }
    private var weight: Double? {
        ble.iredDeviceData.scaleData.data.weight
    }
    private var isStable: Bool {
        ble.iredDeviceData.scaleData.data.isFinalResult == true
    }

    var body: some View {
        ScrollView {
            if isLandscape {
                landscapeContent
            } else {
                portraitContent
            }
        }
        .navigationTitle("體重監測")
        .onChange(of: isConnected) { _, connected in
            if connected { hasSavedCurrent = false }
        }
        .onChange(of: isStable) { _, stable in
            guard stable, let w = weight, !hasSavedCurrent else { return }
            let profile = historyStore.userProfile
            let height = profile?.height ?? 170
            let genderStr = profile?.gender == .male ? "male" : "female"
            let age = profile?.age ?? 30
            let scale = ble.iredDeviceData.scaleData
            let bmi = scale.data.toBMI(height: height, weight: w)
            let bodyFat = scale.data.toBodyFat(height: height, age: age, gender: genderStr)
            historyStore.addScale(weight: w, bmi: bmi, bodyFat: bodyFat)
            hasSavedCurrent = true
        }
    }

    // MARK: - Layout

    private var portraitContent: some View {
        VStack(spacing: 24) {
            statusPillsRow
                .padding(.top, 16)
            measureCardView
                .padding(.horizontal, 20)
            controlSection
                .padding(.horizontal, 20)
            deviceInfoView
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 32)
    }

    private var landscapeContent: some View {
        HStack(alignment: .top, spacing: 20) {
            measureCardView
                .frame(maxWidth: .infinity)

            VStack(spacing: 20) {
                statusPillsRow
                controlSection
                deviceInfoView
            }
            .frame(width: 320)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var statusPillsRow: some View {
        HStack(spacing: 12) {
            StatusPill(
                icon: "antenna.radiowaves.left.and.right",
                label: isPairing ? "配對中…" : (isPaired ? "已配對" : "未配對"),
                color: isPairing ? .orange : (isPaired ? .blue : .secondary)
            )
            StatusPill(
                icon: "wave.3.right",
                label: isConnected ? "已連線" : "未連線",
                color: isConnected ? .green : .red
            )
        }
    }

    private var measureCardView: some View {
        MeasureCard(
            value: weight != nil ? String(format: "%.1f", weight!) : "--.-",
            unit: "公斤",
            subtitle: nil,
            accent: .scale
        ) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isStable ? .green : .orange)
                    .frame(width: 8, height: 8)
                Text(isStable ? "已穩定" : "測量中…")
                    .font(.subheadline)
                    .foregroundStyle(isStable ? .green : .orange)
            }
            .padding(.top, 8)
        }
    }

    private var deviceInfoView: some View {
        DeviceInfoGroup(
            name: ble.iredDeviceData.scaleData.data.peripheralName ?? "-",
            macAddress: ble.iredDeviceData.scaleData.data.macAddress ?? "-",
            lastUpdated: ble.iredDeviceData.scaleData.data.lastUpdatedTime.description
        )
    }

    // MARK: - Controls

    @ViewBuilder
    private var controlSection: some View {
        if isConnected {
            Button(role: .destructive, action: { ble.disconnect(from: .scale) }) {
                Label("斷線", systemImage: "xmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
        } else if isPairing {
            Button(action: { ble.stopPairing() }) {
                Label("停止配對", systemImage: "stop.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.extraLarge)
            .tint(.orange)
        } else if isPaired {
            VStack(spacing: 12) {
                Button(action: { ble.connect(from: .scale) }) {
                    Label("連線裝置", systemImage: "link.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)

                Button(action: { ble.startPairing(to: .scale) }) {
                    Label("重新配對", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.extraLarge)
            }
        } else {
            Button(action: { ble.startPairing(to: .scale) }) {
                Label("開始配對", systemImage: "waveform.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
        }
    }
}

#Preview {
    NavigationStack {
        ScaleView()
            .environmentObject(HistoryStore())
    }
}
