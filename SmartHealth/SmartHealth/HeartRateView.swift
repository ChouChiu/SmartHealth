//
//  HeartRateView.swift
//  SmartHealth
//
//  Heart rate monitoring — iOS native, HIG-compliant.
//  .regularMaterial card, system buttons, SF Symbols.
//

import SwiftUI
import Combine
import iREdFramework

struct HeartRateView: View {
    @StateObject private var ble = iREdBluetooth.shared
    @EnvironmentObject var historyStore: HistoryStore
    @State private var sessionReadings: [Int] = []

    private var isPairing: Bool {
        ble.iredDeviceData.heartRateData.state.isPairing
    }
    private var isPaired: Bool {
        ble.iredDeviceData.heartRateData.state.isPaired
    }
    private var isConnected: Bool {
        ble.iredDeviceData.heartRateData.state.isConnected
    }
    private var heartRate: Int? {
        ble.iredDeviceData.heartRateData.data.heartrate
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status pills
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
                .padding(.top, 16)

                // Measurement card
                MeasureCard(
                    value: heartRate != nil ? "\(heartRate!)" : "--",
                    unit: "心率",
                    subtitle: "BPM",
                    accent: .heartRate
                ) {
                    if heartRate != nil {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                                .symbolEffect(.pulse, options: .repeating)
                            Text("正在測量")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)

                // Control buttons
                controlSection
                    .padding(.horizontal, 20)

                // Device info
                DeviceInfoGroup(
                    name: ble.iredDeviceData.heartRateData.data.peripheralName ?? "-",
                    macAddress: ble.iredDeviceData.heartRateData.data.macAddress ?? "-",
                    lastUpdated: ble.iredDeviceData.heartRateData.data.lastUpdatedTime.description
                )
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("心率監測")
        .onChange(of: isConnected) { _, connected in
            if connected {
                sessionReadings = []
            } else if !sessionReadings.isEmpty {
                let avg = sessionReadings.reduce(0, +) / sessionReadings.count
                let max = sessionReadings.max() ?? 0
                let min = sessionReadings.min() ?? 0
                historyStore.addHeartRate(averageHR: avg, maxHR: max, minHR: min)
                sessionReadings = []
            }
        }
        .onChange(of: heartRate) { _, newValue in
            if isConnected, let hr = newValue {
                sessionReadings.append(hr)
            }
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controlSection: some View {
        if isConnected {
            Button(role: .destructive, action: { ble.disconnect(from: .heartRateBelt) }) {
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
                Button(action: { ble.connect(from: .heartRateBelt) }) {
                    Label("連線裝置", systemImage: "link.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)

                Button(action: { ble.startPairing(to: .heartRateBelt) }) {
                    Label("重新配對", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.extraLarge)
            }
        } else {
            Button(action: { ble.startPairing(to: .heartRateBelt) }) {
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
        HeartRateView()
            .environmentObject(HistoryStore())
    }
}
