//
//  ProfileView.swift
//  SmartHealth
//
//  User profile & settings — native .form style, HIG-compliant.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @Environment(NotificationManager.self) private var notificationManager
    @AppStorage("SmartHealth.debugMode") private var isDebugMode = false
    @State private var showEditSheet = false
    @State private var versionTapCount = 0
    @State private var tapResetTask: Task<Void, Never>?

    var body: some View {
        List {
            // MARK: Profile Section
            Section {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(historyStore.userProfile?.surname.prefix(1) ?? "?")
                                .font(.title.weight(.semibold))
                                .foregroundStyle(.blue)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(historyStore.userProfile?.displayName ?? "未設定")
                            .font(.title3.weight(.semibold))
                        Text("點擊編輯個人資料")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
                .onTapGesture { showEditSheet = true }
            }

            // MARK: History Stats
            Section("記錄統計") {
                LabeledContent("心率記錄", value: "\(historyStore.heartRateRecordsSorted.count) 筆")
                LabeledContent("體重記錄", value: "\(historyStore.scaleRecordsSorted.count) 筆")
            }

            // MARK: About
            Section("關於") {
                LabeledContent("App 名稱", value: "SmartHealth")

                HStack {
                    Text("版本")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(isDebugMode ? "1.0.0 🛠" : "1.0.0")
                        .foregroundStyle(isDebugMode ? .orange : .primary)
                }
                .contentShape(.rect)
                .onTapGesture { onVersionTap() }

                if let name = historyStore.userProfile?.displayName {
                    LabeledContent("使用者", value: name)
                }
            }

            // MARK: Debug Tools
            if isDebugMode {
                Section {
                    HStack {
                        Text("通知權限")
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(notificationManager.isAuthorized ? .green : .red)
                                .frame(width: 8, height: 8)
                            Text(notificationManager.isAuthorized ? "已授權" : "未授權")
                                .font(.subheadline)
                                .foregroundStyle(notificationManager.isAuthorized ? .green : .red)
                        }
                    }

                    if !notificationManager.isAuthorized {
                        Button {
                            notificationManager.requestPermission()
                        } label: {
                            Label("重新請求通知權限", systemImage: "bell.badge")
                        }
                    }
                } header: {
                    Text("🛠 通知狀態")
                }

                Section {
                    Button {
                        notificationManager.notifyHeartRateHigh(bpm: 110)
                    } label: {
                        Label("測試心率過高通知 (110 BPM)", systemImage: "heart.fill")
                    }
                    .tint(.red)

                    Button {
                        notificationManager.notifyHeartRateLow(bpm: 45)
                    } label: {
                        Label("測試心率過低通知 (45 BPM)", systemImage: "heart.slash")
                    }
                    .tint(.blue)

                    Button {
                        notificationManager.notifyWeightHigh(weight: 85, bmi: 28)
                    } label: {
                        Label("測試體重提醒通知 (85kg / BMI 28)", systemImage: "scalemass.fill")
                    }
                    .tint(.orange)
                } header: {
                    Text("🛠 通知測試")
                } footer: {
                    if !notificationManager.isAuthorized {
                        Text("⚠️ 尚未取得通知權限，測試通知將無法顯示。請先到 iOS 設定 > SmartHealth > 通知 中開啟，或點擊上方按鈕重新請求。")
                    }
                }

                Section {
                    Button {
                        historyStore.generateSampleHeartRateData()
                    } label: {
                        Label("產生範例心率資料（14 筆）", systemImage: "waveform.path.ecg")
                    }

                    Button {
                        historyStore.generateSampleScaleData()
                    } label: {
                        Label("產生範例體重資料（14 筆）", systemImage: "scalemass")
                    }
                } header: {
                    Text("🛠 範例資料")
                }

                Section {
                    Button(role: .destructive) {
                        historyStore.clearAllData()
                    } label: {
                        Label("清除所有資料", systemImage: "trash")
                    }
                } header: {
                    Text("🛠 資料操作")
                }
            }
        }
        .navigationTitle("個人")
        .sheet(isPresented: $showEditSheet) {
            ProfileEditView(historyStore: historyStore)
        }
    }

    // MARK: - Debug Tap

    private func onVersionTap() {
        tapResetTask?.cancel()
        versionTapCount += 1

        if versionTapCount >= 5 {
            versionTapCount = 0
            isDebugMode.toggle()
            return
        }

        tapResetTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            versionTapCount = 0
        }
    }
}

// MARK: - Profile Edit Sheet

struct ProfileEditView: View {
    let historyStore: HistoryStore
    @Environment(\.dismiss) var dismiss

