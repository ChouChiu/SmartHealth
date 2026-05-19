//
//  WeatherManager.swift
//  SmartHealth
//
//  Fetches current weather via Open-Meteo API (no entitlement required).
//

import Foundation
import CoreLocation
#if canImport(MapKit)
import MapKit
#endif

@Observable
final class WeatherManager {
    var temperature: String?
    var condition: String?
    var cityName: String?
    var symbolName: String = "cloud.fill"
    var isLoading = false

    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        defer { isLoading = false }

        // Reverse geocode for city name (Traditional Chinese)
        let locale = Locale(identifier: "zh-Hant")
        if #available(iOS 26.0, *) {
            if let request = MKReverseGeocodingRequest(location: location) {
                request.preferredLocale = locale
                if let mapItems = try? await request.mapItems,
                   let address = mapItems.first?.address {
                    cityName = address.shortAddress ?? address.fullAddress
                }
            }
        } else {
            if let placemark = try? await CLGeocoder().reverseGeocodeLocation(location, preferredLocale: locale).first {
                cityName = placemark.locality ?? placemark.administrativeArea
            }
        }

        // Fetch weather from Open-Meteo (free, no API key needed)
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code"

        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let tempCelsius = Int(result.current.temperature2m)
            temperature = "\(tempCelsius)°C"
            let code = result.current.weatherCode
            condition = Self.weatherConditionText(for: code)
            symbolName = Self.weatherSymbol(for: code)
        } catch {
            temperature = nil
            condition = nil
            symbolName = "cloud.fill"
        }
    }

    // MARK: - Weather code mapping (WMO codes)

    private static func weatherConditionText(for code: Int) -> String {
        switch code {
        case 0: return "晴天"
        case 1: return "大致晴朗"
        case 2: return "局部多雲"
        case 3: return "多雲"
        case 45, 48: return "霧"
        case 51, 53, 55: return "毛毛雨"
        case 56, 57: return "凍毛毛雨"
        case 61, 63, 65: return "雨"
        case 66, 67: return "凍雨"
        case 71, 73, 75: return "雪"
        case 77: return "雪粒"
        case 80, 81, 82: return "陣雨"
        case 85, 86: return "陣雪"
        case 95: return "雷暴"
        case 96, 99: return "雷暴伴有冰雹"
        default: return "未知"
        }
    }

    private static func weatherSymbol(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1: return "sun.min.fill"
        case 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82: return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.fill"
        default: return "cloud.fill"
        }
    }
}

// MARK: - Open-Meteo Response Model

private struct OpenMeteoResponse: Codable {
    let current: CurrentWeather

    struct CurrentWeather: Codable {
        let temperature2m: Double
        let weatherCode: Int

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
        }
    }
}
