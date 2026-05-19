# REASONIX.md — SmartHealth

## Stack

- **Language**: Swift (iOS 17+ target)
- **Framework**: SwiftUI + Observation (`@Observable`)
- **BLE**: `iREdFramework` SPM package (wraps `iREdBluetooth.shared` singleton)
- **Weather**: Open-Meteo API (free, no API key)
- **Persistence**: `UserDefaults` (keys prefixed `SmartHealth.`)

## Layout

| Dir/File | Purpose |
|----------|---------|
| `SmartHealth/SmartHealth/` | Main app source |
| `…/Core/AppState.swift` | `@Observable` state, tab enum, greetings |
| `…/DesignSystem/` | `AppColors`, `AppTypography`, `AppComponents` (3 reusable views) |
| `…/Views/` | `MainView.swift`, `ProfileView.swift` |
| `…/*View.swift` | Feature views: HeartRate, Scale, Onboarding, History |
| `…/*Manager.swift` | `BLEManager`, `LocationManager`, `WeatherManager` |
| `…/Models.swift` | `UserProfile`, `HeartRateRecord`, `ScaleRecord` (Codable+Identifiable) |
| `…/HistoryStore.swift` | ObservableObject CRUD → UserDefaults (`SmartHealth.*` keys) |
| `…/SmartHealthApp.swift` | `@main` entry point, DI root |
| `SportKitNoModify/` | **Separate experimental app — ignore unless asked** |
| `.github/workflows/build.yml` | CI: builds `SmartHealth` scheme on push/PR |

## Commands

```bash
# Build
xcodebuild build -project SmartHealth/SmartHealth.xcodeproj -scheme SmartHealth

# Build for device (CI, no signing)
xcodebuild build -project SmartHealth/SmartHealth.xcodeproj -scheme SmartHealth \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO

# Resolve SPM deps
xcodebuild -resolvePackageDependencies -project SmartHealth/SmartHealth.xcodeproj -scheme SmartHealth
```

No test suite, lint, or format config in the repo.

## Conventions

- **UI strings**: Traditional Chinese (繁體中文) throughout
- **State**: `@Observable` (iOS 17+) for `AppState`, `LocationManager`, `WeatherManager`; `@StateObject`/`@EnvironmentObject` for `BLEManager`, `HistoryStore`
- **3 reusable components**: `StatusPill`, `MeasureCard`, `SummaryCard` — everything else native SwiftUI
- **Design**: `.regularMaterial`, `RoundedRectangle(28)`, `StrokeStyle` borders; semantic `AppAccent` enum (`.heartRate`→red, `.scale`/`.brand`→blue); SF Pro only, Dynamic Type
- **Models**: `Codable`+`Identifiable` structs; records sorted newest-first
- **Code style**: `// MARK: -` dividers; `#Preview` macro; `@ViewBuilder` for conditionals; `.sheet()` for modals; `Bindable()` for `@Observable`→`TabView` binding
- **DI**: managers created as `@State` in `SmartHealthApp`, injected via `.environment()`/`.environmentObject()`

## Watch out for

- `BLEManager` is a thin wrapper — views often access `iREdBluetooth.shared` directly via `@StateObject`
- `WeatherManager` has an `#available(iOS 26.0, *)` code path alongside a `CLGeocoder` fallback — both must be kept in sync
- `SportKitNoModify/` is a separate project; do not modify or reference it unless explicitly asked
- No `Package.swift` — dependencies are resolved via Xcode SPM integration in the `.xcodeproj`
