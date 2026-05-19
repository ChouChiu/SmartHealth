//
//  OnboardingView.swift
//  SmartHealth
//
//  First-launch onboarding — iOS native, HIG-compliant.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var historyStore: HistoryStore
    @State private var surname = ""
    @State private var gender: UserProfile.Gender = .male
    @State private var heightText = ""
    @State private var birthYear: Int = Calendar.current.component(.year, from: Date()) - 30
    @FocusState private var isSurnameFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var canProceed: Bool {
        !surname.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var isLandscape: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            // 背景点击收起键盘 — 仅在非交互区域生效
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isSurnameFocused = false }
                .allowsHitTesting(isSurnameFocused)

            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
    }

    // MARK: - Portrait

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            Spacer()
            logoSection(iconSize: 60)
            Spacer()
            inputCard
                .padding(.horizontal, 32)
            Spacer()
            startButton
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
    }

    // MARK: - Landscape

    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            Spacer()
            logoSection(iconSize: 48)
                .frame(width: 200)
            Spacer()
            VStack {
                Spacer()
                inputCard
                    .padding(.horizontal, 24)
                Spacer()
                startButton
                    .padding(.horizontal, 24)
                Spacer()
            }
            .frame(maxWidth: 400)
            Spacer()
        }
    }

    // MARK: - Logo

    private func logoSection(iconSize: CGFloat) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(.blue)
                .symbolRenderingMode(.hierarchical)
            Text("SmartHealth")
                .font(.largeTitle.weight(.bold))
            Text("歡迎使用智慧健康管理")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Input Card

    private var inputCard: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("姓氏")
                    .font(.headline)
                TextField("請輸入您的姓氏", text: $surname)
                    .textFieldStyle(.roundedBorder)
                    .focused($isSurnameFocused)
                    .submitLabel(.done)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("性別")
                    .font(.headline)
                Picker("性別", selection: $gender) {
                    Text("男").tag(UserProfile.Gender.male)
                    Text("女").tag(UserProfile.Gender.female)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("身高（選填）")
                    .font(.headline)
                HStack(spacing: 8) {
                    TextField("例如 170", text: $heightText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Text("cm")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Picker(selection: $birthYear) {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    ForEach((currentYear - 100)...currentYear, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                } label: {
                    Text("出生年份")
                        .foregroundStyle(.secondary)
                }
                .pickerStyle(.wheel)
            }
        }
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            let trimmed = surname.trimmingCharacters(in: .whitespaces)
            let height = Int(heightText).flatMap { $0 > 0 ? $0 : nil }
            let profile = UserProfile(
                surname: trimmed,
                gender: gender,
                height: height,
                birthYear: birthYear
            )
            historyStore.saveUserProfile(profile)
            withAnimation(.easeInOut) {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
        } label: {
            Text("開始使用")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.extraLarge)
        .disabled(!canProceed)
    }
}

#Preview {
    OnboardingView(historyStore: HistoryStore())
}
