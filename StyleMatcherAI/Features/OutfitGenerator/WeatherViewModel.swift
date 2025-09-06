import Foundation
import CoreLocation
import SwiftUI

@MainActor
class WeatherViewModel: ObservableObject {
    
    @Published var currentWeather: CurrentWeather?
    @Published var forecast: WeatherForecast?
    @Published var isLoadingWeather = false
    @Published var weatherError: String?
    @Published var showWeatherError = false
    @Published var lastLocation: CLLocation?
    @Published var selectedCity: String = ""
    
    private let weatherService: WeatherServiceProtocol
    private var weatherUpdateTimer: Timer?
    
    init(weatherService: WeatherServiceProtocol = WeatherService()) {
        self.weatherService = weatherService
        startWeatherUpdateTimer()
    }
    
    deinit {
        weatherUpdateTimer?.invalidate()
    }
    
    func updateWeatherForLocation(_ location: CLLocation) async {
        guard location != lastLocation else { return }
        
        lastLocation = location
        isLoadingWeather = true
        weatherError = nil
        
        do {
            async let currentWeatherTask = weatherService.getCurrentWeather(for: location)
            async let forecastTask = weatherService.getForecast(for: location, days: 5)
            
            let (weather, weatherForecast) = try await (currentWeatherTask, forecastTask)
            
            currentWeather = weather
            forecast = weatherForecast
            
        } catch {
            handleWeatherError(error)
        }
        
        isLoadingWeather = false
    }
    
    func updateWeatherForCity(_ city: String) async {
        guard !city.isEmpty, city != selectedCity else { return }
        
        selectedCity = city
        isLoadingWeather = true
        weatherError = nil
        
        do {
            async let currentWeatherTask = weatherService.getWeatherByCity(city)
            async let forecastTask = weatherService.getForecastByCity(city, days: 5)
            
            let (weather, weatherForecast) = try await (currentWeatherTask, forecastTask)
            
            currentWeather = weather
            forecast = weatherForecast
            
        } catch {
            handleWeatherError(error)
        }
        
        isLoadingWeather = false
    }
    
    func refreshWeather() async {
        if !selectedCity.isEmpty {
            await updateWeatherForCity(selectedCity)
        } else if let location = lastLocation {
            await updateWeatherForLocation(location)
        }
    }
    
    private func handleWeatherError(_ error: Error) {
        if let weatherError = error as? WeatherError {
            self.weatherError = weatherError.localizedDescription
        } else {
            self.weatherError = "Failed to get weather information: \(error.localizedDescription)"
        }
        showWeatherError = true
    }
    
    private func startWeatherUpdateTimer() {
        // Update weather every 30 minutes
        weatherUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshWeather()
            }
        }
    }
    
    func clearWeatherError() {
        weatherError = nil
        showWeatherError = false
    }
    
    var hasWeatherData: Bool {
        return currentWeather != nil
    }
    
    var currentTemperatureDisplay: String {
        guard let weather = currentWeather else { return "--°" }
        return "\(Int(weather.temperature.rounded()))°C"
    }
    
    var temperatureRangeDisplay: String {
        guard let weather = currentWeather else { return "--° / --°" }
        return "\(Int(weather.minTemperature.rounded()))° / \(Int(weather.maxTemperature.rounded()))°"
    }
    
    var weatherConditionDisplay: String {
        return currentWeather?.description.capitalized ?? "Unknown"
    }
    
    var weatherIcon: String {
        guard let weather = currentWeather else { return "questionmark" }
        return weather.condition.icon
    }
    
    var recommendedClothing: [String] {
        guard let weather = currentWeather else { return [] }
        
        let tempCategory = getTemperatureCategory(from: weather.temperature)
        var recommendations = tempCategory.recommendations
        
        // Add condition-specific recommendations
        if weather.outfitConditions.contains(.rainy) {
            recommendations.append("Waterproof jacket")
            recommendations.append("Water-resistant shoes")
        }
        
        if weather.outfitConditions.contains(.windy) {
            recommendations.append("Secure accessories")
            recommendations.append("Fitted clothing")
        }
        
        if weather.outfitConditions.contains(.sunny) {
            recommendations.append("Sun protection")
            recommendations.append("Light colors")
        }
        
        return recommendations
    }
    
    private func getTemperatureCategory(from temperature: Double) -> TemperatureCategory {
        switch temperature {
        case ..<0:
            return .freezing
        case 0..<10:
            return .cold
        case 10..<18:
            return .cool
        case 18..<25:
            return .mild
        case 25..<30:
            return .warm
        default:
            return .hot
        }
    }
}

extension WeatherViewModel {
    func getOutfitConditionsForGeneration() -> [WeatherCondition] {
        return currentWeather?.outfitConditions ?? []
    }
    
    func getCurrentSeason() -> Season {
        return Season.current
    }
    
    func shouldShowWeatherWarning() -> Bool {
        guard let weather = currentWeather else { return false }
        
        return weather.temperature < 0 || 
               weather.temperature > 35 ||
               weather.outfitConditions.contains(.rainy) ||
               weather.outfitConditions.contains(.snowy)
    }
    
    func getWeatherWarningMessage() -> String? {
        guard let weather = currentWeather else { return nil }
        
        if weather.temperature < 0 {
            return "Very cold weather - dress warmly!"
        } else if weather.temperature > 35 {
            return "Very hot weather - stay cool and hydrated!"
        } else if weather.outfitConditions.contains(.rainy) {
            return "Rain expected - consider waterproof clothing"
        } else if weather.outfitConditions.contains(.snowy) {
            return "Snow expected - dress for cold and wet conditions"
        }
        
        return nil
    }
}