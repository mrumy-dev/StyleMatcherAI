import Foundation

struct OutfitScoringEngine {
    
    struct OutfitScore {
        let total: Double
        let colorHarmony: Double
        let formalityMatch: Double
        let weatherAppropriate: Double
        let userPreference: Double
        let breakdown: ScoreBreakdown
        
        struct ScoreBreakdown {
            let colorHarmonyPoints: Double
            let formalityPoints: Double
            let weatherPoints: Double
            let preferencePoints: Double
            let maxPossiblePoints: Double = 100.0
            
            var percentage: Double {
                return (colorHarmonyPoints + formalityPoints + weatherPoints + preferencePoints) / maxPossiblePoints * 100
            }
        }
        
        init(colorHarmony: Double, formalityMatch: Double, weatherAppropriate: Double, userPreference: Double) {
            self.colorHarmony = min(max(colorHarmony, 0.0), 1.0)
            self.formalityMatch = min(max(formalityMatch, 0.0), 1.0)
            self.weatherAppropriate = min(max(weatherAppropriate, 0.0), 1.0)
            self.userPreference = min(max(userPreference, 0.0), 1.0)
            
            let colorPoints = self.colorHarmony * 40.0
            let formalityPoints = self.formalityMatch * 30.0
            let weatherPoints = self.weatherAppropriate * 20.0
            let preferencePoints = self.userPreference * 10.0
            
            self.breakdown = ScoreBreakdown(
                colorHarmonyPoints: colorPoints,
                formalityPoints: formalityPoints,
                weatherPoints: weatherPoints,
                preferencePoints: preferencePoints
            )
            
            self.total = colorPoints + formalityPoints + weatherPoints + preferencePoints
        }
        
