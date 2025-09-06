import Foundation
import SwiftUI

struct Outfit: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let name: String
    let description: String?
    let items: [OutfitItem]
    let occasion: [String]
    let season: [Season]
    let formality: FormalityLevel
    let weather: WeatherCondition?
    let tags: [String]
    let color: OutfitColor?
    let style: String?
    let imageURL: String?
    let thumbnailURL: String?
    let isFavorite: Bool
    let isPublic: Bool
    let timesWorn: Int
    let lastWornAt: Date?
    let rating: Int?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let createdBy: OutfitCreator
    let aiGeneratedScore: Double?
    let aiStyleTips: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case items
        case occasion
        case season
        case formality
        case weather
        case tags
        case color
        case style
        case imageURL = "image_url"
        case thumbnailURL = "thumbnail_url"
        case isFavorite = "is_favorite"
        case isPublic = "is_public"
        case timesWorn = "times_worn"
        case lastWornAt = "last_worn_at"
        case rating
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
        case aiGeneratedScore = "ai_generated_score"
        case aiStyleTips = "ai_style_tips"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        description: String? = nil,
        items: [OutfitItem] = [],
        occasion: [String] = [],
        season: [Season] = [],
        formality: FormalityLevel = .casual,
        weather: WeatherCondition? = nil,
        tags: [String] = [],
        color: OutfitColor? = nil,
        style: String? = nil,
        imageURL: String? = nil,
        thumbnailURL: String? = nil,
        isFavorite: Bool = false,
        isPublic: Bool = false,
        timesWorn: Int = 0,
        lastWornAt: Date? = nil,
        rating: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        createdBy: OutfitCreator = .user,
        aiGeneratedScore: Double? = nil,
        aiStyleTips: [String] = []
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.items = items
        self.occasion = occasion
        self.season = season
        self.formality = formality
        self.weather = weather
        self.tags = tags
        self.color = color
        self.style = style
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.isFavorite = isFavorite
        self.isPublic = isPublic
        self.timesWorn = timesWorn
        self.lastWornAt = lastWornAt
        self.rating = rating
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.aiGeneratedScore = aiGeneratedScore
        self.aiStyleTips = aiStyleTips
    }
}

struct OutfitItem: Codable, Identifiable, Equatable {
    let id: UUID
    let wardrobeItemId: UUID
    let position: ItemPosition
    let isOptional: Bool
    let alternatives: [UUID]
    
    enum CodingKeys: String, CodingKey {
        case id
        case wardrobeItemId = "wardrobe_item_id"
        case position
        case isOptional = "is_optional"
        case alternatives
    }
    
    init(
        id: UUID = UUID(),
        wardrobeItemId: UUID,
        position: ItemPosition,
        isOptional: Bool = false,
        alternatives: [UUID] = []
    ) {
        self.id = id
        self.wardrobeItemId = wardrobeItemId
        self.position = position
        self.isOptional = isOptional
        self.alternatives = alternatives
    }
}

enum ItemPosition: String, Codable, CaseIterable {
    case headwear = "headwear"
    case top = "top"
    case middle = "middle"
    case bottom = "bottom"
    case footwear = "footwear"
    case accessories = "accessories"
    case outerwear = "outerwear"
    case underwear = "underwear"
    
    var displayName: String {
        switch self {
        case .headwear:
            return "Headwear"
        case .top:
            return "Top"
        case .middle:
            return "Middle Layer"
        case .bottom:
            return "Bottom"
        case .footwear:
            return "Footwear"
        case .accessories:
            return "Accessories"
        case .outerwear:
            return "Outerwear"
        case .underwear:
            return "Underwear"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .headwear:
            return 0
        case .outerwear:
            return 1
        case .top:
            return 2
        case .middle:
            return 3
        case .bottom:
            return 4
        case .footwear:
            return 5
        case .accessories:
            return 6
        case .underwear:
            return 7
        }
    }
}

enum OutfitCreator: String, Codable, CaseIterable {
    case user = "user"
    case ai = "ai"
    case collaborative = "collaborative"
    
    var displayName: String {
        switch self {
        case .user:
            return "User Created"
        case .ai:
            return "AI Generated"
        case .collaborative:
            return "User + AI"
        }
    }
}

struct OutfitColor: Codable, Equatable {
    let primary: ClothingColor
    let secondary: [ClothingColor]
    let accent: ClothingColor?
    
    init(primary: ClothingColor, secondary: [ClothingColor] = [], accent: ClothingColor? = nil) {
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
    }
}

