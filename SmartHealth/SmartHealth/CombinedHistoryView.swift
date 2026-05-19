//
//  CombinedHistoryView.swift
//  SmartHealth
//
//  Unified health history — heart rate + weight monthly charts.
//  X-axis shows relative months since first record.
//  Tap a data point to see all records for that month.
//

import SwiftUI
import Charts

// MARK: - Month Summary

private struct MonthSummary: Identifiable {
    let id: String          // "2024-01"
    let relativeMonth: Int  // 1, 2, 3...
    let label: String       // "第1個月"
    let calendarLabel: String // "2024年1月"

    var avgHR: Double?
    var maxHR: Double?
    var minHR: Double?
    var avgWeight: Double?
    var avgBMI: Double?
    var avgBodyFat: Double?
    var heartRateRecords: [HeartRateRecord] = []
    var scaleRecords: [ScaleRecord] = []
}

// MARK: - Combined History View

struct CombinedHistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @State private var chartSelection: Int?
    @State private var detailMonth: MonthSummary?

    private var monthSummaries: [MonthSummary] { buildMonthSummaries() }

    // MARK: - Body

    var body: some View {
        Group {
            if monthSummaries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        summaryCards
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        if monthSummaries.contains(where: { $0.avgHR != nil }) {
                            heartRateChart
                                .padding(.horizontal, 20)
                        }

                        if monthSummaries.contains(where: { $0.avgWeight != nil }) {
                            weightChart
                                .padding(.horizontal, 20)
                        }

                        footerText
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("健康歷史")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: chartSelection) { _, newValue in
            if let m = newValue {
                detailMonth = monthSummaries.first { $0.relativeMonth == m }
            }
        }
        .sheet(item: $detailMonth) { month in
            monthDetailView(month)
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "最新心率",
                value: historyStore.heartRateRecordsSorted.first
                    .map { "\($0.averageHR)" } ?? "-",
                unit: "BPM",
                color: .red
            )
            SummaryCard(
                title: "最新體重",
                value: historyStore.scaleRecordsSorted.first
                    .map { String(format: "%.1f", $0.weight) } ?? "-",
                unit: "kg",
                color: .blue
            )
            SummaryCard(
                title: "總記錄",
                value: "\(historyStore.heartRateRecordsSorted.count + historyStore.scaleRecordsSorted.count)",
                unit: "筆",
                color: .green
            )
        }
    }

    // MARK: - Heart Rate Chart

    private var heartRateChart: some View {
        let hrData = monthSummaries.filter { $0.avgHR != nil }

        return VStack(alignment: .leading, spacing: 8) {
            headerRow(icon: "heart.fill", color: .red, title: "心率趨勢")

            Chart {
                ForEach(hrData) { month in
                    if let avg = month.avgHR {
                        LineMark(
                            x: .value("月份", month.relativeMonth),
                            y: .value("平均心率", avg)
                        )
                        .foregroundStyle(.red)
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                    }
                    if let max = month.maxHR {
                        LineMark(
                            x: .value("月份", month.relativeMonth),
                            y: .value("最高心率", max)
                        )
                        .foregroundStyle(.orange)
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                    }
                    if let min = month.minHR {
                        LineMark(
                            x: .value("月份", month.relativeMonth),
                            y: .value("最低心率", min)
                        )
                        .foregroundStyle(.blue)
                        .symbol(Circle().strokeBorder(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                    }
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
                AxisMarks(values: .automatic) { value in
                    if let month = value.as(Int.self) {
                        AxisValueLabel("第\(month)個月")
                            .font(.caption2)
                    }
                }
            }
            .chartXSelection(value: $chartSelection)
            .frame(height: 200)

            // Legend
            HStack(spacing: 16) {
                legendDot(color: .red, label: "平均")
                legendDot(color: .orange, label: "最高")
                legendDot(color: .blue, label: "最低")
            }
            .font(.caption)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weight Chart

    private var weightChart: some View {
        let wtData = monthSummaries.filter { $0.avgWeight != nil }

        return VStack(alignment: .leading, spacing: 8) {
            headerRow(icon: "scalemass.fill", color: .blue, title: "體重趨勢")

            Chart {
                ForEach(wtData) { month in
                    if let weight = month.avgWeight {
                        LineMark(
                            x: .value("月份", month.relativeMonth),
                            y: .value("體重", weight)
                        )
                        .foregroundStyle(by: .value("類型", "體重"))
                        .symbol(by: .value("類型", "體重"))
                        .interpolationMethod(.catmullRom)
                    }
                    if let bmi = month.avgBMI {
                        LineMark(
                            x: .value("月份", month.relativeMonth),
                            y: .value("BMI", bmi)
                        )
                        .foregroundStyle(by: .value("類型", "BMI"))
                        .symbol(by: .value("類型", "BMI"))
                        .interpolationMethod(.catmullRom)
                    }
                    if let bodyFat = month.avgBodyFat {
                        LineMark(
                            x: .value("月份", month.relativeMonth),
                            y: .value("體脂", bodyFat)
                        )
                        .foregroundStyle(by: .value("類型", "體脂"))
                        .symbol(by: .value("類型", "體脂"))
                        .interpolationMethod(.catmullRom)
                    }
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
                AxisMarks(values: .automatic) { value in
                    if let month = value.as(Int.self) {
                        AxisValueLabel("第\(month)個月")
                            .font(.caption2)
                    }
                }
            }
            .chartXSelection(value: $chartSelection)
            .chartLegend(position: .bottom, spacing: 16)
            .frame(height: 240)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Shared Helpers

    private func headerRow(icon: String, color: Color, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline.weight(.semibold))
            Spacer()
            Text("點擊圖表查看詳情")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(.secondary)
        }
    }

    private var footerText: some View {
        let total = historyStore.heartRateRecordsSorted.count + historyStore.scaleRecordsSorted.count
        return Text("共 \(monthSummaries.count) 個月 · \(total) 筆記錄")
            .font(.footnote)
            .foregroundStyle(.tertiary)
    }

    // MARK: - Month Detail Sheet

    private func monthDetailView(_ month: MonthSummary) -> some View {
        NavigationStack {
            List {
                if !month.heartRateRecords.isEmpty {
                    Section("心率記錄（\(month.calendarLabel)）") {
                        ForEach(month.heartRateRecords.sorted(by: { $0.date > $1.date })) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDate(record.date))
                                    .font(.subheadline)
                                HStack(spacing: 16) {
                                    Label("平均 \(record.averageHR)", systemImage: "heart.fill")
                                        .foregroundStyle(.red)
                                    Label("最高 \(record.maxHR)", systemImage: "arrow.up")
                                        .foregroundStyle(.orange)
                                    Label("最低 \(record.minHR)", systemImage: "arrow.down")
                                        .foregroundStyle(.blue)
                                }
                                .font(.caption)
                            }
                        }
                    }
                }

                if !month.scaleRecords.isEmpty {
                    Section("體重記錄（\(month.calendarLabel)）") {
                        ForEach(month.scaleRecords.sorted(by: { $0.date > $1.date })) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDate(record.date))
                                    .font(.subheadline)
                                HStack(spacing: 16) {
                                    Label(String(format: "%.1f kg", record.weight), systemImage: "scalemass.fill")
                                        .foregroundStyle(.blue)
                                    Label(String(format: "BMI %.1f", record.bmi), systemImage: "figure")
                                        .foregroundStyle(.orange)
                                    Label(String(format: "%.1f%%", record.bodyFat), systemImage: "drop.fill")
                                        .foregroundStyle(.green)
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle(month.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        detailMonth = nil
                        chartSelection = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-Hant")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            VStack(spacing: 8) {
                Text("尚無健康記錄")
                    .font(.headline)
                Text("連接裝置並開始測量後\n記錄會自動顯示在這裡")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
    }

    // MARK: - Month Aggregation

    private func buildMonthSummaries() -> [MonthSummary] {
        let hrRecords = historyStore.heartRateRecordsSorted
        let scRecords = historyStore.scaleRecordsSorted

        // Find earliest date across all records
        var earliestDate: Date?
        if let last = hrRecords.last?.date { earliestDate = last }
        if let last = scRecords.last?.date {
            if earliestDate == nil || last < earliestDate! { earliestDate = last }
        }
        guard let startDate = earliestDate else { return [] }

        let calendar = Calendar.current
        let startYear = calendar.component(.year, from: startDate)
        let startMonth = calendar.component(.month, from: startDate)

        // Group records by (year, month) key
        var groups: [String: (hr: [HeartRateRecord], sc: [ScaleRecord])] = [:]

        for record in hrRecords {
            let key = monthKey(for: record.date, calendar: calendar)
            groups[key, default: ([], [])].hr.append(record)
        }
        for record in scRecords {
            let key = monthKey(for: record.date, calendar: calendar)
            groups[key, default: ([], [])].sc.append(record)
        }

        // Build sorted summaries
        let sortedKeys = groups.keys.sorted()
        var summaries: [MonthSummary] = []

        for key in sortedKeys {
            guard let (year, monthNum) = parseMonthKey(key) else { continue }
            let (hrList, scList) = groups[key]!

            let relativeMonth = (year - startYear) * 12 + (monthNum - startMonth) + 1
            let calendarLabel = "\(year)年\(monthNum)月"

            let avgHR: Double? = hrList.isEmpty
                ? nil : Double(hrList.map(\.averageHR).reduce(0, +)) / Double(hrList.count)
            let maxHR: Double? = hrList.isEmpty
                ? nil : Double(hrList.map(\.maxHR).max() ?? 0)
            let minHR: Double? = hrList.isEmpty
                ? nil : Double(hrList.map(\.minHR).min() ?? 0)
            let avgWeight: Double? = scList.isEmpty
                ? nil : scList.map(\.weight).reduce(0, +) / Double(scList.count)
            let avgBMI: Double? = scList.isEmpty
                ? nil : scList.map(\.bmi).reduce(0, +) / Double(scList.count)
            let avgBodyFat: Double? = scList.isEmpty
                ? nil : scList.map(\.bodyFat).reduce(0, +) / Double(scList.count)

            summaries.append(MonthSummary(
                id: key,
                relativeMonth: relativeMonth,
                label: "第\(relativeMonth)個月",
                calendarLabel: calendarLabel,
                avgHR: avgHR,
                maxHR: maxHR,
                minHR: minHR,
                avgWeight: avgWeight,
                avgBMI: avgBMI,
                avgBodyFat: avgBodyFat,
                heartRateRecords: hrList,
                scaleRecords: scList
            ))
        }

        return summaries
    }

    private func monthKey(for date: Date, calendar: Calendar) -> String {
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        return "\(y)-\(String(format: "%02d", m))"
    }

    private func parseMonthKey(_ key: String) -> (Int, Int)? {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]) else { return nil }
        return (year, month)
    }
}

#Preview {
    NavigationStack {
        CombinedHistoryView()
            .environmentObject(HistoryStore())
    }
}