        var grade: String {
            switch total {
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
    
    static func scoreOutfit(
        items: [WardrobeItem],
        targetFormality: FormalityLevel,
        weatherConditions: [WeatherCondition],
        userPreferences: UserPreferences?,
        currentSeason: Season = Season.current
    ) -> OutfitScore {
        
        let colorScore = calculateColorHarmonyScore(items: items)
        let formalityScore = calculateFormalityScore(items: items, target: targetFormality)
        let weatherScore = calculateWeatherScore(items: items, conditions: weatherConditions, season: currentSeason)
        let preferenceScore = calculateUserPreferenceScore(items: items, preferences: userPreferences)
        
        return OutfitScore(
            colorHarmony: colorScore,
            formalityMatch: formalityScore,
            weatherAppropriate: weatherScore,
            userPreference: preferenceScore
        )
    }
    
    private static func calculateColorHarmonyScore(items: [WardrobeItem]) -> Double {
        let allColors = items.flatMap { $0.colors }
        let allPatterns = items.flatMap { $0.patterns }
        
        guard !allColors.isEmpty else { return 0.5 }
        
        let colorHarmonyScore = ColorMatchingService.calculateColorHarmony(colors: allColors)
        let patternCompatibilityScore = ColorMatchingService.calculatePatternCompatibility(patterns: allPatterns)
        
        return (colorHarmonyScore * 0.7) + (patternCompatibilityScore * 0.3)
    }
    
    private static func calculateFormalityScore(items: [WardrobeItem], target: FormalityLevel) -> Double {
        guard !items.isEmpty else { return 0.0 }
        
        var totalScore = 0.0
        let weights = getFormalityWeights()
        
        for item in items {
            let itemScore = calculateFormalityCompatibility(item.formality, target: target)
            let categoryWeight = weights[item.category] ?? 1.0
            totalScore += itemScore * categoryWeight
        }
        
        let totalWeight = items.reduce(0.0) { total, item in
            total + (weights[item.category] ?? 1.0)
        }
        
        return totalWeight > 0 ? totalScore / totalWeight : 0.0
    }
    
    private static func calculateFormalityCompatibility(_ itemFormality: FormalityLevel, target: FormalityLevel) -> Double {
        if itemFormality == target || itemFormality == .mixed || target == .mixed {
            return 1.0
        }
        
        let formalityOrder: [FormalityLevel] = [.casual, .smartCasual, .business, .formal]
        guard let itemIndex = formalityOrder.firstIndex(of: itemFormality),
              let targetIndex = formalityOrder.firstIndex(of: target) else {
            return 0.5
        }
        
        let difference = abs(itemIndex - targetIndex)
        
        switch difference {
        case 0: return 1.0
        case 1: return 0.8
        case 2: return 0.4
        case 3: return 0.1
        default: return 0.0
        }
    }
    
    private static func getFormalityWeights() -> [ClothingCategory: Double] {
        return [
            .tops: 1.5,
            .bottoms: 1.5,
            .dresses: 2.0,
            .outerwear: 1.2,
            .shoes: 1.3,
            .accessories: 0.8,
            .underwear: 0.1,
            .activewear: 0.9,
            .sleepwear: 0.1,
            .swimwear: 0.1
        ]
    }
    
    private static func calculateWeatherScore(items: [WardrobeItem], conditions: [WeatherCondition], season: Season) -> Double {
        guard !items.isEmpty else { return 0.0 }
        
        var totalScore = 0.0
        
        for item in items {
            var itemScore = 1.0
            
            itemScore *= calculateSeasonalAppropriate(item: item, season: season)
            itemScore *= calculateWeatherConditionScore(item: item, conditions: conditions)
            
            totalScore += itemScore
        }
        
        return totalScore / Double(items.count)
    }
    
    private static func calculateSeasonalAppropriate(item: WardrobeItem, season: Season) -> Double {
        if item.season.isEmpty {
            return 0.8
        }
        
        if item.season.contains(season) {
            return 1.0
        }
        
        let seasonalCompatibility: [Season: [Season]] = [
            .spring: [.summer, .fall],
            .summer: [.spring, .fall],
            .fall: [.spring, .winter],
            .winter: [.fall, .spring]
        ]
        
        if let compatible = seasonalCompatibility[season],
           item.season.contains(where: { compatible.contains($0) }) {
            return 0.6
        }
        
        return 0.3
    }
    
    private static func calculateWeatherConditionScore(item: WardrobeItem, conditions: [WeatherCondition]) -> Double {
        guard !conditions.isEmpty else { return 1.0 }
        
        var score = 1.0
        
        for condition in conditions {
            score *= getWeatherCompatibilityScore(item: item, condition: condition)
        }
        
        return score
    }
    
    private static func getWeatherCompatibilityScore(item: WardrobeItem, condition: WeatherCondition) -> Double {
        let categoryScores = getWeatherCategoryScores(condition: condition)
        return categoryScores[item.category] ?? 0.8
    }
    
    private static func getWeatherCategoryScores(condition: WeatherCondition) -> [ClothingCategory: Double] {
        switch condition {
        case .sunny, .hot:
            return [
                .tops: 1.0,
                .bottoms: 1.0,
                .dresses: 1.0,
                .outerwear: 0.3,
                .shoes: 0.9,
                .accessories: 1.0,
                .activewear: 1.0,
                .swimwear: 1.0
            ]
            
        case .cold, .snowy:
            return [
                .tops: 1.0,
                .bottoms: 1.0,
                .dresses: 0.7,
                .outerwear: 1.0,
                .shoes: 1.0,
                .accessories: 1.0,
                .activewear: 0.8,
                .swimwear: 0.1
            ]
            
        case .rainy:
            return [
                .tops: 0.9,
                .bottoms: 0.9,
                .dresses: 0.7,
                .outerwear: 1.0,
                .shoes: 0.8,
                .accessories: 0.9,
                .activewear: 0.9,
                .swimwear: 0.2
            ]
            
        case .windy:
            return [
                .tops: 0.9,
                .bottoms: 1.0,
                .dresses: 0.8,
                .outerwear: 1.0,
                .shoes: 1.0,
                .accessories: 0.7,
                .activewear: 0.9,
                .swimwear: 0.3
            ]
            
        case .humid:
            return [
                .tops: 0.9,
                .bottoms: 0.9,
                .dresses: 1.0,
                .outerwear: 0.4,
                .shoes: 0.8,
                .accessories: 0.9,
                .activewear: 1.0,
                .swimwear: 1.0
            ]
            
        case .dry, .cloudy:
            return [
                .tops: 1.0,
                .bottoms: 1.0,
                .dresses: 1.0,
                .outerwear: 0.8,
                .shoes: 1.0,
                .accessories: 1.0,
                .activewear: 1.0,
                .swimwear: 0.8
            ]
        }
    }
    
    private static func calculateUserPreferenceScore(items: [WardrobeItem], preferences: UserPreferences?) -> Double {
        guard let preferences = preferences else { return 0.5 }
        
        var totalScore = 0.0
        var scoreCount = 0
        
        totalScore += calculateColorPreferenceScore(items: items, preferences: preferences.colors)
        scoreCount += 1
        
        if let stylePreference = preferences.style {
            totalScore += calculateFormalityPreferenceScore(items: items, stylePreference: stylePreference)
            scoreCount += 1
        }
        
        totalScore += calculateBrandPreferenceScore(items: items, preferredBrands: preferences.brands)
        scoreCount += 1
        
        return scoreCount > 0 ? totalScore / Double(scoreCount) : 0.5
    }
    
    private static func calculateColorPreferenceScore(items: [WardrobeItem], preferences: ColorPreferences) -> Double {
        let allColors = items.flatMap { $0.colors }
        guard !allColors.isEmpty else { return 0.5 }
        
        var score = 0.5
        
        for color in allColors {
            let colorName = color.name.lowercased()
            
            if preferences.preferred.contains(where: { $0.lowercased() == colorName }) {
                score += 0.3
            } else if preferences.avoided.contains(where: { $0.lowercased() == colorName }) {
                score -= 0.4
            } else if preferences.neutral.contains(where: { $0.lowercased() == colorName }) {
                score += 0.1
            }
        }
        
        return min(max(score, 0.0), 1.0)
    }
    
    private static func calculateFormalityPreferenceScore(items: [WardrobeItem], stylePreference: StylePreference) -> Double {
        return calculateFormalityScore(items: items, target: stylePreference.formality)
    }
    
    private static func calculateBrandPreferenceScore(items: [WardrobeItem], preferredBrands: [String]) -> Double {
        guard !preferredBrands.isEmpty && !items.isEmpty else { return 0.5 }
        
        let preferredBrandsLower = preferredBrands.map { $0.lowercased() }
        let matchingItems = items.filter { item in
            guard let brand = item.brand else { return false }
            return preferredBrandsLower.contains(brand.lowercased())
        }
        
        let matchRatio = Double(matchingItems.count) / Double(items.count)
        return 0.5 + (matchRatio * 0.5)
    }
}

extension OutfitScoringEngine {
    static func rankOutfits(
        outfits: [Outfit],
        targetFormality: FormalityLevel,
        weatherConditions: [WeatherCondition],
        userPreferences: UserPreferences?
    ) -> [OutfitWithScore] {
        
        let scoredOutfits = outfits.map { outfit in
            let score = scoreOutfit(
                items: outfit.items,
                targetFormality: targetFormality,
                weatherConditions: weatherConditions,
                userPreferences: userPreferences
            )
            return OutfitWithScore(outfit: outfit, score: score)
        }
        
        return scoredOutfits.sorted { $0.score.total > $1.score.total }
    }
}

struct OutfitWithScore {
    let outfit: Outfit
    let score: OutfitScoringEngine.OutfitScore
    
    var isHighQuality: Bool {
        return score.total >= 80.0
    }
    
    var needsImprovement: Bool {
        return score.total < 60.0
    }
}