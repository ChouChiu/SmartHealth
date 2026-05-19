# SmartHealth — 智慧健康管理

SmartHealth 是一款 iOS 原生健康監測 App，透過藍牙連接心率帶與智慧體重計，持續記錄生理數據，並整合在地天氣與歷史紀錄，讓日常健康追蹤更完整。

## 核心功能

- **心率監測**：配對 BLE 心率帶，即時顯示心率數值；斷線後自動保存本次量測的平均、最高與最低心率。
- **體重監測**：連接 BLE 智慧體重計，追蹤體重、BMI 與體脂率，數值穩定後自動記錄。
- **歷史記錄**：瀏覽心率與體重量測歷史，資料依最新優先排序並儲存在裝置本機。
- **天氣資訊**：透過 Open-Meteo 免費 API 取得當前氣溫與天氣狀況，顯示於主畫面。
- **首次設定**：初次啟動時引導輸入姓氏、性別、身高與出生年份，建立個人化體驗。
- **原生體驗**：以 SwiftUI 建構，使用 iOS 原生材質、SF Symbols 與動態字級，並自動適應深色 / 淺色模式。

## 技術概覽

- **語言**：Swift，iOS 17+
- **UI / 狀態**：SwiftUI + Observation（`@Observable`）
- **藍牙**：iREdFramework SPM 套件，封裝 `iREdBluetooth`
- **天氣**：Open-Meteo API，無需 API 金鑰
- **儲存**：`UserDefaults` + `Codable` 模型

## 專案結構

```
SmartHealth/
├── SmartHealthApp.swift       # App 入口與依賴注入
├── Core/AppState.swift        # 應用狀態、分頁與問候語
├── DesignSystem/              # 顏色、元件、字體樣式
├── Views/                     # 主畫面與個人資料頁
├── BLEManager.swift           # BLE 裝置連線與資料封裝
├── HeartRateView.swift        # 心率監測
├── ScaleView.swift            # 體重監測
├── HeartRateHistoryView.swift # 心率歷史
├── ScaleHistoryView.swift     # 體重歷史
├── CombinedHistoryView.swift  # 歷史整合檢視
├── OnboardingView.swift       # 首次使用引導
├── HistoryStore.swift         # 本機歷史資料儲存
├── LocationManager.swift      # 位置權限與定位
├── WeatherManager.swift       # 天氣查詢與圖示對應
├── Models.swift               # 資料模型
├── Info.plist                 # 藍牙與定位權限描述
└── Assets.xcassets/           # App 圖示與色彩資源
```

## 系統需求

- Xcode 26 或相容版本
- iOS 17.0+ 部署目標
- Swift 6
- 藍牙功能需在實機上測試，模擬器不支援藍牙

## 快速開始

```bash
git clone <repo-url>
cd SmartHealth

xcodebuild -resolvePackageDependencies \
  -project SmartHealth/SmartHealth.xcodeproj \
  -scheme SmartHealth

open SmartHealth/SmartHealth.xcodeproj
```

在 Xcode 選擇裝置或模擬器後，按下 ⌘R 即可執行。

### 命令列建置

```bash
xcodebuild build \
  -project SmartHealth/SmartHealth.xcodeproj \
  -scheme SmartHealth

xcodebuild build \
  -project SmartHealth/SmartHealth.xcodeproj \
  -scheme SmartHealth \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO
```

## 權限設定

正式發佈前，請確認 `Info.plist` 已加入以下用途說明：

- `NSBluetoothAlwaysUsageDescription`：用於連接心率帶與智慧體重計
- `NSLocationWhenInUseUsageDescription`：用於取得當地天氣資訊

## 依賴套件

- [iREdFramework](https://github.com/ireadyou/ired_bluetooth_ios_sdk)：BLE 裝置抽象層，負責心率帶與智慧體重計整合

依賴透過 Xcode 的 SPM 整合解析，無需額外的 `Package.swift`。

## 持續整合

GitHub Actions 位於 [`.github/workflows/build.yml`](.github/workflows/build.yml)：

- push、PR 與手動觸發皆會執行
- 快取 SPM 套件以縮短建置時間
- 以 `generic/platform=iOS` 建置，並關閉簽署
- 產出 `.ipa` 並上傳為構件

## 授權

Apache 2.0，詳見 [LICENSE](LICENSE)。
