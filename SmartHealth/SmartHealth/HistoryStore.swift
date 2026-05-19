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
