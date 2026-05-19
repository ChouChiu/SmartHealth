//
//  HistoryStore.swift
//  SmartHealth
//
//  Local persistence for heart rate & scale history using UserDefaults.
//

import Foundation
import Combine

/// Observes and persists heart rate, scale records, and user profile locally.
final class HistoryStore: ObservableObject {
    @Published var heartRateRecords: [HeartRateRecord] = []
    @Published var scaleRecords: [ScaleRecord] = []
    @Published var userProfile: UserProfile?
    @Published var healthThresholds: HealthThresholds = .default

    private let heartRateKey = "SmartHealth.heartRateRecords"
    private let scaleKey = "SmartHealth.scaleRecords"
    private let profileKey = "SmartHealth.userProfile"
    private let thresholdsKey = "SmartHealth.thresholds"

    var greetingName: String {
        userProfile?.displayName ?? ""
    }

    init() {
        load()
    }

    // MARK: - User Profile

    func saveUserProfile(_ profile: UserProfile) {
        userProfile = profile
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: profileKey)
    }

    private func loadUserProfile() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
        }
    }

    // MARK: - Heart Rate

    /// Sorted newest-first.
    var heartRateRecordsSorted: [HeartRateRecord] {
        heartRateRecords.sorted { $0.date > $1.date }
    }

    func addHeartRate(averageHR: Int, maxHR: Int, minHR: Int) {
        let record = HeartRateRecord(
            date: Date(),
            averageHR: averageHR,
            maxHR: maxHR,
            minHR: minHR
        )
        heartRateRecords.append(record)
        saveHeartRate()
    }

    // MARK: - Scale

    /// Sorted newest-first.
    var scaleRecordsSorted: [ScaleRecord] {
        scaleRecords.sorted { $0.date > $1.date }
    }

    func addScale(weight: Double, bmi: Double, bodyFat: Double) {
        let record = ScaleRecord(
            date: Date(),
            weight: weight,
            bmi: bmi,
            bodyFat: bodyFat
        )
        scaleRecords.append(record)
        saveScale()
    }

    // MARK: - Thresholds

    func saveThresholds(_ thresholds: HealthThresholds) {
        healthThresholds = thresholds
        guard let data = try? JSONEncoder().encode(thresholds) else { return }
        UserDefaults.standard.set(data, forKey: thresholdsKey)
    }

    private func loadThresholds() {
        if let data = UserDefaults.standard.data(forKey: thresholdsKey),
           let thresholds = try? JSONDecoder().decode(HealthThresholds.self, from: data) {
            healthThresholds = thresholds
        }
    }

    // MARK: - Debug Helpers

    /// 產生 24 筆過去半年（每週約一筆）的隨機心率範例資料，讓月度圖表有足夠資料點
    func generateSampleHeartRateData() {
        let calendar = Calendar.current
        let now = Date()
        let samples: [HeartRateRecord] = (0..<24).map { weekOffset in
            // 每週 1 筆，跨 24 週 ≈ 6 個月
            var date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
            // 加上 ±2 天的隨機偏移，避免全部擠在同一個星期幾
            date = calendar.date(byAdding: .day, value: Int.random(in: -2...2), to: date) ?? date
            date = calendar.date(
                bySettingHour: Int.random(in: 6...22),
                minute: Int.random(in: 0...59),
                second: 0,
                of: date
            ) ?? date
            let avg = Int.random(in: 65...95)
            return HeartRateRecord(
                id: UUID(),
                date: date,
                averageHR: avg,
                maxHR: avg + Int.random(in: 5...20),
                minHR: avg - Int.random(in: 5...15)
            )
        }
        heartRateRecords.append(contentsOf: samples)
        saveHeartRate()
    }

    /// 產生 24 筆過去半年（每週約一筆）的隨機體重範例資料，讓月度圖表有足夠資料點
    func generateSampleScaleData() {
        let calendar = Calendar.current
        let now = Date()
        let samples: [ScaleRecord] = (0..<24).map { weekOffset in
            // 每週 1 筆，跨 24 週 ≈ 6 個月
            var date = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
            // 加上 ±2 天的隨機偏移 + 早晨時段（模擬每週量體重的習慣）
            date = calendar.date(byAdding: .day, value: Int.random(in: -2...2), to: date) ?? date
            date = calendar.date(
                bySettingHour: Int.random(in: 7...10),
                minute: Int.random(in: 0...59),
                second: 0,
                of: date
            ) ?? date
            // 模擬體重逐漸變化：從早期較高到近期較低（減重趨勢）
            let baseWeight = 80.0 - Double(weekOffset) * 0.3 + Double.random(in: -2...2)
            let weight = max(60, min(88, baseWeight))
            let bmi = weight * 0.35 + Double.random(in: -1.5...1.5)
            return ScaleRecord(
                id: UUID(),
                date: date,
                weight: weight,
                bmi: max(18, min(33, bmi)),
                bodyFat: Double.random(in: 18...35)
            )
        }
        scaleRecords.append(contentsOf: samples)
        saveScale()
    }

    /// 清除所有記錄與個人資料
    func clearAllData() {
        heartRateRecords = []
        scaleRecords = []
        userProfile = nil
        healthThresholds = .default
        UserDefaults.standard.removeObject(forKey: heartRateKey)
        UserDefaults.standard.removeObject(forKey: scaleKey)
        UserDefaults.standard.removeObject(forKey: profileKey)
        UserDefaults.standard.removeObject(forKey: thresholdsKey)
    }

    // MARK: - Persistence

    private func saveHeartRate() {
        guard let data = try? JSONEncoder().encode(heartRateRecords) else { return }
        UserDefaults.standard.set(data, forKey: heartRateKey)
    }

    private func saveScale() {
        guard let data = try? JSONEncoder().encode(scaleRecords) else { return }
        UserDefaults.standard.set(data, forKey: scaleKey)
    }

    private func load() {
        loadUserProfile()
        loadThresholds()
        if let data = UserDefaults.standard.data(forKey: heartRateKey),
           let records = try? JSONDecoder().decode([HeartRateRecord].self, from: data) {
            heartRateRecords = records
        }
        if let data = UserDefaults.standard.data(forKey: scaleKey),
           let records = try? JSONDecoder().decode([ScaleRecord].self, from: data) {
            scaleRecords = records
        }
    }
}
