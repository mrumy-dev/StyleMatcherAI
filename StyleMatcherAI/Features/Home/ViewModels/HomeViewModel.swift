import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = true
    @Published var wardrobeItemCount = 0
    @Published var wardrobeStats = WardrobeStats()
    @Published var recentItems: [WardrobeItem] = []
    @Published var recommendations: [StyleRecommendation]?
    @Published var weatherInfo: WeatherInfo?
    @Published var userAvatarURL: String?
    @Published var error: Error?
    
    // MARK: - Private Properties
    private let wardrobeRepository = WardrobeRepository()
    private let weatherService = WeatherService.shared
    private let recommendationService = RecommendationService.shared
    private let authService = AuthenticationService.shared
    
    // MARK: - Initialization
    init() {
        Task {
            await loadData()
        }
    }
    
    // MARK: - Public Methods
    
    func loadData() async {
        isLoading = true
        error = nil
        
        async let wardrobeData = loadWardrobeData()
        async let weather = loadWeatherData()
        async let userInfo = loadUserInfo()
        async let recommendationsData = loadRecommendations()
        
        await wardrobeData
        await weather
        await userInfo
        await recommendationsData
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadData()
    }
    
    // MARK: - Private Methods
    
    private func loadWardrobeData() async {
        do {
            guard let userId = authService.currentUser?.id else { return }
            
            let items = try await wardrobeRepository.getItems(for: userId)
            let recentlyAdded = items
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(5)
            
            wardrobeItemCount = items.count
            recentItems = Array(recentlyAdded)
            wardrobeStats = calculateWardrobeStats(from: items)
            
        } catch {
            self.error = error
            print("Failed to load wardrobe data: \(error)")
        }
    }
    
    private func loadWeatherData() async {
        do {
            let weather = try await weatherService.getCurrentWeather()
            weatherInfo = weather
        } catch {
            print("Failed to load weather data: \(error)")
            // Don't set error for weather as it's not critical
        }
    }
    
    private func loadUserInfo() async {
        if let user = authService.currentUser {
            userAvatarURL = user.avatarURL
        }
    }
    
    private func loadRecommendations() async {
        do {
            guard let userId = authService.currentUser?.id else { return }
            let recs = try await recommendationService.getPersonalizedRecommendations(for: userId)
            recommendations = recs
        } catch {
            print("Failed to load recommendations: \(error)")
            // Don't set error for recommendations as they're not critical
        }
    }
    
    private func calculateWardrobeStats(from items: [WardrobeItem]) -> WardrobeStats {
        let totalItems = items.count
        let favoriteItems = items.filter { $0.isFavorite }.count
        
        // Calculate most worn category
        let categoryCount = Dictionary(grouping: items, by: { $0.category })
            .mapValues { $0.count }
        let mostWornCategory = categoryCount.max { $0.value < $1.value }?.key.displayName ?? "None"
        
        return WardrobeStats(
            totalItems: totalItems,
            favoriteItems: favoriteItems,
            mostWornCategory: mostWornCategory,
            averageTimesWorn: items.isEmpty ? 0 : Double(items.map { $0.timesWorn }.reduce(0, +)) / Double(items.count),
            newestItems: items.filter { $0.isRecentlyAdded }.count,
            needsAttention: items.filter { $0.needsAttention }.count
        )
    }
}

// MARK: - Supporting Models

struct WardrobeStats {
    let totalItems: Int
    let favoriteItems: Int
    let mostWornCategory: String
    let averageTimesWorn: Double
    let newestItems: Int
    let needsAttention: Int
    
    init(
        totalItems: Int = 0,
        favoriteItems: Int = 0,
        mostWornCategory: String = "None",
        averageTimesWorn: Double = 0,
        newestItems: Int = 0,
        needsAttention: Int = 0
    ) {
        self.totalItems = totalItems
        self.favoriteItems = favoriteItems
        self.mostWornCategory = mostWornCategory
        self.averageTimesWorn = averageTimesWorn
        self.newestItems = newestItems
        self.needsAttention = needsAttention
    }
}

struct WeatherInfo {
    let temperature: Int
    let description: String
    let icon: String
    let clothingRecommendation: String
    
    init(temperature: Int, description: String, icon: String, clothingRecommendation: String) {
        self.temperature = temperature
        self.description = description
        self.icon = icon
        self.clothingRecommendation = clothingRecommendation
    }
}

struct StyleRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let action: RecommendationAction
    
    enum RecommendationAction {
        case addMissingItem(category: ClothingCategory)
        case wearItem(itemId: UUID)
        case createOutfit(suggestion: String)
        case seasonalUpdate(season: Season)
        case trendAlert(trend: String)
    }
}

// MARK: - Mock Services (Placeholders)

final class WeatherService {
    static let shared = WeatherService()
    
    private init() {}
    
    func getCurrentWeather() async throws -> WeatherInfo {
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return WeatherInfo(
            temperature: 72,
            description: "Partly cloudy",
            icon: "cloud.sun",
            clothingRecommendation: "light layers"
        )
    }
}

final class RecommendationService {
    static let shared = RecommendationService()
    
    private init() {}
    
    func getPersonalizedRecommendations(for userId: UUID) async throws -> [StyleRecommendation] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return [
            StyleRecommendation(
                title: "Complete Your Business Look",
                description: "Add a navy blazer to complement your dress shirts",
                icon: "suit",
                action: .addMissingItem(category: .outerwear)
            ),
            StyleRecommendation(
                title: "It's Been a While...",
                description: "Your blue jeans haven't been worn in 3 weeks",
                icon: "clock",
                action: .wearItem(itemId: UUID())
            ),
            StyleRecommendation(
                title: "Perfect Weather Outfit",
                description: "Light layers work great for today's weather",
                icon: "cloud.sun",
                action: .createOutfit(suggestion: "cardigan + jeans")
            )
        ]
    }
}