//
//  NotificationManager.swift
//  SmartHealth
//
//  Local notification management — request permission, send health alerts.
//

import UserNotifications
import Observation
import UIKit

@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    var isAuthorized = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Permission

    /// 請求通知權限。若使用者之前已拒絕，則引導至系統設定。
    func requestPermission() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined:
                // 首次請求 — 會彈出系統對話框
                do {
                    let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                    await MainActor.run { self.isAuthorized = granted }
                } catch {
                    await MainActor.run { self.isAuthorized = false }
                }
            case .denied:
                // 已拒絕 — 只能引導去設定，更新狀態顯示
                await MainActor.run { self.isAuthorized = false }
            case .authorized, .provisional, .ephemeral:
                await MainActor.run { self.isAuthorized = true }
            @unknown default:
                break
            }
        }
    }

    /// 更新授權狀態（供外部呼叫，例如從設定頁面返回後）
    func refreshAuthorizationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.isAuthorized = (settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                    || settings.authorizationStatus == .ephemeral)
            }
        }
    }

    /// 打開 iOS 系統設定 → SmartHealth → 通知
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Send

    /// 心率過高通知
    func notifyHeartRateHigh(bpm: Int) {
        send(
            title: "💓 心跳偏快，請休息一下",
            body: "您的心跳目前每分鐘 \(bpm) 下，比平時快了一些。找個地方坐下來，放鬆心情，慢慢深呼吸，很快就會平穩下來。",
            category: "heartRate"
        )
    }

    /// 心率過低通知
    func notifyHeartRateLow(bpm: Int) {
        send(
            title: "💓 心跳偏慢，請留意身體",
            body: "您的心跳目前每分鐘 \(bpm) 下，比平時慢了一些。如果感覺頭暈或沒力氣，請先坐下休息，必要時聯絡家人或醫生。",
            category: "heartRate"
        )
    }

    /// 體重/BMI 過高 — 運動提醒
    func notifyWeightHigh(weight: Double, bmi: Double) {
        let bmiStr = String(format: "%.1f", bmi)
        let weightStr = String(format: "%.1f", weight)
        let suggestion = exerciseSuggestion(forBMI: bmi)
        send(
            title: "🚶 今天出去走走吧",
            body: "您目前體重 \(weightStr) 公斤，BMI 為 \(bmiStr)。\(suggestion)",
            category: "weight"
        )
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// 讓通知在 App 前景時也能彈出橫幅（否則只會靜默存入通知中心）
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - Private

    private func send(title: String, body: String, category: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category

        // 用極短延遲 trigger 取代 nil，確保立即發送行為一致
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(category)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Task { @MainActor in
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    /// 最後一次發送通知的錯誤訊息（nil 表示成功），供除錯面板顯示
    var lastError: String?

    private func exerciseSuggestion(forBMI bmi: Double) -> String {
        switch bmi {
        case ..<25: return "繼續保持，您做得很好！"
        case 25..<28: return "每天到公園散步 20 分鐘，或在家做做伸展操，對身體很好喔。"
        case 28..<30: return "每天健走 30 分鐘，也可以試試太極拳或園藝活動，輕鬆動一動。"
        default:      return "每天出門散步，打打太極拳，循序漸進就好。建議和醫生聊聊，一起訂個適合您的活動計畫。"
        }
    }
}
