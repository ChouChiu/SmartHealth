//
//  ProfileView.swift
//  SmartHealth
//
//  User profile & settings — native .form style, HIG-compliant.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @State private var showEditSheet = false

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
                LabeledContent("版本", value: "1.0.0")

                if let name = historyStore.userProfile?.displayName {
                    LabeledContent("使用者", value: name)
                }
            }
        }
        .navigationTitle("個人")
        .sheet(isPresented: $showEditSheet) {
            ProfileEditView(historyStore: historyStore)
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

    init(historyStore: HistoryStore) {
        self.historyStore = historyStore
        let profile = historyStore.userProfile
        _surname = State(initialValue: profile?.surname ?? "")
        _gender = State(initialValue: profile?.gender ?? .male)
        _heightText = State(initialValue: profile?.height.map(String.init) ?? "")
        _birthYear = State(initialValue: profile?.birthYear ?? Calendar.current.component(.year, from: Date()) - 30)
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
                        Picker(selection: $birthYear) {
                            let currentYear = Calendar.current.component(.year, from: Date())
                            ForEach((currentYear - 100)...currentYear, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        } label: {
                            Text("出生年份")
                        }
                        .pickerStyle(.wheel)
                    }
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
                        dismiss()
                    }
                    .disabled(surname.trimmingCharacters(in: .whitespaces).isEmpty)
                }

            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(HistoryStore())
    }
}
