//
//  NotificationManager.swift
//  SmartHealth
//
//  Local notification management — request permission, send health alerts.
//

import UserNotifications
import Observation

@Observable
final class NotificationManager {
    var isAuthorized = false

    // MARK: - Permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                self.isAuthorized = granted
            }
        }
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

    // MARK: - Private

    private func send(title: String, body: String, category: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category

        let request = UNNotificationRequest(
            identifier: "\(category)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil  // 立即發送
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func exerciseSuggestion(forBMI bmi: Double) -> String {
        switch bmi {
        case ..<25: return "繼續保持，您做得很好！"
        case 25..<28: return "每天到公園散步 20 分鐘，或在家做做伸展操，對身體很好喔。"
        case 28..<30: return "每天健走 30 分鐘，也可以試試太極拳或園藝活動，輕鬆動一動。"
        default:      return "每天出門散步，打打太極拳，循序漸進就好。建議和醫生聊聊，一起訂個適合您的活動計畫。"
        }
    }
}
