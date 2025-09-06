import Foundation

struct OutfitRatingService {
    
    static func updateUserPreferences(
        userId: UUID,
        outfit: Outfit,
        rating: Double,
        currentPreferences: UserPreferences
    ) async throws -> UserPreferences {
        
        var updatedPreferences = currentPreferences
        
        if rating >= 4.0 {
            updatedPreferences = updatePreferencesForLikedOutfit(
                outfit: outfit,
                preferences: updatedPreferences
            )
        } else if rating <= 2.0 {
            updatedPreferences = updatePreferencesForDislikedOutfit(
                outfit: outfit,
                preferences: updatedPreferences
            )
        }
        
        return updatedPreferences
    }
    
    private static func updatePreferencesForLikedOutfit(
        outfit: Outfit,
        preferences: UserPreferences
    ) -> UserPreferences {
        
        var updatedPreferences = preferences
        
        let allColors = outfit.items.flatMap { $0.colors.map { $0.name.lowercased() } }
        for color in allColors {
            if !updatedPreferences.colors.preferred.contains(color) &&
               !updatedPreferences.colors.neutral.contains(color) {
                updatedPreferences.colors.preferred.append(color)
            }
            
            updatedPreferences.colors.avoided.removeAll { $0.lowercased() == color }
        }
        
        for occasion in outfit.occasion {
            if !updatedPreferences.occasions.contains(occasion) {
                updatedPreferences.occasions.append(occasion)
            }
        }
        
        let brands = outfit.items.compactMap { $0.brand?.lowercased() }
        for brand in brands {
            if !updatedPreferences.brands.map({ $0.lowercased() }).contains(brand) {
                updatedPreferences.brands.append(brand)
            }
        }
        
        if updatedPreferences.style == nil {
            updatedPreferences.style = StylePreference(
                primary: "classic",
                secondary: ["modern"],
                formality: outfit.formality
            )
        } else if let currentStyle = updatedPreferences.style {
            if currentStyle.formality != outfit.formality {
                updatedPreferences.style = StylePreference(
                    primary: currentStyle.primary,
                    secondary: currentStyle.secondary,
                    formality: .mixed
                )
            }
        }
        
        return updatedPreferences
    }
    
    private static func updatePreferencesForDislikedOutfit(
        outfit: Outfit,
        preferences: UserPreferences
    ) -> UserPreferences {
        
        var updatedPreferences = preferences
        
        let allColors = outfit.items.flatMap { $0.colors.map { $0.name.lowercased() } }
        for color in allColors {
            if !updatedPreferences.colors.avoided.contains(color) &&
               !updatedPreferences.colors.neutral.contains(color) {
                updatedPreferences.colors.avoided.append(color)
            }
            
            updatedPreferences.colors.preferred.removeAll { $0.lowercased() == color }
        }
        
        return updatedPreferences
    }
}

struct OutfitFeedbackService {
    private let userRepository: UserRepositoryProtocol
    private let outfitRepository: OutfitRepositoryProtocol
    
    init(
        userRepository: UserRepositoryProtocol = UserRepository(),
        outfitRepository: OutfitRepositoryProtocol = OutfitRepository()
    ) {
        self.userRepository = userRepository
        self.outfitRepository = outfitRepository
    }
    
    func recordOutfitFeedback(
        outfitId: UUID,
        userId: UUID,
        rating: Double,
        feedback: OutfitFeedback?
    ) async throws {
        
        guard let outfit = try await outfitRepository.getOutfit(id: outfitId) else {
            throw OutfitFeedbackError.outfitNotFound
        }
        
        let updatedOutfit = Outfit(
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
            isFavorite: rating >= 4.0 ? true : outfit.isFavorite,
            timesWorn: outfit.timesWorn,
            lastWornAt: outfit.lastWornAt,
            imageURL: outfit.imageURL,
            createdAt: outfit.createdAt,
            updatedAt: Date(),
            creator: outfit.creator,
            isPublic: outfit.isPublic,
            rating: rating
        )
        
        _ = try await outfitRepository.updateOutfit(updatedOutfit)
        
        if let user = try await userRepository.getUser(id: userId),
           let preferences = user.preferences {
            
            let updatedPreferences = try await OutfitRatingService.updateUserPreferences(
                userId: userId,
                outfit: outfit,
                rating: rating,
                currentPreferences: preferences
            )
            
            try await userRepository.updatePreferences(userId: userId, preferences: updatedPreferences)
        }
        
        if let feedback = feedback {
            try await processFeedbackDetails(feedback: feedback, outfit: outfit, userId: userId)
        }
    }
    
