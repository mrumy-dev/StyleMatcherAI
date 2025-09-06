import Foundation
import SwiftUI

@MainActor
class OutfitGeneratorViewModel: ObservableObject {
    
    @Published var isLoading = false
    @Published var suggestions: [OutfitWithScore] = []
    @Published var currentSuggestionIndex = 0
    @Published var selectedFormality: FormalityLevel = .casual
    @Published var selectedWeatherConditions: [WeatherCondition] = []
    @Published var selectedOccasions: [String] = []
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var savedOutfits: [Outfit] = []
    @Published var wardrobeItems: [WardrobeItem] = []
    @Published var lastGenerationFilters: GenerationFilters?
    
    private let wardrobeRepository: WardrobeRepositoryProtocol
    private let outfitRepository: OutfitRepository
    private let userRepository: UserRepository
    private var currentUser: AppUser?
    
    struct GenerationFilters {
        let formality: FormalityLevel
        let weatherConditions: [WeatherCondition]
        let occasions: [String]
        let timestamp: Date
        
        init(formality: FormalityLevel, weatherConditions: [WeatherCondition], occasions: [String]) {
            self.formality = formality
            self.weatherConditions = weatherConditions
            self.occasions = occasions
            self.timestamp = Date()
        }
    }
    
    init(
        wardrobeRepository: WardrobeRepositoryProtocol = WardrobeRepository(),
        outfitRepository: OutfitRepository = OutfitRepository(),
        userRepository: UserRepository = UserRepository()
    ) {
        self.wardrobeRepository = wardrobeRepository
        self.outfitRepository = outfitRepository
        self.userRepository = userRepository
        
        Task {
            await loadCurrentUser()
            await loadWardrobeItems()
            await loadSavedOutfits()
        }
    }
    
    private func loadCurrentUser() async {
        do {
            self.currentUser = try await userRepository.getCurrentUser()
        } catch {
            handleError(error)
        }
    }
    
