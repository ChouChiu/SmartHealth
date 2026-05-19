//
//  MainView.swift
//  SmartHealth
//
//  Root view — native TabView with greeting/weather header in toolbar.
//  Replaces ContentView + GreetingHeaderView.
//

import SwiftUI
import CoreLocation

struct MainView: View {
    @Environment(AppState.self) var appState
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(LocationManager.self) var locationManager
    @Environment(WeatherManager.self) var weatherManager
    @Environment(\.isLandscape) private var isLandscape
    @State private var showHistory = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            TabView(selection: Bindable(appState).selectedTab) {
                NavigationStack {
                    HeartRateView()
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem {
                    Label(AppState.Tab.heartRate.title, systemImage: AppState.Tab.heartRate.icon)
                }
                .tag(AppState.Tab.heartRate)

                NavigationStack {
                    ScaleView()
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem {
                    Label(AppState.Tab.scale.title, systemImage: AppState.Tab.scale.icon)
                }
                .tag(AppState.Tab.scale)

                NavigationStack {
                    ProfileView()
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem {
                    Label(AppState.Tab.profile.title, systemImage: AppState.Tab.profile.icon)
                }
                .tag(AppState.Tab.profile)
            }
        }
        .onAppear { handleWeather() }
        .onChange(of: locationManager.currentLocation) { _, _ in handleWeather() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.greetingText)
                    .font(.headline.weight(.semibold))
                weatherView
            }
            Spacer()
            Button {
                showHistory = true
            } label: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, isLandscape ? 4 : 8)
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                historyDestination
            }
        }
    }

    private var historyDestination: some View {
        CombinedHistoryView()
    }

    @ViewBuilder
    private var weatherView: some View {
        if let temp = weatherManager.temperature {
            if isLandscape {
                HStack(spacing: 8) {
                    Image(systemName: weatherManager.symbolName)
                        .symbolRenderingMode(.multicolor)
                    Text("\(temp)")
                    if let city = weatherManager.cityName {
                        Text("·")
                            .foregroundStyle(.quaternary)
                        Text(city)
                    }
                    if let condition = weatherManager.condition {
                        Text(condition)
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: weatherManager.symbolName)
                        .symbolRenderingMode(.multicolor)
                    Text("\(temp)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Weather

    private func handleWeather() {
        guard let location = locationManager.currentLocation else {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            }
            return
        }
        Task { await weatherManager.fetchWeather(for: location) }
    }
}

#Preview {
    MainView()
        .environment(AppState())
        .environmentObject(HistoryStore())
        .environment(LocationManager())
        .environment(WeatherManager())
}