    private func processFeedbackDetails(
        feedback: OutfitFeedback,
        outfit: Outfit,
        userId: UUID
    ) async throws {
        
        if feedback.tooFormal || feedback.tooFormalFor.isEmpty == false {
            try await adjustFormalityPreferences(
                userId: userId,
                outfit: outfit,
                adjustment: .tooFormal
            )
        }
        
        if feedback.tooCasual || feedback.tooCasualFor.isEmpty == false {
            try await adjustFormalityPreferences(
                userId: userId,
                outfit: outfit,
                adjustment: .tooCasual
            )
        }
        
        if !feedback.dislikedColors.isEmpty {
            try await adjustColorPreferences(
                userId: userId,
                colors: feedback.dislikedColors,
                preference: .dislike
            )
        }
        
        if !feedback.likedColors.isEmpty {
            try await adjustColorPreferences(
                userId: userId,
                colors: feedback.likedColors,
                preference: .like
            )
        }
    }
    
    private func adjustFormalityPreferences(
        userId: UUID,
        outfit: Outfit,
        adjustment: FormalityAdjustment
    ) async throws {
        
        guard let user = try await userRepository.getUser(id: userId),
              var preferences = user.preferences else { return }
        
        if let currentStyle = preferences.style {
            let targetFormality: FormalityLevel
            
            switch adjustment {
            case .tooFormal:
                targetFormality = getFormalityLevel(below: outfit.formality)
            case .tooCasual:
                targetFormality = getFormalityLevel(above: outfit.formality)
            }
            
            preferences.style = StylePreference(
                primary: currentStyle.primary,
                secondary: currentStyle.secondary,
                formality: targetFormality
            )
            
            try await userRepository.updatePreferences(userId: userId, preferences: preferences)
        }
    }
    
    private func adjustColorPreferences(
        userId: UUID,
        colors: [String],
        preference: ColorPreference
    ) async throws {
        
        guard let user = try await userRepository.getUser(id: userId),
              var preferences = user.preferences else { return }
        
        for color in colors {
            let colorLower = color.lowercased()
            
            switch preference {
            case .like:
                if !preferences.colors.preferred.contains(colorLower) {
                    preferences.colors.preferred.append(colorLower)
                }
                preferences.colors.avoided.removeAll { $0.lowercased() == colorLower }
                
            case .dislike:
                if !preferences.colors.avoided.contains(colorLower) {
                    preferences.colors.avoided.append(colorLower)
                }
                preferences.colors.preferred.removeAll { $0.lowercased() == colorLower }
            }
        }
        
        try await userRepository.updatePreferences(userId: userId, preferences: preferences)
    }
    
    private func getFormalityLevel(below formality: FormalityLevel) -> FormalityLevel {
        switch formality {
        case .formal:
            return .business
        case .business:
            return .smartCasual
        case .smartCasual:
            return .casual
        case .casual, .mixed:
            return .casual
        }
    }
    
    private func getFormalityLevel(above formality: FormalityLevel) -> FormalityLevel {
        switch formality {
        case .casual:
            return .smartCasual
        case .smartCasual:
            return .business
        case .business:
            return .formal
        case .formal, .mixed:
            return .formal
        }
    }
}

struct OutfitFeedback {
    let rating: Double
    let tooFormal: Bool
    let tooCasual: Bool
    let tooFormalFor: [String]
    let tooCasualFor: [String]
    let likedColors: [String]
    let dislikedColors: [String]
    let likedItems: [UUID]
    let dislikedItems: [UUID]
    let comments: String?
    
    init(
        rating: Double,
        tooFormal: Bool = false,
        tooCasual: Bool = false,
        tooFormalFor: [String] = [],
        tooCasualFor: [String] = [],
        likedColors: [String] = [],
        dislikedColors: [String] = [],
        likedItems: [UUID] = [],
        dislikedItems: [UUID] = [],
        comments: String? = nil
    ) {
        self.rating = rating
        self.tooFormal = tooFormal
        self.tooCasual = tooCasual
        self.tooFormalFor = tooFormalFor
        self.tooCasualFor = tooCasualFor
        self.likedColors = likedColors
        self.dislikedColors = dislikedColors
        self.likedItems = likedItems
        self.dislikedItems = dislikedItems
        self.comments = comments
    }
}

enum FormalityAdjustment {
    case tooFormal
    case tooCasual
}

enum ColorPreference {
    case like
    case dislike
}

enum OutfitFeedbackError: LocalizedError {
    case outfitNotFound
    case userNotFound
    case invalidRating
    case feedbackProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .outfitNotFound:
            return "The outfit could not be found."
        case .userNotFound:
            return "User not found."
        case .invalidRating:
            return "Rating must be between 1 and 5."
        case .feedbackProcessingFailed:
            return "Failed to process outfit feedback."
        }
    }
}

