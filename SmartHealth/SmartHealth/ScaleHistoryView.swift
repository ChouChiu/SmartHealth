//
//  ScaleHistoryView.swift
//  SmartHealth
//
//  Scale history — iOS native, Charts-backed, HIG-compliant.
//

import SwiftUI
import Charts

struct ScaleChart: View {
    let data: [ScaleRecord]
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("體重趨勢")
                .font(.headline.weight(.semibold))

            Chart {
                ForEach(data) { item in
                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("體重", item.weight)
                    )
                    .foregroundStyle(by: .value("類型", "體重"))
                    .symbol(by: .value("類型", "體重"))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("BMI", item.bmi)
                    )
                    .foregroundStyle(by: .value("類型", "BMI"))
                    .symbol(by: .value("類型", "BMI"))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("體脂", item.bodyFat)
                    )
                    .foregroundStyle(by: .value("類型", "體脂"))
                    .symbol(by: .value("類型", "體脂"))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartForegroundStyleScale([
                "體重": Color.blue,
                "BMI": Color.orange,
                "體脂": Color.green
            ])
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
            .chartLegend(position: .bottom, spacing: 16)
            .frame(height: compact ? 200 : 240)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ScaleHistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(\.isLandscape) private var isLandscape

    var body: some View {
        Group {
            if historyStore.scaleRecordsSorted.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        HStack(spacing: 12) {
                            SummaryCard(
                                title: "最新體重",
                                value: String(format: "%.1f", historyStore.scaleRecordsSorted.first?.weight ?? 0),
                                unit: "kg",
                                color: .blue
                            )
                            SummaryCard(
                                title: "最新BMI",
                                value: String(format: "%.1f", historyStore.scaleRecordsSorted.first?.bmi ?? 0),
                                unit: "",
                                color: .orange
                            )
                            SummaryCard(
                                title: "記錄",
                                value: "\(historyStore.scaleRecordsSorted.count)",
                                unit: "筆",
                                color: .green
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        ScaleChart(data: historyStore.scaleRecordsSorted, compact: isLandscape)
                            .padding(.horizontal, 20)

                        Text("共 \(historyStore.scaleRecordsSorted.count) 筆記錄")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("體重歷史")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "scalemass")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            VStack(spacing: 8) {
                Text("尚無體重記錄")
                    .font(.headline)
                Text("連接智慧體重秤並開始測量後\n記錄會自動顯示在這裡")
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
        ScaleHistoryView()
            .environmentObject(HistoryStore())
    }
}
