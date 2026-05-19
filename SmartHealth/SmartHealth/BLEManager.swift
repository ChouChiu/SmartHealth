//
//  BLEManager.swift
//  SmartHealth
//
//  Shared BLE state — wraps iREdBluetooth singleton for use across all views.
//

import SwiftUI
import Combine
import iREdFramework

/// Central BLE manager that holds the iREdBluetooth singleton.
/// Inject via `.environmentObject()` at the App level.
final class BLEManager: ObservableObject {
    let ble: iREdBluetooth

    init() {
        self.ble = iREdBluetooth.shared
    }
}