extension OutfitFeedbackService {
    func getOutfitInsights(for userId: UUID, limit: Int = 50) async throws -> OutfitInsights {
        let outfits = try await outfitRepository.getOutfits(for: userId)
        let ratedOutfits = outfits.compactMap { outfit -> (Outfit, Double) in
            guard let rating = outfit.rating else { return nil }
            return (outfit, rating)
        }.prefix(limit)
        
        let insights = calculateInsights(from: Array(ratedOutfits))
        return insights
    }
    
    private func calculateInsights(from ratedOutfits: [(Outfit, Double)]) -> OutfitInsights {
        let highRatedOutfits = ratedOutfits.filter { $0.1 >= 4.0 }
        let lowRatedOutfits = ratedOutfits.filter { $0.1 <= 2.0 }
        
        let favoriteColors = calculateFavoriteColors(from: highRatedOutfits.map { $0.0 })
        let leastFavoriteColors = calculateLeastFavoriteColors(from: lowRatedOutfits.map { $0.0 })
        let preferredFormality = calculatePreferredFormality(from: highRatedOutfits.map { $0.0 })
        let favoriteOccasions = calculateFavoriteOccasions(from: highRatedOutfits.map { $0.0 })
        
        return OutfitInsights(
            totalRatedOutfits: ratedOutfits.count,
            averageRating: ratedOutfits.map { $0.1 }.reduce(0, +) / Double(ratedOutfits.count),
            favoriteColors: favoriteColors,
            leastFavoriteColors: leastFavoriteColors,
            preferredFormality: preferredFormality,
            favoriteOccasions: favoriteOccasions,
            bestScoringOutfits: highRatedOutfits.prefix(5).map { $0.0 },
            improvementSuggestions: generateImprovementSuggestions(
                highRated: highRatedOutfits.map { $0.0 },
                lowRated: lowRatedOutfits.map { $0.0 }
            )
        )
    }
    
    private func calculateFavoriteColors(from outfits: [Outfit]) -> [String] {
        let allColors = outfits.flatMap { $0.items.flatMap { $0.colors.map { $0.name } } }
        let colorCounts = Dictionary(grouping: allColors, by: { $0 })
            .mapValues { $0.count }
        return colorCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
    
    private func calculateLeastFavoriteColors(from outfits: [Outfit]) -> [String] {
        let allColors = outfits.flatMap { $0.items.flatMap { $0.colors.map { $0.name } } }
        let colorCounts = Dictionary(grouping: allColors, by: { $0 })
            .mapValues { $0.count }
        return colorCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }
    
    private func calculatePreferredFormality(from outfits: [Outfit]) -> FormalityLevel? {
        let formalityCounts = Dictionary(grouping: outfits, by: { $0.formality })
            .mapValues { $0.count }
        return formalityCounts.max { $0.value < $1.value }?.key
    }
    
    private func calculateFavoriteOccasions(from outfits: [Outfit]) -> [String] {
        let allOccasions = outfits.flatMap { $0.occasion }
        let occasionCounts = Dictionary(grouping: allOccasions, by: { $0 })
            .mapValues { $0.count }
        return occasionCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
    
    private func generateImprovementSuggestions(
        highRated: [Outfit],
        lowRated: [Outfit]
    ) -> [String] {
        var suggestions: [String] = []
        
        let highRatedColors = Set(highRated.flatMap { $0.items.flatMap { $0.colors.map { $0.name } } })
        let lowRatedColors = Set(lowRated.flatMap { $0.items.flatMap { $0.colors.map { $0.name } } })
        
        let colorsToAvoid = lowRatedColors.subtracting(highRatedColors)
        if !colorsToAvoid.isEmpty {
            suggestions.append("Consider avoiding these colors: \(colorsToAvoid.joined(separator: ", "))")
        }
        
        let favoriteColors = highRatedColors.subtracting(lowRatedColors)
        if !favoriteColors.isEmpty {
            suggestions.append("You seem to prefer these colors: \(favoriteColors.joined(separator: ", "))")
        }
        
        let highRatedFormalities = Set(highRated.map { $0.formality })
        let lowRatedFormalities = Set(lowRated.map { $0.formality })
        
        if highRatedFormalities.count == 1, let preferred = highRatedFormalities.first {
            suggestions.append("You prefer \(preferred.displayName) outfits")
        }
        
        return suggestions
    }
}

struct OutfitInsights {
    let totalRatedOutfits: Int
    let averageRating: Double
    let favoriteColors: [String]
    let leastFavoriteColors: [String]
    let preferredFormality: FormalityLevel?
    let favoriteOccasions: [String]
    let bestScoringOutfits: [Outfit]
    let improvementSuggestions: [String]
}