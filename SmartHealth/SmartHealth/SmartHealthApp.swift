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
    @State private var notificationManager = NotificationManager()
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
                    .environment(notificationManager)
                    .onAppear {
                        appState.userProfile = historyStore.userProfile
                        notificationManager.requestPermission()
                    }
            } else {
                OnboardingView(historyStore: historyStore)
            }
        }
    }
}
