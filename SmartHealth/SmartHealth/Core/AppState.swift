//
//  AppState.swift
//  SmartHealth
//
//  Centralized app state — user profile, tab selection.
//  Uses @Observable (iOS 17+) for efficient observation.
//

import SwiftUI
import Observation

@Observable
final class AppState {
    var selectedTab: Tab = .heartRate
    var userProfile: UserProfile?

    enum Tab: Int, CaseIterable {
        case heartRate
        case scale
        case history
        case profile

        var title: String {
            switch self {
            case .heartRate: return "心率"
            case .scale:      return "體重"
            case .history:   return "歷史"
            case .profile:    return "個人"
            }
        }

        var icon: String {
            switch self {
            case .heartRate: return "heart.fill"
            case .scale:      return "scalemass.fill"
            case .history:   return "chart.line.uptrend.xyaxis"
            case .profile:    return "person.fill"
            }
        }
    }

    var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5...11:  return "早上好"
        case 12...13: return "中午好"
        case 14...17: return "下午好"
        default:      return "晚上好"
        }
    }

    var greetingText: String {
        if let name = userProfile?.displayName, !name.isEmpty {
            return "\(name) \(timeGreeting)"
        }
        return timeGreeting
    }

    var avatarLetter: String {
        if let surname = userProfile?.surname, !surname.isEmpty {
            return String(surname.prefix(1))
        }
        return "?"
    }
}
