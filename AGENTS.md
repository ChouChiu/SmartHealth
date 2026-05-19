# AGENTS.md — SmartHealth

Primary project: **SmartHealth** (iOS health tracker). `SportKitNoModify/` is a separate experimental app — ignore unless explicitly asked.

## Build

```bash
xcodebuild build -project SmartHealth/SmartHealth.xcodeproj -scheme SmartHealth
```

Targets iOS 17+ (uses `@Observable`). SPM dependency: `iREdFramework` (BLE device singleton).

## Architecture

- **`@Observable` (iOS 17+)** centralized state via `Core/AppState.swift` — tabs, user profile, greetings. Injected as `.environment(appState)`.
- **`@StateObject` / `@EnvironmentObject`** for ObservableObject managers: `BLEManager`, `HistoryStore`, `LocationManager`, `WeatherManager`. All injected at `SmartHealthApp.swift` root.
- **Persistence**: `HistoryStore` → `UserDefaults` (keys: `SmartHealth.*`). Records are `Codable`, sorted newest-first.
- **BLE**: `BLEManager` wraps `iREdBluetooth.shared` singleton. Device data via `iredDeviceData.heartRateData` / `.scaleData`.

## Design System

Three reusable components only — everything else uses native SwiftUI:
- `StatusPill` — icon + label capsule (connection status)
- `MeasureCard` — large measurement display (material bg, 28pt corners, adaptive sizing)
- `SummaryCard` — small stat card

Visual: `.regularMaterial` backgrounds, `RoundedRectangle(28)`, `StrokeStyle` borders. Semantic colors: `.heartRate` (red), `.scale` (blue), `.brand` (blue). All system colors — no custom hex.

Typography: SF Pro only. `.appMeasurement()` for fixed-size monospaced digits (prevents layout shift). Dynamic Type supported.

## Conventions

- **Language**: Traditional Chinese (繁體中文) for all UI strings
- **Naming**: `*View.swift`, `*Manager.swift`, `*Store.swift`. MARK comments for sections.
- **Patterns**: `@ViewBuilder` for conditional content, `#Preview` macro, `.sheet()` for modals, `Bindable()` for `@Observable` binding to TabView
- **Models**: `Codable` + `Identifiable` structs in `Models.swift`

## Key Files

| File | Purpose |
|------|---------|
| `SmartHealthApp.swift` | Entry point, dependency injection |
| `Core/AppState.swift` | `@Observable` state, tabs, greetings |
| `Models.swift` | `UserProfile`, `HeartRateRecord`, `ScaleRecord` |
| `HistoryStore.swift` | UserDefaults CRUD |
| `DesignSystem/AppComponents.swift` | 3 reusable components |
| `DesignSystem/AppColors.swift` | Semantic color extensions |
| `DesignSystem/AppTypography.swift` | Font styles |
| `BLEManager.swift` | iREdFramework wrapper |
| `WeatherManager.swift` | Open-Meteo API |

CI: `.github/workflows/build.yml` — triggers on push/PR, builds `SmartHealth` scheme.