    @State private var surname: String
    @State private var gender: UserProfile.Gender
    @State private var heightText: String
    @State private var birthYear: Int
    @State private var showYearPicker = false
    @State private var maxHeartRateText: String
    @State private var minHeartRateText: String
    @State private var maxBMIText: String
    @State private var maxWeightText: String

    init(historyStore: HistoryStore) {
        self.historyStore = historyStore
        let profile = historyStore.userProfile
        let thresholds = historyStore.healthThresholds
        _surname = State(initialValue: profile?.surname ?? "")
        _gender = State(initialValue: profile?.gender ?? .male)
        _heightText = State(initialValue: profile?.height.map(String.init) ?? "")
        _birthYear = State(initialValue: profile?.birthYear ?? Calendar.current.component(.year, from: Date()) - 30)
        _maxHeartRateText = State(initialValue: String(thresholds.maxHeartRate))
        _minHeartRateText = State(initialValue: String(thresholds.minHeartRate))
        _maxBMIText = State(initialValue: String(format: "%.1f", thresholds.maxBMI))
        _maxWeightText = State(initialValue: String(format: "%.1f", thresholds.maxWeight))
    }

    @FocusState private var isSurnameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Avatar Preview
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Text(surname.isEmpty ? "?" : String(surname.prefix(1)))
                                        .font(.title.weight(.semibold))
                                        .foregroundStyle(.blue)
                                )

                            Text(surname.isEmpty ? "未命名" : "\(surname)\(gender.honorific)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // MARK: Basic Info
                Section("基本資料") {
                    HStack {
                        Text("姓氏")
                            .foregroundStyle(.secondary)
                        TextField("請輸入姓氏", text: $surname)
                            .multilineTextAlignment(.trailing)
                            .focused($isSurnameFocused)
                            .submitLabel(.done)
                    }

                    HStack {
                        Text("性別")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("性別", selection: $gender) {
                            Text("男").tag(UserProfile.Gender.male)
                            Text("女").tag(UserProfile.Gender.female)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                }

                Section("身體數據（選填）") {
                    HStack {
                        Text("身高")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("例如 170", text: $heightText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("cm")
                            .foregroundStyle(.tertiary)
                    }
                    HStack {
                        Text("出生年份")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            showYearPicker = true
                        } label: {
                            Text(String(birthYear))
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showYearPicker) {
                            yearPickerSheet
                        }
                    }
                }

                // MARK: Health Thresholds
                Section {
                    HStack {
                        Text("心率上限")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("100", text: $maxHeartRateText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("BPM")
                            .foregroundStyle(.tertiary)
                    }
                    HStack {
                        Text("心率下限")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("50", text: $minHeartRateText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("BPM")
                            .foregroundStyle(.tertiary)
                    }
                } header: {
                    Text("健康提醒 · 心率")
                } footer: {
                    Text("心跳太快或太慢時，會溫馨提醒您休息。")
                }

                Section {
                    HStack {
                        Text("BMI 上限")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("25.0", text: $maxBMIText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("體重上限")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("90.0", text: $maxWeightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundStyle(.tertiary)
                    }
                } header: {
                    Text("健康提醒 · 體重")
                } footer: {
                    Text("體重偏高時，會推薦適合您的溫和活動。")
                }
            }
            .navigationTitle("編輯個人資料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let trimmed = surname.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        let height = Int(heightText).flatMap { $0 > 0 ? $0 : nil }
                        let profile = UserProfile(
                            surname: trimmed,
                            gender: gender,
                            height: height,
                            birthYear: birthYear
                        )
                        historyStore.saveUserProfile(profile)

                        // Save thresholds
                        let maxHR = Int(maxHeartRateText) ?? 90
                        let minHR = Int(minHeartRateText) ?? 55
                        let maxBMI = Double(maxBMIText) ?? 24.0
                        let maxWeight = Double(maxWeightText) ?? 80.0
                        let thresholds = HealthThresholds(
                            maxHeartRate: max(maxHR, minHR + 5),
                            minHeartRate: min(minHR, maxHR - 5),
                            maxBMI: maxBMI,
                            maxWeight: maxWeight
                        )
                        historyStore.saveThresholds(thresholds)
                        dismiss()
                    }
                    .disabled(surname.trimmingCharacters(in: .whitespaces).isEmpty)
                }

            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Year Picker Sheet

    @ViewBuilder
    private var yearPickerSheet: some View {
        NavigationStack {
            VStack {
                let currentYear = Calendar.current.component(.year, from: Date())
                Picker(selection: $birthYear) {
                    ForEach((currentYear - 100)...currentYear, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                } label: {
                    Text("出生年份")
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("選擇出生年份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        showYearPicker = false
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(HistoryStore())
    }
}
