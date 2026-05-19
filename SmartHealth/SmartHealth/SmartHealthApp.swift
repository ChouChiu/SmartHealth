//
//  SmartHealthApp.swift
//  SmartHealth
//
//  App entry point — iOS native, HIG-compliant.
//

import SwiftUI
import Observation

@main
struct SmartHealthApp: App {
    @State private var appState = AppState()
    @State private var bleManager = BLEManager()
    @State private var historyStore = HistoryStore()
    @State private var locationManager = LocationManager()
    @State private var weatherManager = WeatherManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainView()
                    .environment(appState)
                    .environmentObject(bleManager)
                    .environmentObject(historyStore)
                    .environment(locationManager)
                    .environment(weatherManager)
                    .onAppear {
                        appState.userProfile = historyStore.userProfile
                    }
            } else {
                OnboardingView(historyStore: historyStore)
            }
        }
    }
}
