import Foundation
import SwiftUI

@MainActor
class ForecastOutfitPlannerViewModel: ObservableObject {
    
    @Published var forecastPlans: [Date: [OutfitWithScore]] = [:]
    @Published var isGeneratingPlans = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let wardrobeRepository: WardrobeRepositoryProtocol
    private let outfitRepository: OutfitRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private var currentUser: AppUser?
    
    init(
        wardrobeRepository: WardrobeRepositoryProtocol = WardrobeRepository(),
        outfitRepository: OutfitRepositoryProtocol = OutfitRepository(),
        userRepository: UserRepositoryProtocol = UserRepository()
    ) {
        self.wardrobeRepository = wardrobeRepository
        self.outfitRepository = outfitRepository
        self.userRepository = userRepository
        
        Task {
            await loadCurrentUser()
        }
    }
    
    private func loadCurrentUser() async {
        do {
            self.currentUser = try await userRepository.getCurrentUser()
        } catch {
            handleError(error)
        }
    }
    
    func generateForecastPlans(forecast: WeatherForecast) async {
        guard let userId = currentUser?.id else {
            handleError(ForecastPlannerError.userNotFound)
            return
        }
        
        isGeneratingPlans = true
        defer { isGeneratingPlans = false }
        
        do {
            let wardrobeItems = try await wardrobeRepository.getItems(for: userId)
            guard !wardrobeItems.isEmpty else {
                handleError(ForecastPlannerError.emptyWardrobe)
                return
            }
            
            let userPreferences = currentUser?.preferences
            
            // Generate plans for each day in the forecast
            for dailyForecast in forecast.next5Days {
                let dayPlans = await generateOutfitsForDay(
                    dailyForecast: dailyForecast,
                    wardrobeItems: wardrobeItems,
                    userPreferences: userPreferences
                )
                
                forecastPlans[Calendar.current.startOfDay(for: dailyForecast.date)] = dayPlans
            }
            
        } catch {
            handleError(error)
        }
    }
    
    private func generateOutfitsForDay(
        dailyForecast: DailyForecast,
        wardrobeItems: [WardrobeItem],
        userPreferences: UserPreferences?
    ) async -> [OutfitWithScore] {
        
        // Filter items appropriate for the forecast
        let appropriateItems = WeatherClothingFilter.filterItemsForForecast(
            items: wardrobeItems,
            forecast: dailyForecast,
            season: Season.current
        )
        
        guard !appropriateItems.isEmpty else { return [] }
        
        // Get weather-based recommendations
        let mockWeather = createMockWeather(from: dailyForecast)
        let recommendedItems = WeatherClothingFilter.getRecommendedItemsForWeather(
            items: appropriateItems,
            weather: mockWeather,
            season: Season.current
        )
        
        // Generate outfit combinations
        let outfits = generateOutfitCombinations(
            from: recommendedItems,
            forecast: dailyForecast
        )
        
        // Score and rank outfits
        let scoredOutfits = outfits.map { outfit in
            let score = OutfitScoringEngine.scoreOutfit(
                items: outfit.items,
                targetFormality: outfit.formality,
                weatherConditions: dailyForecast.outfitConditions,
                userPreferences: userPreferences,
                currentSeason: Season.current
            )
            return OutfitWithScore(outfit: outfit, score: score)
        }
        
        // Return top 5 suggestions
        return Array(scoredOutfits.sorted { $0.score.total > $1.score.total }.prefix(5))
    }
    
    private func createMockWeather(from forecast: DailyForecast) -> CurrentWeather {
        let avgTemp = (forecast.minTemperature + forecast.maxTemperature) / 2
        
        return CurrentWeather(
            location: "",
            country: "",
            temperature: avgTemp,
            feelsLike: avgTemp,
            minTemperature: forecast.minTemperature,
            maxTemperature: forecast.maxTemperature,
            humidity: forecast.humidity,
            windSpeed: forecast.windSpeed,
            windDirection: 0,
            pressure: 1013,
            visibility: 10000,
            uvIndex: nil,
            condition: forecast.condition,
            description: forecast.description,
            icon: forecast.icon,
            timestamp: forecast.date,
            sunrise: nil,
            sunset: nil
        )
    }
    
