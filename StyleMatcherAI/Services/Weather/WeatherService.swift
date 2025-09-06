import Foundation
import CoreLocation

protocol WeatherServiceProtocol {
    func getCurrentWeather(for location: CLLocation) async throws -> CurrentWeather
    func getForecast(for location: CLLocation, days: Int) async throws -> WeatherForecast
    func getWeatherByCity(_ city: String) async throws -> CurrentWeather
    func getForecastByCity(_ city: String, days: Int) async throws -> WeatherForecast
}

final class WeatherService: WeatherServiceProtocol {
    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let session = URLSession.shared
    private let cache = WeatherCache()
    
    init(apiKey: String = APIKeys.Weather.openWeatherMapApiKey) {
        self.apiKey = apiKey
    }
    
    func getCurrentWeather(for location: CLLocation) async throws -> CurrentWeather {
        let cacheKey = "current_\(location.coordinate.latitude)_\(location.coordinate.longitude)"
        
        if let cachedWeather = cache.getCachedWeather(for: cacheKey) {
            return cachedWeather
        }
        
        let urlString = "\(baseURL)/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw WeatherError.apiError(httpResponse.statusCode)
            }
            
            let weatherResponse = try JSONDecoder().decode(OpenWeatherMapCurrentResponse.self, from: data)
            let currentWeather = weatherResponse.toCurrentWeather()
            
            cache.cacheWeather(currentWeather, for: cacheKey)
            return currentWeather
            
        } catch {
            if error is WeatherError {
                throw error
            }
            throw WeatherError.networkError(error.localizedDescription)
        }
    }
    
    func getForecast(for location: CLLocation, days: Int = 5) async throws -> WeatherForecast {
        let cacheKey = "forecast_\(location.coordinate.latitude)_\(location.coordinate.longitude)_\(days)"
        
        if let cachedForecast = cache.getCachedForecast(for: cacheKey) {
            return cachedForecast
        }
        
        let urlString = "\(baseURL)/forecast?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(apiKey)&units=metric&cnt=\(days * 8)"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw WeatherError.apiError(httpResponse.statusCode)
            }
            
            let forecastResponse = try JSONDecoder().decode(OpenWeatherMapForecastResponse.self, from: data)
            let forecast = forecastResponse.toWeatherForecast()
            
            cache.cacheForecast(forecast, for: cacheKey)
            return forecast
            
        } catch {
            if error is WeatherError {
                throw error
            }
            throw WeatherError.networkError(error.localizedDescription)
        }
    }
    
    func getWeatherByCity(_ city: String) async throws -> CurrentWeather {
        let cacheKey = "current_city_\(city)"
        
        if let cachedWeather = cache.getCachedWeather(for: cacheKey) {
            return cachedWeather
        }
        
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "\(baseURL)/weather?q=\(encodedCity)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw WeatherError.apiError(httpResponse.statusCode)
            }
            
            let weatherResponse = try JSONDecoder().decode(OpenWeatherMapCurrentResponse.self, from: data)
            let currentWeather = weatherResponse.toCurrentWeather()
            
            cache.cacheWeather(currentWeather, for: cacheKey)
            return currentWeather
            
        } catch {
            if error is WeatherError {
                throw error
            }
            throw WeatherError.networkError(error.localizedDescription)
        }
    }
    
    func getForecastByCity(_ city: String, days: Int = 5) async throws -> WeatherForecast {
        let cacheKey = "forecast_city_\(city)_\(days)"
        
        if let cachedForecast = cache.getCachedForecast(for: cacheKey) {
            return cachedForecast
        }
        
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "\(baseURL)/forecast?q=\(encodedCity)&appid=\(apiKey)&units=metric&cnt=\(days * 8)"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw WeatherError.apiError(httpResponse.statusCode)
            }
            
            let forecastResponse = try JSONDecoder().decode(OpenWeatherMapForecastResponse.self, from: data)
            let forecast = forecastResponse.toWeatherForecast()
            
            cache.cacheForecast(forecast, for: cacheKey)
            return forecast
            
        } catch {
            if error is WeatherError {
                throw error
            }
            throw WeatherError.networkError(error.localizedDescription)
        }
    }
}