    private func loadWardrobeItems() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            wardrobeItems = try await wardrobeRepository.getItems(for: userId)
        } catch {
            handleError(error)
        }
    }
    
    private func loadSavedOutfits() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            savedOutfits = try await outfitRepository.getOutfits(for: userId)
        } catch {
            handleError(error)
        }
    }
    
    func generateOutfitSuggestions(currentWeather: CurrentWeather? = nil) async {
        guard let userId = currentUser?.id else {
            handleError(OutfitGeneratorError.userNotFound)
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allWardrobeItems = try await wardrobeRepository.getItems(for: userId)
            guard !allWardrobeItems.isEmpty else {
                handleError(OutfitGeneratorError.emptyWardrobe)
                return
            }
            
            // Filter items based on weather if available
            let wardrobeItems: [WardrobeItem]
            if let weather = currentWeather {
                wardrobeItems = WeatherClothingFilter.filterItemsForWeather(
                    items: allWardrobeItems,
                    weather: weather,
                    season: Season.current
                )
                
                // Update weather conditions based on actual weather
                selectedWeatherConditions = weather.outfitConditions
            } else {
                wardrobeItems = allWardrobeItems
            }
            
            guard !wardrobeItems.isEmpty else {
                handleError(OutfitGeneratorError.noSuitableItems)
                return
            }
            
            let userPreferences = currentUser?.preferences
            let generatedOutfits = try await generateOutfitCombinations(
                from: wardrobeItems,
                formality: selectedFormality,
                weather: selectedWeatherConditions,
                occasions: selectedOccasions,
                currentWeather: currentWeather
            )
            
            let scoredOutfits = OutfitScoringEngine.rankOutfits(
                outfits: generatedOutfits,
                targetFormality: selectedFormality,
                weatherConditions: selectedWeatherConditions,
                userPreferences: userPreferences
            )
            
            suggestions = Array(scoredOutfits.prefix(10))
            currentSuggestionIndex = 0
            lastGenerationFilters = GenerationFilters(
                formality: selectedFormality,
                weatherConditions: selectedWeatherConditions,
                occasions: selectedOccasions
            )
            
        } catch {
            handleError(error)
        }
    }
    
    private func generateOutfitCombinations(
        from items: [WardrobeItem],
        formality: FormalityLevel,
        weather: [WeatherCondition],
        occasions: [String],
        currentWeather: CurrentWeather? = nil
    ) async throws -> [Outfit] {
        let currentSeason = Season.current
        
        let filteredItems: [WardrobeItem]
        
        if let weather = currentWeather {
            // Use weather-based filtering for better recommendations
            filteredItems = items.filter { item in
                item.isAppropriateFor(formality: formality) && !item.isArchived
            }
        } else {
            filteredItems = items.filter { item in
                item.isAppropriateFor(formality: formality) &&
                (item.season.isEmpty || item.season.contains(currentSeason)) &&
                !item.isArchived
            }
        }
        
        let itemsByCategory = Dictionary(grouping: filteredItems) { $0.category }
        
        // Get weather-based recommendations if available
        let recommendedItems: RecommendedItems?
        if let weather = currentWeather {
            recommendedItems = WeatherClothingFilter.getRecommendedItemsForWeather(
                items: filteredItems,
                weather: weather,
                season: currentSeason
            )
        } else {
            recommendedItems = nil
        }
        
        var outfits: [Outfit] = []
        let maxOutfits = 50
        
        // Use weather recommendations if available, otherwise use all items
        let tops = recommendedItems?.tops ?? itemsByCategory[.tops] ?? []
        let bottoms = recommendedItems?.bottoms ?? itemsByCategory[.bottoms] ?? []
        let dresses = recommendedItems?.dresses ?? itemsByCategory[.dresses] ?? []
        let shoes = recommendedItems?.shoes ?? itemsByCategory[.shoes] ?? []
        let outerwear = recommendedItems?.outerwear ?? itemsByCategory[.outerwear] ?? []
        let accessories = recommendedItems?.accessories ?? itemsByCategory[.accessories] ?? []
        
        for dress in dresses.prefix(min(dresses.count, 10)) {
            for shoe in shoes.prefix(min(shoes.count, 5)) {
                var outfitItems = [dress, shoe]
                
                if let accessory = accessories.randomElement() {
                    outfitItems.append(accessory)
                }
                
                if !outerwear.isEmpty && weather.contains(where: { $0 == .cold || $0 == .rainy }) {
                    if let jacket = outerwear.randomElement() {
                        outfitItems.append(jacket)
                    }
                }
                
                let outfit = createOutfit(
                    items: outfitItems,
                    formality: formality,
                    weather: weather,
                    occasions: occasions
                )
                outfits.append(outfit)
                
                if outfits.count >= maxOutfits { return outfits }
            }
        }
        
        for top in tops.prefix(min(tops.count, 15)) {
            for bottom in bottoms.prefix(min(bottoms.count, 10)) {
                for shoe in shoes.prefix(min(shoes.count, 5)) {
                    var outfitItems = [top, bottom, shoe]
                    
                    if let accessory = accessories.randomElement() {
                        outfitItems.append(accessory)
                    }
                    
                    if !outerwear.isEmpty && weather.contains(where: { $0 == .cold || $0 == .rainy }) {
                        if let jacket = outerwear.randomElement() {
                            outfitItems.append(jacket)
                        }
                    }
                    
                    let outfit = createOutfit(
                        items: outfitItems,
                        formality: formality,
                        weather: weather,
                        occasions: occasions
                    )
                    outfits.append(outfit)
                    
                    if outfits.count >= maxOutfits { return outfits }
                }
            }
        }
        
        return outfits
    }
    
    private func createOutfit(
        items: [WardrobeItem],
        formality: FormalityLevel,
        weather: [WeatherCondition],
        occasions: [String]
    ) -> Outfit {
        guard let userId = currentUser?.id else {
            fatalError("User ID not available")
        }
        
        let outfitName = generateOutfitName(items: items, formality: formality, occasions: occasions)
        
        return Outfit(
            userId: userId,
            name: outfitName,
            items: items,
            occasion: occasions,
            season: [Season.current],
            formality: formality,
            weather: weather,
            creator: .ai
        )
    }
    
    private func generateOutfitName(items: [WardrobeItem], formality: FormalityLevel, occasions: [String]) -> String {
        let primaryColors = items.compactMap { $0.primaryColor?.name }.prefix(2)
        let colorString = primaryColors.isEmpty ? "" : primaryColors.joined(separator: " & ") + " "
        
        let occasion = occasions.first ?? formality.displayName
        
        let categories = Set(items.map { $0.category })
        if categories.contains(.dresses) {
            return "\(colorString)\(occasion) Dress Look"
        } else if categories.contains(.outerwear) {
            return "\(colorString)Layered \(occasion) Outfit"
        } else {
            return "\(colorString)\(occasion) Ensemble"
        }
    }
    
    func swipeToNext() {
        if currentSuggestionIndex < suggestions.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentSuggestionIndex += 1
            }
        }
    }
    
    func swipeToPrevious() {
        if currentSuggestionIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentSuggestionIndex -= 1
            }
        }
    }
    
    func likeOutfit() async {
        guard currentSuggestionIndex < suggestions.count else { return }
        
        let outfitWithScore = suggestions[currentSuggestionIndex]
        let outfit = outfitWithScore.outfit
        
        await saveOutfit(outfit, rating: 5.0)
    }
    
    func dislikeOutfit() async {
        swipeToNext()
    }
    
    func saveOutfit(_ outfit: Outfit, rating: Double? = nil) async {
        do {
            var outfitToSave = outfit
            if let rating = rating {
                outfitToSave = Outfit(
                    id: outfit.id,
                    userId: outfit.userId,
                    name: outfit.name,
                    description: outfit.description,
                    items: outfit.items,
                    occasion: outfit.occasion,
                    season: outfit.season,
                    formality: outfit.formality,
                    weather: outfit.weather,
                    tags: outfit.tags,
                    isFavorite: rating >= 4.0,
                    timesWorn: outfit.timesWorn,
                    lastWornAt: outfit.lastWornAt,
                    imageURL: outfit.imageURL,
                    createdAt: outfit.createdAt,
                    updatedAt: Date(),
                    creator: outfit.creator,
                    isPublic: outfit.isPublic,
                    rating: rating
                )
            }
            
            let savedOutfit = try await outfitRepository.createOutfit(outfitToSave)
            savedOutfits.append(savedOutfit)
            
        } catch {
            handleError(error)
        }
    }
    
    func rateOutfit(_ outfit: Outfit, rating: Double) async {
        await saveOutfit(outfit, rating: rating)
    }
    
    func refreshSuggestions(currentWeather: CurrentWeather? = nil) async {
        await generateOutfitSuggestions(currentWeather: currentWeather)
    }
    
    func updateFilters(
        formality: FormalityLevel? = nil,
        weather: [WeatherCondition]? = nil,
        occasions: [String]? = nil
    ) {
        if let formality = formality {
            selectedFormality = formality
        }
        if let weather = weather {
            selectedWeatherConditions = weather
        }
        if let occasions = occasions {
            selectedOccasions = occasions
        }
    }
    
    var currentSuggestion: OutfitWithScore? {
        guard currentSuggestionIndex < suggestions.count else { return nil }
        return suggestions[currentSuggestionIndex]
    }
    
    var hasMoreSuggestions: Bool {
        return currentSuggestionIndex < suggestions.count - 1
    }
    
    var canGenerateOutfits: Bool {
        return !wardrobeItems.isEmpty
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
}

enum OutfitGeneratorError: LocalizedError {
    case userNotFound
    case emptyWardrobe
    case noSuitableItems
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please log in again."
        case .emptyWardrobe:
            return "Your wardrobe is empty. Add some clothing items to generate outfits."
        case .noSuitableItems:
            return "No suitable items found for the selected criteria. Try adjusting your filters."
        case .generationFailed:
            return "Failed to generate outfit suggestions. Please try again."
        }
    }
}

extension OutfitGeneratorViewModel {
    var suggestionsEmpty: Bool {
        return suggestions.isEmpty
    }
    
    var loadingOrEmpty: Bool {
        return isLoading || suggestions.isEmpty
    }
    
    func canRegenerateWithSameFilters: Bool {
        guard let filters = lastGenerationFilters else { return false }
        return filters.formality == selectedFormality &&
               filters.weatherConditions == selectedWeatherConditions &&
               filters.occasions == selectedOccasions
    }
}