    private func generateOutfitCombinations(
        from recommendedItems: RecommendedItems,
        forecast: DailyForecast
    ) -> [Outfit] {
        
        guard let userId = currentUser?.id else { return [] }
        
        var outfits: [Outfit] = []
        let maxOutfits = 10
        
        // Generate dress-based outfits
        for dress in recommendedItems.dresses.prefix(3) {
            for shoe in recommendedItems.shoes.prefix(3) {
                var outfitItems = [dress, shoe]
                
                // Add outerwear if needed
                if !recommendedItems.outerwear.isEmpty && 
                   (forecast.minTemperature < 15 || forecast.precipitationChance > 30) {
                    if let outerwear = recommendedItems.outerwear.first {
                        outfitItems.append(outerwear)
                    }
                }
                
                // Add accessories
                if let accessory = recommendedItems.accessories.first {
                    outfitItems.append(accessory)
                }
                
                let outfit = createOutfit(
                    items: outfitItems,
                    forecast: forecast,
                    userId: userId
                )
                outfits.append(outfit)
                
                if outfits.count >= maxOutfits { return outfits }
            }
        }
        
        // Generate top + bottom outfits
        for top in recommendedItems.tops.prefix(4) {
            for bottom in recommendedItems.bottoms.prefix(3) {
                for shoe in recommendedItems.shoes.prefix(2) {
                    var outfitItems = [top, bottom, shoe]
                    
                    // Add outerwear if appropriate
                    if !recommendedItems.outerwear.isEmpty && shouldAddOuterwear(for: forecast) {
                        if let outerwear = recommendedItems.outerwear.first {
                            outfitItems.append(outerwear)
                        }
                    }
                    
                    // Add accessories
                    if let accessory = recommendedItems.accessories.first {
                        outfitItems.append(accessory)
                    }
                    
                    let outfit = createOutfit(
                        items: outfitItems,
                        forecast: forecast,
                        userId: userId
                    )
                    outfits.append(outfit)
                    
                    if outfits.count >= maxOutfits { return outfits }
                }
            }
        }
        
        return outfits
    }
    
    private func shouldAddOuterwear(for forecast: DailyForecast) -> Bool {
        return forecast.minTemperature < 15 || 
               forecast.precipitationChance > 30 ||
               forecast.windSpeed > 20
    }
    
    private func createOutfit(
        items: [WardrobeItem],
        forecast: DailyForecast,
        userId: UUID
    ) -> Outfit {
        
        let formality = determineBestFormality(for: items)
        let outfitName = generateOutfitName(items: items, forecast: forecast)
        
        return Outfit(
            userId: userId,
            name: outfitName,
            items: items,
            occasion: ["Daily Wear"],
            season: [Season.current],
            formality: formality,
            weather: forecast.outfitConditions,
            creator: .ai
        )
    }
    
    private func determineBestFormality(for items: [WardrobeItem]) -> FormalityLevel {
        let formalityScores = items.reduce(into: [FormalityLevel: Int]()) { counts, item in
            counts[item.formality, default: 0] += 1
        }
        
        return formalityScores.max { $0.value < $1.value }?.key ?? .casual
    }
    
    private func generateOutfitName(items: [WardrobeItem], forecast: DailyForecast) -> String {
        let weatherPrefix = getWeatherPrefix(for: forecast)
        let styleElements = getStyleElements(from: items)
        
        if styleElements.isEmpty {
            return "\(weatherPrefix) \(forecast.dayOfWeek) Look"
        } else {
            return "\(weatherPrefix) \(styleElements.joined(separator: " & ")) Outfit"
        }
    }
    
    private func getWeatherPrefix(for forecast: DailyForecast) -> String {
        if forecast.precipitationChance > 50 {
            return "Rainy Day"
        } else if forecast.maxTemperature > 25 {
            return "Warm Weather"
        } else if forecast.minTemperature < 10 {
            return "Cool Weather"
        } else {
            return "Perfect Weather"
        }
    }
    
    private func getStyleElements(from items: [WardrobeItem]) -> [String] {
        var elements: [String] = []
        
        let primaryColors = items.compactMap { $0.primaryColor?.name }.prefix(2)
        if !primaryColors.isEmpty {
            elements.append(primaryColors.joined(separator: " & "))
        }
        
        if items.contains(where: { $0.category == .dresses }) {
            elements.append("Dress")
        } else if items.contains(where: { $0.category == .outerwear }) {
            elements.append("Layered")
        }
        
        return elements
    }
    
