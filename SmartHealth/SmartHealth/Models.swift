//
//  Models.swift
//  SmartHealth
//
//  Local history record models — persisted via UserDefaults.
//

import Foundation

// MARK: - User Profile

struct UserProfile: Codable, Equatable {
    var surname: String
    var gender: Gender
    var height: Int?       // cm
    var birthYear: Int?    // 出生年份

    enum Gender: String, Codable, CaseIterable {
        case male, female
        var honorific: String { self == .male ? "先生" : "女士" }
    }

    var displayName: String { "\(surname)\(gender.honorific)" }

    var age: Int? {
        guard let birthYear else { return nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - birthYear
    }
}

// MARK: - Heart Rate Record

struct HeartRateRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    let date: Date
    let averageHR: Int
    let maxHR: Int
    let minHR: Int
}

// MARK: - Scale Record

struct ScaleRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    let date: Date
    let weight: Double
    let bmi: Double
    let bodyFat: Double
}

// MARK: - Health Thresholds

struct HealthThresholds: Codable, Equatable {
    var maxHeartRate: Int    // BPM 上限，預設 100
    var minHeartRate: Int    // BPM 下限，預設 50
    var maxBMI: Double       // BMI 上限，預設 25.0
    var maxWeight: Double    // 體重上限 (kg)，預設 90

    static let `default` = HealthThresholds(
        maxHeartRate: 90,
        minHeartRate: 55,
        maxBMI: 24.0,
        maxWeight: 80.0
    )
}