struct CurrentWeather: Codable, Equatable {
    let location: String
    let country: String
    let temperature: Double
    let feelsLike: Double
    let minTemperature: Double
    let maxTemperature: Double
    let humidity: Int
    let windSpeed: Double
    let windDirection: Int
    let pressure: Int
    let visibility: Int
    let uvIndex: Double?
    let condition: WeatherCondition
    let description: String
    let icon: String
    let timestamp: Date
    let sunrise: Date?
    let sunset: Date?
    
    var temperatureRange: ClosedRange<Double> {
        return minTemperature...maxTemperature
    }
    
    var isHot: Bool { temperature > 25 }
    var isCold: Bool { temperature < 10 }
    var isHumid: Bool { humidity > 70 }
    var isWindy: Bool { windSpeed > 15 }
    
    var outfitConditions: [WeatherCondition] {
        var conditions: [WeatherCondition] = [condition]
        
        if isHot { conditions.append(.hot) }
        if isCold { conditions.append(.cold) }
        if isHumid { conditions.append(.humid) }
        if isWindy { conditions.append(.windy) }
        
        return conditions
    }
}

struct WeatherForecast: Codable {
    let location: String
    let country: String
    let forecasts: [DailyForecast]
    let timestamp: Date
    
    var next5Days: [DailyForecast] {
        return Array(forecasts.prefix(5))
    }
}

struct DailyForecast: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let minTemperature: Double
    let maxTemperature: Double
    let condition: WeatherCondition
    let description: String
    let icon: String
    let humidity: Int
    let windSpeed: Double
    let precipitationChance: Double
    
    enum CodingKeys: String, CodingKey {
        case date, minTemperature, maxTemperature, condition, description, icon, humidity, windSpeed, precipitationChance
    }
    
    var outfitConditions: [WeatherCondition] {
        var conditions: [WeatherCondition] = [condition]
        
        if maxTemperature > 25 { conditions.append(.hot) }
        if minTemperature < 10 { conditions.append(.cold) }
        if humidity > 70 { conditions.append(.humid) }
        if windSpeed > 15 { conditions.append(.windy) }
        if precipitationChance > 50 {
            switch condition {
            case .snowy: conditions.append(.snowy)
            default: conditions.append(.rainy)
            }
        }
        
        return conditions
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

enum WeatherError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(String)
    case apiError(Int)
    case parsingError
    case locationNotFound
    case apiKeyInvalid
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid weather API URL"
        case .invalidResponse:
            return "Invalid response from weather service"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let code):
            return "Weather API error: \(code)"
        case .parsingError:
            return "Failed to parse weather data"
        case .locationNotFound:
            return "Location not found"
        case .apiKeyInvalid:
            return "Invalid API key for weather service"
        }
    }
}

private struct OpenWeatherMapCurrentResponse: Codable {
    let coord: Coordinates
    let weather: [WeatherInfo]
    let main: MainInfo
    let visibility: Int
    let wind: WindInfo
    let sys: SystemInfo
    let name: String
    let dt: TimeInterval
    
    struct Coordinates: Codable {
        let lon: Double
        let lat: Double
    }
    
    struct WeatherInfo: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct MainInfo: Codable {
        let temp: Double
        let feelsLike: Double
        let tempMin: Double
        let tempMax: Double
        let pressure: Int
        let humidity: Int
        
        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case tempMin = "temp_min"
            case tempMax = "temp_max"
            case pressure, humidity
        }
    }
    
    struct WindInfo: Codable {
        let speed: Double
        let deg: Int?
    }
    
    struct SystemInfo: Codable {
        let country: String
        let sunrise: TimeInterval?
        let sunset: TimeInterval?
    }
    
    func toCurrentWeather() -> CurrentWeather {
        let weatherInfo = weather.first!
        let condition = WeatherCondition.fromOpenWeatherMapId(weatherInfo.id)
        
        return CurrentWeather(
            location: name,
            country: sys.country,
            temperature: main.temp,
            feelsLike: main.feelsLike,
            minTemperature: main.tempMin,
            maxTemperature: main.tempMax,
            humidity: main.humidity,
            windSpeed: wind.speed,
            windDirection: wind.deg ?? 0,
            pressure: main.pressure,
            visibility: visibility,
            uvIndex: nil,
            condition: condition,
            description: weatherInfo.description,
            icon: weatherInfo.icon,
            timestamp: Date(timeIntervalSince1970: dt),
            sunrise: sys.sunrise.map { Date(timeIntervalSince1970: $0) },
            sunset: sys.sunset.map { Date(timeIntervalSince1970: $0) }
        )
    }
}