    func getOutfitSuggestions(for date: Date) -> [OutfitWithScore] {
        let dayStart = Calendar.current.startOfDay(for: date)
        return forecastPlans[dayStart] ?? []
    }
    
    func regenerateOutfitsForDay(_ date: Date, forecast: WeatherForecast) async {
        guard let userId = currentUser?.id,
              let dailyForecast = forecast.forecasts.first(where: { 
                  Calendar.current.isDate($0.date, inSameDayAs: date) 
              }) else { return }
        
        isGeneratingPlans = true
        defer { isGeneratingPlans = false }
        
        do {
            let wardrobeItems = try await wardrobeRepository.getItems(for: userId)
            let userPreferences = currentUser?.preferences
            
            let dayPlans = await generateOutfitsForDay(
                dailyForecast: dailyForecast,
                wardrobeItems: wardrobeItems,
                userPreferences: userPreferences
            )
            
            forecastPlans[Calendar.current.startOfDay(for: date)] = dayPlans
            
        } catch {
            handleError(error)
        }
    }
    
    func saveOutfit(_ outfit: Outfit) async {
        do {
            _ = try await outfitRepository.createOutfit(outfit)
        } catch {
            handleError(error)
        }
    }
    
    func clearPlans() {
        forecastPlans.removeAll()
    }
    
    private func handleError(_ error: Error) {
        if let forecastError = error as? ForecastPlannerError {
            errorMessage = forecastError.localizedDescription
        } else {
            errorMessage = "An error occurred: \(error.localizedDescription)"
        }
        showError = true
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    var hasPlans: Bool {
        return !forecastPlans.isEmpty
    }
    
    var totalOutfitSuggestions: Int {
        return forecastPlans.values.reduce(0) { $0 + $1.count }
    }
}

enum ForecastPlannerError: LocalizedError {
    case userNotFound
    case emptyWardrobe
    case noForecastData
    case planGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please log in again."
        case .emptyWardrobe:
            return "Your wardrobe is empty. Add some clothing items to generate outfit plans."
        case .noForecastData:
            return "No weather forecast data available."
        case .planGenerationFailed:
            return "Failed to generate outfit plans. Please try again."
        }
    }
}

extension ForecastOutfitPlannerViewModel {
    func getWeekSummary() -> WeekSummary? {
        guard !forecastPlans.isEmpty else { return nil }
        
        let allOutfits = forecastPlans.values.flatMap { $0 }
        let avgScore = allOutfits.reduce(0.0) { $0 + $1.score.total } / Double(allOutfits.count)
        
        let daysWithPlans = forecastPlans.keys.count
        let totalSuggestions = allOutfits.count
        
        let dominantColors = getDominantColors(from: allOutfits)
        let recommendedFormalities = getRecommendedFormalities(from: allOutfits)
        
        return WeekSummary(
            averageScore: avgScore,
            daysPlanned: daysWithPlans,
            totalSuggestions: totalSuggestions,
            dominantColors: dominantColors,
            recommendedFormalities: recommendedFormalities
        )
    }
    
    private func getDominantColors(from outfits: [OutfitWithScore]) -> [String] {
        let allColors = outfits.flatMap { $0.outfit.items.flatMap { $0.colors.map { $0.name } } }
        let colorCounts = Dictionary(grouping: allColors, by: { $0 })
            .mapValues { $0.count }
        
        return colorCounts.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    private func getRecommendedFormalities(from outfits: [OutfitWithScore]) -> [FormalityLevel] {
        let formalityCounts = Dictionary(grouping: outfits.map { $0.outfit.formality }, by: { $0 })
            .mapValues { $0.count }
        
        return formalityCounts.sorted { $0.value > $1.value }
            .prefix(2)
            .map { $0.key }
    }
}

struct WeekSummary {
    let averageScore: Double
    let daysPlanned: Int
    let totalSuggestions: Int
    let dominantColors: [String]
    let recommendedFormalities: [FormalityLevel]
    
    var averageGrade: String {
        switch averageScore {
        case 90...100: return "A+"
        case 85..<90: return "A"
        case 80..<85: return "A-"
        case 75..<80: return "B+"
        case 70..<75: return "B"
        case 65..<70: return "B-"
        case 60..<65: return "C+"
        case 55..<60: return "C"
        case 50..<55: return "C-"
        default: return "D"
        }
    }
}