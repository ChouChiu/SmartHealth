//
//  HeartRateHistoryView.swift
//  SmartHealth
//
//  Heart rate history — iOS native, Charts-backed, HIG-compliant.
//

import SwiftUI
import Charts

enum HeartRateMetric {
    case average, max, min

    var title: String {
        switch self {
        case .average: return "平均心率"
        case .max: return "最高心率"
        case .min: return "最低心率"
        }
    }

    var color: Color {
        switch self {
        case .average: return .red
        case .max: return .orange
        case .min: return .blue
        }
    }
}

struct HeartRateChart: View {
    let data: [HeartRateRecord]
    let metric: HeartRateMetric
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(metric.color)
                    .frame(width: 8, height: 8)
                Text(metric.title)
                    .font(.headline.weight(.semibold))
                Spacer()
                if let latest = data.first {
                    let value: Int = {
                        switch metric {
                        case .average: return latest.averageHR
                        case .max: return latest.maxHR
                        case .min: return latest.minHR
                        }
                    }()
                    Text("\(value) BPM")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Chart {
                ForEach(data) { item in
                    let value: Int = {
                        switch metric {
                        case .average: return item.averageHR
                        case .max: return item.maxHR
                        case .min: return item.minHR
                        }
                    }()

                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("心率", value)
                    )
                    .foregroundStyle(metric.color)
                    .symbol(Circle().strokeBorder(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(.quaternary)
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: compact ? 160 : 180)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

extension HeartRateChart {
    func chartFrame(compact: Bool) -> some View {
        var copy = self
        copy.compact = compact
        return copy
    }
}

struct HeartRateHistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.isLandscape) private var isLandscape

    private var averageHR: Int {
        let records = historyStore.heartRateRecordsSorted
        guard !records.isEmpty else { return 0 }
        return records.map(\.averageHR).reduce(0, +) / records.count
    }

    var body: some View {
        Group {
            if historyStore.heartRateRecordsSorted.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary row
                        HStack(spacing: 12) {
                            SummaryCard(
                                title: "最新",
                                value: "\(historyStore.heartRateRecordsSorted.first?.averageHR ?? 0)",
                                unit: "BPM",
                                color: .red
                            )
                            SummaryCard(
                                title: "平均",
                                value: "\(averageHR)",
                                unit: "BPM",
                                color: .blue
                            )
                            SummaryCard(
                                title: "記錄",
                                value: "\(historyStore.heartRateRecordsSorted.count)",
                                unit: "筆",
                                color: .green
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        if isLandscape {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                HeartRateChart(data: historyStore.heartRateRecordsSorted, metric: .average)
                                    .chartFrame(compact: true)
                                HeartRateChart(data: historyStore.heartRateRecordsSorted, metric: .max)
                                    .chartFrame(compact: true)
                                HeartRateChart(data: historyStore.heartRateRecordsSorted, metric: .min)
                                    .chartFrame(compact: true)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            HeartRateChart(data: historyStore.heartRateRecordsSorted, metric: .average)
                                .padding(.horizontal, 20)

                            HeartRateChart(data: historyStore.heartRateRecordsSorted, metric: .max)
                                .padding(.horizontal, 20)

                            HeartRateChart(data: historyStore.heartRateRecordsSorted, metric: .min)
                                .padding(.horizontal, 20)
                        }

                        Text("共 \(historyStore.heartRateRecordsSorted.count) 筆記錄")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("心率歷史")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.text.square")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            VStack(spacing: 8) {
                Text("尚無心率記錄")
                    .font(.headline)
                Text("連接心率帶並開始測量後\n記錄會自動顯示在這裡")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        HeartRateHistoryView()
            .environmentObject(HistoryStore())
    }
}