private struct OpenWeatherMapForecastResponse: Codable {
    let city: CityInfo
    let list: [ForecastItem]
    
    struct CityInfo: Codable {
        let name: String
        let country: String
    }
    
    struct ForecastItem: Codable {
        let dt: TimeInterval
        let main: MainInfo
        let weather: [WeatherInfo]
        let wind: WindInfo
        let pop: Double
        
        struct MainInfo: Codable {
            let temp: Double
            let tempMin: Double
            let tempMax: Double
            let humidity: Int
            
            enum CodingKeys: String, CodingKey {
                case temp
                case tempMin = "temp_min"
                case tempMax = "temp_max"
                case humidity
            }
        }
        
        struct WeatherInfo: Codable {
            let id: Int
            let main: String
            let description: String
            let icon: String
        }
        
        struct WindInfo: Codable {
            let speed: Double
        }
    }
    
    func toWeatherForecast() -> WeatherForecast {
        let groupedByDay = Dictionary(grouping: list) { item in
            Calendar.current.startOfDay(for: Date(timeIntervalSince1970: item.dt))
        }
        
        let dailyForecasts = groupedByDay.compactMap { (date, items) -> DailyForecast? in
            guard let firstItem = items.first else { return nil }
            
            let minTemp = items.map { $0.main.tempMin }.min() ?? firstItem.main.tempMin
            let maxTemp = items.map { $0.main.tempMax }.max() ?? firstItem.main.tempMax
            let avgHumidity = Int(items.map { Double($0.main.humidity) }.reduce(0, +) / Double(items.count))
            let avgWindSpeed = items.map { $0.wind.speed }.reduce(0, +) / Double(items.count)
            let maxPrecipitation = items.map { $0.pop }.max() ?? 0
            
            let weatherInfo = firstItem.weather.first!
            let condition = WeatherCondition.fromOpenWeatherMapId(weatherInfo.id)
            
            return DailyForecast(
                date: date,
                minTemperature: minTemp,
                maxTemperature: maxTemp,
                condition: condition,
                description: weatherInfo.description,
                icon: weatherInfo.icon,
                humidity: avgHumidity,
                windSpeed: avgWindSpeed,
                precipitationChance: maxPrecipitation * 100
            )
        }.sorted { $0.date < $1.date }
        
        return WeatherForecast(
            location: city.name,
            country: city.country,
            forecasts: dailyForecasts,
            timestamp: Date()
        )
    }
}

extension WeatherCondition {
    static func fromOpenWeatherMapId(_ id: Int) -> WeatherCondition {
        switch id {
        case 200...299: return .rainy // Thunderstorms
        case 300...399: return .rainy // Drizzle
        case 500...599: return .rainy // Rain
        case 600...699: return .snowy // Snow
        case 700...799: return .cloudy // Atmosphere (fog, haze, etc.)
        case 800: return .sunny // Clear sky
        case 801...809: return .cloudy // Clouds
        default: return .cloudy
        }
    }
}

private class WeatherCache {
    private var weatherCache: [String: (weather: CurrentWeather, timestamp: Date)] = [:]
    private var forecastCache: [String: (forecast: WeatherForecast, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 10 * 60 // 10 minutes
    
    func getCachedWeather(for key: String) -> CurrentWeather? {
        guard let cached = weatherCache[key] else { return nil }
        
        if Date().timeIntervalSince(cached.timestamp) > cacheTimeout {
            weatherCache.removeValue(forKey: key)
            return nil
        }
        
        return cached.weather
    }
    
    func cacheWeather(_ weather: CurrentWeather, for key: String) {
        weatherCache[key] = (weather: weather, timestamp: Date())
    }
    
    func getCachedForecast(for key: String) -> WeatherForecast? {
        guard let cached = forecastCache[key] else { return nil }
        
        if Date().timeIntervalSince(cached.timestamp) > cacheTimeout {
            forecastCache.removeValue(forKey: key)
            return nil
        }
        
        return cached.forecast
    }
    
    func cacheForecast(_ forecast: WeatherForecast, for key: String) {
        forecastCache[key] = (forecast: forecast, timestamp: Date())
    }
}