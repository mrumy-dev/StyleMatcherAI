import Foundation

struct WeatherClothingFilter {
    
    static func filterItemsForWeather(
        items: [WardrobeItem],
        weather: CurrentWeather,
        season: Season = Season.current
    ) -> [WardrobeItem] {
        return items.filter { item in
            isItemAppropriateForWeather(item: item, weather: weather, season: season)
        }
    }
    
    static func filterItemsForForecast(
        items: [WardrobeItem],
        forecast: DailyForecast,
        season: Season = Season.current
    ) -> [WardrobeItem] {
        return items.filter { item in
            isItemAppropriateForForecast(item: item, forecast: forecast, season: season)
        }
    }
    
    static func getRecommendedItemsForWeather(
        items: [WardrobeItem],
        weather: CurrentWeather,
        season: Season = Season.current
    ) -> RecommendedItems {
        
        let appropriateItems = filterItemsForWeather(items: items, weather: weather, season: season)
        let itemsByCategory = Dictionary(grouping: appropriateItems) { $0.category }
        
        let temperatureRange = getTemperatureCategory(from: weather.temperature)
        let weatherConditions = weather.outfitConditions
        
        return RecommendedItems(
            tops: prioritizeItems(itemsByCategory[.tops] ?? [], for: temperatureRange, conditions: weatherConditions),
            bottoms: prioritizeItems(itemsByCategory[.bottoms] ?? [], for: temperatureRange, conditions: weatherConditions),
            outerwear: getOuterwearRecommendations(items: itemsByCategory[.outerwear] ?? [], weather: weather),
            shoes: getShoeRecommendations(items: itemsByCategory[.shoes] ?? [], weather: weather),
            accessories: getAccessoryRecommendations(items: itemsByCategory[.accessories] ?? [], weather: weather),
            dresses: prioritizeItems(itemsByCategory[.dresses] ?? [], for: temperatureRange, conditions: weatherConditions)
        )
    }
    
    private static func isItemAppropriateForWeather(
        item: WardrobeItem,
        weather: CurrentWeather,
        season: Season
    ) -> Bool {
        // Check seasonal appropriateness
        if !item.season.isEmpty && !item.season.contains(season) {
            // Allow some flexibility with seasonal items
            let seasonalScore = calculateSeasonalFlexibility(item: item, currentSeason: season, weather: weather)
            if seasonalScore < 0.3 {
                return false
            }
        }
        
        // Temperature checks
        if !isItemAppropriateForTemperature(item: item, temperature: weather.temperature) {
            return false
        }
        
        // Weather condition checks
        return isItemAppropriateForConditions(item: item, conditions: weather.outfitConditions)
    }
    