struct WeatherCondition: Codable, Equatable {
    let temperature: TemperatureRange
    let condition: WeatherType
    let humidity: Double?
    let windSpeed: Double?
    let precipitation: PrecipitationType?
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case condition
        case humidity
        case windSpeed = "wind_speed"
        case precipitation
    }
}

struct TemperatureRange: Codable, Equatable {
    let min: Double
    let max: Double
    let unit: TemperatureUnit
    
    var average: Double {
        return (min + max) / 2
    }
    
    var displayRange: String {
        return "\(Int(min))°-\(Int(max))° \(unit.displayName)"
    }
}

enum TemperatureUnit: String, Codable, CaseIterable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"
    
    var displayName: String {
        switch self {
        case .celsius:
            return "C"
        case .fahrenheit:
            return "F"
        }
    }
}

enum WeatherType: String, Codable, CaseIterable {
    case sunny = "sunny"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case snowy = "snowy"
    case windy = "windy"
    case stormy = "stormy"
    case foggy = "foggy"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .sunny:
            return "☀️"
        case .cloudy:
            return "☁️"
        case .rainy:
            return "🌧️"
        case .snowy:
            return "❄️"
        case .windy:
            return "💨"
        case .stormy:
            return "⛈️"
        case .foggy:
            return "🌫️"
        }
    }
}

enum PrecipitationType: String, Codable, CaseIterable {
    case none = "none"
    case light = "light"
    case moderate = "moderate"
    case heavy = "heavy"
    
    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .light:
            return "Light"
        case .moderate:
            return "Moderate"
        case .heavy:
            return "Heavy"
        }
    }
}

extension Outfit {
    var itemsByPosition: [ItemPosition: [OutfitItem]] {
        return Dictionary(grouping: items, by: { $0.position })
    }
    
    var sortedItems: [OutfitItem] {
        return items.sorted { $0.position.sortOrder < $1.position.sortOrder }
    }
    
    var totalItems: Int {
        return items.count
    }
    
    var requiredItems: [OutfitItem] {
        return items.filter { !$0.isOptional }
    }
    
    var optionalItems: [OutfitItem] {
        return items.filter { $0.isOptional }
    }
    
    var isComplete: Bool {
        return !requiredItems.isEmpty
    }
    
    var averageRating: Double? {
        guard let rating = rating else { return nil }
        return Double(rating) / 5.0
    }
    
    var isRecentlyCreated: Bool {
        return Calendar.current.isDate(createdAt, inSameDayAs: Date()) ||
               createdAt > Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    }
    
    var isFrequentlyWorn: Bool {
        return timesWorn > 5
    }
    
    var needsRating: Bool {
        return rating == nil && timesWorn > 0
    }
    
    mutating func markAsWorn(rating: Int? = nil) {
        timesWorn += 1
        lastWornAt = Date()
        if let rating = rating {
            self.rating = rating
        }
        updatedAt = Date()
    }
    
    func isAppropriateFor(weather: WeatherCondition) -> Bool {
        guard let outfitWeather = self.weather else { return true }
        
        let temperatureMatch = abs(outfitWeather.temperature.average - weather.temperature.average) <= 10
        let conditionMatch = outfitWeather.condition == weather.condition
        
        return temperatureMatch || conditionMatch
    }
    
    func isAppropriateFor(season: Season) -> Bool {
        return self.season.isEmpty || self.season.contains(season)
    }
    
    func isAppropriateFor(occasions: [String]) -> Bool {
        return occasion.isEmpty || !Set(occasion).isDisjoint(with: Set(occasions))
    }
    
    func canAddItem(_ item: OutfitItem) -> Bool {
        let existingPositions = items.map { $0.position }
        
        switch item.position {
        case .top, .bottom, .footwear:
            return !existingPositions.contains(item.position) || item.isOptional
        case .accessories, .outerwear:
            return true
        case .headwear:
            return !existingPositions.contains(.headwear) || item.isOptional
        case .middle, .underwear:
            return true
        }
    }
    
    mutating func addItem(_ item: OutfitItem) -> Bool {
        guard canAddItem(item) else { return false }
        items.append(item)
        updatedAt = Date()
        return true
    }
    
    mutating func removeItem(withId id: UUID) {
        items.removeAll { $0.id == id }
        updatedAt = Date()
    }
    
    mutating func replaceItem(withId id: UUID, with newItem: OutfitItem) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return false }
        items[index] = newItem
        updatedAt = Date()
        return true
    }
}