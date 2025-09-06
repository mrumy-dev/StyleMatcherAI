import Foundation
import SwiftUI

struct Outfit: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let userId: UUID
    let name: String
    let description: String?
    let items: [WardrobeItem]
    let occasion: [String]
    let season: [Season]
    let formality: FormalityLevel
    let weather: [WeatherCondition]
    let tags: [String]
    let isFavorite: Bool
    let timesWorn: Int
    let lastWornAt: Date?
    let imageURL: String?
    let createdAt: Date
    let updatedAt: Date
    let creator: OutfitCreator
    let isPublic: Bool
    let rating: Double?
    
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
        case isFavorite = "is_favorite"
        case timesWorn = "times_worn"
        case lastWornAt = "last_worn_at"
        case imageURL = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case creator
        case isPublic = "is_public"
        case rating
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        description: String? = nil,
        items: [WardrobeItem],
        occasion: [String] = [],
        season: [Season] = [],
        formality: FormalityLevel = .casual,
        weather: [WeatherCondition] = [],
        tags: [String] = [],
        isFavorite: Bool = false,
        timesWorn: Int = 0,
        lastWornAt: Date? = nil,
        imageURL: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        creator: OutfitCreator = .user,
        isPublic: Bool = false,
        rating: Double? = nil
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
        self.isFavorite = isFavorite
        self.timesWorn = timesWorn
        self.lastWornAt = lastWornAt
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.creator = creator
        self.isPublic = isPublic
        self.rating = rating
    }
}

enum OutfitCreator: String, Codable, CaseIterable {
    case user = "user"
    case ai = "ai"
    case stylist = "stylist"
    case community = "community"
    
    var displayName: String {
        switch self {
        case .user:
            return "You"
        case .ai:
            return "AI Assistant"
        case .stylist:
            return "Personal Stylist"
        case .community:
            return "Community"
        }
    }
    
    var icon: String {
        switch self {
        case .user:
            return "person.circle"
        case .ai:
            return "cpu"
        case .stylist:
            return "person.badge.key"
        case .community:
            return "person.3"
        }
    }
}

enum WeatherCondition: String, Codable, CaseIterable {
    case sunny = "sunny"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case snowy = "snowy"
    case windy = "windy"
    case hot = "hot"
    case cold = "cold"
    case humid = "humid"
    case dry = "dry"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .sunny:
            return "sun.max"
        case .cloudy:
            return "cloud"
        case .rainy:
            return "cloud.rain"
        case .snowy:
            return "cloud.snow"
        case .windy:
            return "wind"
        case .hot:
            return "thermometer.sun"
        case .cold:
            return "thermometer.snowflake"
        case .humid:
            return "humidity"
        case .dry:
            return "aqi.low"
        }
    }
}

extension Outfit {
    var primaryColors: [ClothingColor] {
        return items.compactMap { $0.primaryColor }
    }
    
    var allColors: [ClothingColor] {
        return items.flatMap { $0.colors }
    }
    
    var categories: Set<ClothingCategory> {
        return Set(items.map { $0.category })
    }
    
    var totalValue: Double {
        return items.compactMap { $0.purchasePrice }.reduce(0, +)
    }
    
    var isComplete: Bool {
        let hasTop = items.contains { $0.category == .tops || $0.category == .dresses }
        let hasBottom = items.contains { $0.category == .bottoms || $0.category == .dresses }
        let hasShoes = items.contains { $0.category == .shoes }
        
        return hasTop && hasBottom && hasShoes
    }
    
    mutating func markAsWorn() {
        timesWorn += 1
        lastWornAt = Date()
        updatedAt = Date()
    }
}