    private static func isItemAppropriateForForecast(
        item: WardrobeItem,
        forecast: DailyForecast,
        season: Season
    ) -> Bool {
        // Check seasonal appropriateness
        if !item.season.isEmpty && !item.season.contains(season) {
            let avgTemp = (forecast.minTemperature + forecast.maxTemperature) / 2
            let mockWeather = CurrentWeather(
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
            
            let seasonalScore = calculateSeasonalFlexibility(item: item, currentSeason: season, weather: mockWeather)
            if seasonalScore < 0.3 {
                return false
            }
        }
        
        // Temperature range checks
        if !isItemAppropriateForTemperatureRange(
            item: item,
            minTemp: forecast.minTemperature,
            maxTemp: forecast.maxTemperature
        ) {
            return false
        }
        
        // Weather condition checks
        return isItemAppropriateForConditions(item: item, conditions: forecast.outfitConditions)
    }
    
    private static func isItemAppropriateForTemperature(item: WardrobeItem, temperature: Double) -> Bool {
        let tempCategory = getTemperatureCategory(from: temperature)
        
        switch tempCategory {
        case .freezing:
            return isWarmClothing(item) || isNeutralClothing(item)
        case .cold:
            return isWarmClothing(item) || isNeutralClothing(item)
        case .cool:
            return isNeutralClothing(item) || isLightClothing(item)
        case .mild:
            return true // Most items work in mild weather
        case .warm:
            return isLightClothing(item) || isNeutralClothing(item)
        case .hot:
            return isLightClothing(item)
        }
    }
    
    private static func isItemAppropriateForTemperatureRange(
        item: WardrobeItem,
        minTemp: Double,
        maxTemp: Double
    ) -> Bool {
        let tempSpread = maxTemp - minTemp
        
        // For large temperature swings, prefer versatile pieces
        if tempSpread > 15 {
            return isNeutralClothing(item) || item.category == .outerwear
        }
        
        // Check if item works for the average temperature
        let avgTemp = (minTemp + maxTemp) / 2
        return isItemAppropriateForTemperature(item: item, temperature: avgTemp)
    }
    
    private static func isItemAppropriateForConditions(
        item: WardrobeItem,
        conditions: [WeatherCondition]
    ) -> Bool {
        for condition in conditions {
            if !isItemSuitableForCondition(item: item, condition: condition) {
                return false
            }
        }
        return true
    }
    
    private static func isItemSuitableForCondition(item: WardrobeItem, condition: WeatherCondition) -> Bool {
        switch condition {
        case .rainy:
            return !isFormalFootwear(item) && !isDelicateFabric(item)
        case .snowy:
            return isWaterResistant(item) || isWarmClothing(item)
        case .sunny:
            return !isDarkColor(item) || hasLightFabric(item)
        case .cloudy:
            return true // Most items work in cloudy weather
        case .windy:
            return !isFlowingGarment(item) || item.category == .outerwear
        case .hot:
            return isBreathable(item) && isLightColor(item)
        case .cold:
            return isWarmClothing(item) || item.category == .outerwear
        case .humid:
            return isBreathable(item) && !isHeavyFabric(item)
        case .dry:
            return true // Most items work in dry weather
        }
    }
    
    private static func calculateSeasonalFlexibility(
        item: WardrobeItem,
        currentSeason: Season,
        weather: CurrentWeather
    ) -> Double {
        let itemSeasons = item.season
        
        if itemSeasons.isEmpty {
            return 1.0 // No seasonal restrictions
        }
        
        if itemSeasons.contains(currentSeason) {
            return 1.0 // Perfect match
        }
        
        // Calculate flexibility based on weather conditions
        var flexibilityScore = 0.0
        
        // Temperature-based flexibility
        switch currentSeason {
        case .spring:
            if itemSeasons.contains(.summer) && weather.temperature > 20 {
                flexibilityScore += 0.6
            }
            if itemSeasons.contains(.winter) && weather.temperature < 15 {
                flexibilityScore += 0.4
            }
        case .summer:
            if itemSeasons.contains(.spring) && weather.temperature < 25 {
                flexibilityScore += 0.6
            }
            if itemSeasons.contains(.fall) && weather.temperature < 30 {
                flexibilityScore += 0.3
            }
        case .fall:
            if itemSeasons.contains(.winter) && weather.temperature < 15 {
                flexibilityScore += 0.6
            }
            if itemSeasons.contains(.spring) && weather.temperature > 15 {
                flexibilityScore += 0.4
            }
        case .winter:
            if itemSeasons.contains(.fall) && weather.temperature > 5 {
                flexibilityScore += 0.5
            }
            if itemSeasons.contains(.spring) && weather.temperature > 10 {
                flexibilityScore += 0.3
            }
        }
        
        return flexibilityScore
    }
    
    private static func prioritizeItems(
        _ items: [WardrobeItem],
        for temperatureRange: TemperatureCategory,
        conditions: [WeatherCondition]
    ) -> [WardrobeItem] {
        return items.sorted { item1, item2 in
            let score1 = calculateItemScore(item1, temperatureRange: temperatureRange, conditions: conditions)
            let score2 = calculateItemScore(item2, temperatureRange: temperatureRange, conditions: conditions)
            return score1 > score2
        }
    }
    
    private static func calculateItemScore(
        _ item: WardrobeItem,
        temperatureRange: TemperatureCategory,
        conditions: [WeatherCondition]
    ) -> Double {
        var score = 0.0
        
        // Temperature appropriateness (40% of score)
        if isItemPerfectForTemperature(item, temperatureRange: temperatureRange) {
            score += 4.0
        } else if isItemGoodForTemperature(item, temperatureRange: temperatureRange) {
            score += 2.0
        } else if isItemOkayForTemperature(item, temperatureRange: temperatureRange) {
            score += 1.0
        }
        
        // Condition appropriateness (30% of score)
        let conditionScore = conditions.map { condition in
            isItemSuitableForCondition(item: item, condition: condition) ? 1.0 : -1.0
        }.reduce(0, +) / Double(max(conditions.count, 1))
        score += conditionScore * 3.0
        
        // Versatility bonus (20% of score)
        score += getVersatilityScore(item) * 2.0
        
        // User preference bonus (10% of score)
        if item.isFavorite {
            score += 1.0
        }
        
        // Frequency penalty (don't always suggest the same items)
        if item.timesWorn > 10 {
            score -= 0.5
        }
        
        return score
    }
    
    private static func getOuterwearRecommendations(
        items: [WardrobeItem],
        weather: CurrentWeather
    ) -> [WardrobeItem] {
        let needsOuterwear = weather.temperature < 20 || 
                           weather.outfitConditions.contains(.rainy) ||
                           weather.outfitConditions.contains(.windy)
        
        if !needsOuterwear {
            return []
        }
        
        return items.filter { item in
            if weather.temperature < 5 {
                return isHeavyOuterwear(item)
            } else if weather.temperature < 15 {
                return isMediumOuterwear(item) || isHeavyOuterwear(item)
            } else if weather.outfitConditions.contains(.rainy) {
                return isWaterResistant(item)
            } else if weather.outfitConditions.contains(.windy) {
                return isWindResistant(item)
            } else {
                return isLightOuterwear(item) || isMediumOuterwear(item)
            }
        }.sorted { $0.timesWorn < $1.timesWorn } // Prefer less worn items
    }
    
    private static func getShoeRecommendations(
        items: [WardrobeItem],
        weather: CurrentWeather
    ) -> [WardrobeItem] {
        return items.filter { shoe in
            if weather.outfitConditions.contains(.rainy) || weather.outfitConditions.contains(.snowy) {
                return isWeatherResistantFootwear(shoe)
            } else if weather.temperature > 25 {
                return isBreathableFootwear(shoe)
            } else if weather.temperature < 5 {
                return isWarmFootwear(shoe)
            } else {
                return true
            }
        }.sorted { shoe1, shoe2 in
            let score1 = calculateFootwearScore(shoe1, weather: weather)
            let score2 = calculateFootwearScore(shoe2, weather: weather)
            return score1 > score2
        }
    }
    
    private static func getAccessoryRecommendations(
        items: [WardrobeItem],
        weather: CurrentWeather
    ) -> [WardrobeItem] {
        return items.filter { accessory in
            // Recommend accessories based on weather needs
            if weather.outfitConditions.contains(.sunny) && isHatOrSunglasses(accessory) {
                return true
            } else if weather.outfitConditions.contains(.cold) && isWarmAccessory(accessory) {
                return true
            } else if weather.outfitConditions.contains(.rainy) && isWaterResistantAccessory(accessory) {
                return true
            } else if weather.outfitConditions.contains(.windy) && isSecureAccessory(accessory) {
                return true
            } else {
                return isGeneralAccessory(accessory)
            }
        }.prefix(3).map { $0 } // Limit to 3 accessories
    }
    
    private static func getTemperatureCategory(from temperature: Double) -> TemperatureCategory {
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

// MARK: - Item Classification Helpers

extension WeatherClothingFilter {
    
    private static func isWarmClothing(_ item: WardrobeItem) -> Bool {
        let warmMaterials = ["wool", "cashmere", "fleece", "down", "fur", "flannel", "thermal"]
        let warmSubcategories = ["sweater", "hoodie", "coat", "jacket", "boots", "winter"]
        
        return item.materials.contains { material in
            warmMaterials.contains { material.lowercased().contains($0) }
        } || warmSubcategories.contains { category in
            item.subcategory?.lowercased().contains(category) == true ||
            item.name.lowercased().contains(category)
        }
    }
    
    private static func isLightClothing(_ item: WardrobeItem) -> Bool {
        let lightMaterials = ["cotton", "linen", "silk", "rayon", "bamboo", "mesh"]
        let lightSubcategories = ["t-shirt", "tank top", "shorts", "sandals", "dress"]
        
        return item.materials.contains { material in
            lightMaterials.contains { material.lowercased().contains($0) }
        } || lightSubcategories.contains { category in
            item.subcategory?.lowercased().contains(category) == true ||
            item.name.lowercased().contains(category)
        }
    }
    
    private static func isNeutralClothing(_ item: WardrobeItem) -> Bool {
        return !isWarmClothing(item) && !isLightClothing(item)
    }
    
    private static func isBreathable(_ item: WardrobeItem) -> Bool {
        let breathableMaterials = ["cotton", "linen", "bamboo", "modal", "moisture-wicking"]
        return item.materials.contains { material in
            breathableMaterials.contains { material.lowercased().contains($0) }
        }
    }
    
    private static func isWaterResistant(_ item: WardrobeItem) -> Bool {
        let waterResistantMaterials = ["nylon", "polyester", "rubber", "vinyl", "waterproof", "water-resistant"]
        let waterResistantNames = ["raincoat", "trench", "windbreaker", "parka"]
        
        return item.materials.contains { material in
            waterResistantMaterials.contains { material.lowercased().contains($0) }
        } || waterResistantNames.contains { name in
            item.name.lowercased().contains(name) ||
            item.subcategory?.lowercased().contains(name) == true
        }
    }
    
    private static func isLightColor(_ item: WardrobeItem) -> Bool {
        let lightColors = ["white", "cream", "beige", "light", "pale", "pastel"]
        return item.colors.contains { color in
            lightColors.contains { color.name.lowercased().contains($0) }
        }
    }
    
    private static func isDarkColor(_ item: WardrobeItem) -> Bool {
        let darkColors = ["black", "navy", "dark", "deep"]
        return item.colors.contains { color in
            darkColors.contains { color.name.lowercased().contains($0) }
        }
    }
    
    private static func hasLightFabric(_ item: WardrobeItem) -> Bool {
        let lightFabrics = ["cotton", "linen", "silk", "chiffon", "georgette"]
        return item.materials.contains { material in
            lightFabrics.contains { material.lowercased().contains($0) }
        }
    }
    
    private static func isDelicateFabric(_ item: WardrobeItem) -> Bool {
        let delicateFabrics = ["silk", "cashmere", "suede", "velvet", "lace"]
        return item.materials.contains { material in
            delicateFabrics.contains { material.lowercased().contains($0) }
        }
    }
    
    private static func isFlowingGarment(_ item: WardrobeItem) -> Bool {
        let flowingTypes = ["dress", "skirt", "scarf", "cape", "poncho"]
        return flowingTypes.contains { type in
            item.subcategory?.lowercased().contains(type) == true ||
            item.name.lowercased().contains(type)
        }
    }
    
    private static func isFormalFootwear(_ item: WardrobeItem) -> Bool {
        guard item.category == .shoes else { return false }
        let formalShoes = ["heels", "dress shoes", "oxfords", "loafers"]
        return formalShoes.contains { type in
            item.subcategory?.lowercased().contains(type.lowercased()) == true ||
            item.name.lowercased().contains(type.lowercased())
        }
    }
    
    private static func isHeavyFabric(_ item: WardrobeItem) -> Bool {
        let heavyFabrics = ["denim", "wool", "leather", "canvas", "corduroy"]
        return item.materials.contains { material in
            heavyFabrics.contains { material.lowercased().contains($0) }
        }
    }
    
    private static func getVersatilityScore(_ item: WardrobeItem) -> Double {
        var score = 0.0
        
        // Neutral colors are more versatile
        if item.colors.contains(where: { ["black", "white", "gray", "navy", "beige"].contains($0.name.lowercased()) }) {
            score += 0.5
        }
        
        // Solid patterns are more versatile
        if item.patterns.contains(.solid) || item.patterns.isEmpty {
            score += 0.3
        }
        
        // Certain categories are more versatile
        switch item.category {
        case .tops, .bottoms:
            score += 0.2
        default:
            break
        }
        
        return score
    }
    
    // Additional helper methods for specific item types
    private static func isItemPerfectForTemperature(_ item: WardrobeItem, temperatureRange: TemperatureCategory) -> Bool {
        switch temperatureRange {
        case .freezing, .cold:
            return isWarmClothing(item) && item.category != .shoes
        case .hot:
            return isLightClothing(item) && isBreathable(item)
        case .mild:
            return isNeutralClothing(item)
        default:
            return false
        }
    }
    
    private static func isItemGoodForTemperature(_ item: WardrobeItem, temperatureRange: TemperatureCategory) -> Bool {
        switch temperatureRange {
        case .freezing, .cold:
            return isWarmClothing(item) || isNeutralClothing(item)
        case .warm, .hot:
            return isLightClothing(item) || (isNeutralClothing(item) && isBreathable(item))
        case .cool, .mild:
            return true
        }
    }
    
    private static func isItemOkayForTemperature(_ item: WardrobeItem, temperatureRange: TemperatureCategory) -> Bool {
        // Basic temperature compatibility
        return true
    }
    
    private static func isHeavyOuterwear(_ item: WardrobeItem) -> Bool {
        let heavyOuterwear = ["coat", "parka", "puffer", "down"]
        return heavyOuterwear.contains { type in
            item.name.lowercased().contains(type) ||
            item.subcategory?.lowercased().contains(type) == true
        }
    }
    
    private static func isMediumOuterwear(_ item: WardrobeItem) -> Bool {
        let mediumOuterwear = ["jacket", "cardigan", "blazer"]
        return mediumOuterwear.contains { type in
            item.name.lowercased().contains(type) ||
            item.subcategory?.lowercased().contains(type) == true
        }
    }
    
    private static func isLightOuterwear(_ item: WardrobeItem) -> Bool {
        let lightOuterwear = ["vest", "light jacket", "windbreaker"]
        return lightOuterwear.contains { type in
            item.name.lowercased().contains(type) ||
            item.subcategory?.lowercased().contains(type) == true
        }
    }
    
    private static func isWindResistant(_ item: WardrobeItem) -> Bool {
        let windResistant = ["windbreaker", "shell", "jacket"]
        return windResistant.contains { type in
            item.name.lowercased().contains(type) ||
            item.subcategory?.lowercased().contains(type) == true
        }
    }
    
    private static func calculateFootwearScore(_ item: WardrobeItem, weather: CurrentWeather) -> Double {
        var score = 1.0
        
        if weather.outfitConditions.contains(.rainy) && isWeatherResistantFootwear(item) {
            score += 2.0
        }
        if weather.temperature > 25 && isBreathableFootwear(item) {
            score += 1.5
        }
        if weather.temperature < 5 && isWarmFootwear(item) {
            score += 2.0
        }
        if item.isFavorite {
            score += 0.5
        }
        
        return score
    }
    
    private static func isWeatherResistantFootwear(_ item: WardrobeItem) -> Bool {
        let weatherResistantShoes = ["boots", "rain boots", "waterproof"]
        return weatherResistantShoes.contains { type in
            item.name.lowercased().contains(type) ||
            item.subcategory?.lowercased().contains(type) == true
        }
    }
    
    private static func isBreathableFootwear(_ item: WardrobeItem) -> Bool {
        let breathableShoes = ["sandals", "canvas", "mesh", "breathable"]
        return breathableShoes.contains { type in
            item.name.lowercased().contains(type) ||
            item.subcategory?.lowercased().contains(type) == true ||
            item.materials.contains { material in material.lowercased().contains(type) }
        }
    }
    
    private static func isWarmFootwear(_ item: WardrobeItem) -> Bool {
        let warmShoes = ["boots", "winter", "wool", "fur", "lined"]
        return warmShoes.contains { type in
            item.name.lowercased().contains(type) ||
            item.subcategory?.lowercased().contains(type) == true ||
            item.materials.contains { material in material.lowercased().contains(type) }
        }
    }
    
    private static func isHatOrSunglasses(_ item: WardrobeItem) -> Bool {
        let sunProtection = ["hat", "cap", "sunglasses", "visor"]
        return sunProtection.contains { type in
            item.name.lowercased().contains(type) ||
            item.subcategory?.lowercased().contains(type) == true
        }
    }
    
    private static func isWarmAccessory(_ item: WardrobeItem) -> Bool {
        let warmAccessories = ["scarf", "gloves", "hat", "beanie", "mittens"]
        return warmAccessories.contains { type in
            item.name.lowercased().contains(type) ||
            item.subcategory?.lowercased().contains(type) == true
        }
    }
    
    private static func isWaterResistantAccessory(_ item: WardrobeItem) -> Bool {
        let waterResistantAccessories = ["umbrella", "waterproof bag", "rain hat"]
        return waterResistantAccessories.contains { type in
            item.name.lowercased().contains(type) ||
            item.subcategory?.lowercased().contains(type) == true
        }
    }
    
    private static func isSecureAccessory(_ item: WardrobeItem) -> Bool {
        let secureAccessories = ["belt", "watch", "small bag"]
        return secureAccessories.contains { type in
            item.name.lowercased().contains(type) ||
            item.subcategory?.lowercased().contains(type) == true
        }
    }
    
    private static func isGeneralAccessory(_ item: WardrobeItem) -> Bool {
        return item.category == .accessories
    }
}

struct RecommendedItems {
    let tops: [WardrobeItem]
    let bottoms: [WardrobeItem]
    let outerwear: [WardrobeItem]
    let shoes: [WardrobeItem]
    let accessories: [WardrobeItem]
    let dresses: [WardrobeItem]
    
    var hasRecommendations: Bool {
        return !tops.isEmpty || !bottoms.isEmpty || !dresses.isEmpty || !shoes.isEmpty
    }
    
    var requiresOuterwear: Bool {
        return !outerwear.isEmpty
    }
}

enum TemperatureCategory {
    case freezing  // < 0°C
    case cold      // 0-10°C
    case cool      // 10-18°C
    case mild      // 18-25°C
    case warm      // 25-30°C
    case hot       // > 30°C
    
    var description: String {
        switch self {
        case .freezing: return "Freezing"
        case .cold: return "Cold"
        case .cool: return "Cool"
        case .mild: return "Mild"
        case .warm: return "Warm"
        case .hot: return "Hot"
        }
    }
    
    var recommendations: [String] {
        switch self {
        case .freezing:
            return ["Heavy coat", "Warm layers", "Insulated boots", "Gloves and scarf"]
        case .cold:
            return ["Warm jacket", "Long sleeves", "Closed shoes", "Light scarf"]
        case .cool:
            return ["Light jacket", "Long sleeves or layering", "Comfortable shoes"]
        case .mild:
            return ["T-shirt or light top", "Light pants or jeans", "Comfortable shoes"]
        case .warm:
            return ["Light breathable fabrics", "Short sleeves", "Breathable shoes"]
        case .hot:
            return ["Very light fabrics", "Minimal coverage", "Breathable footwear", "Sun protection"]
        }
    }
}