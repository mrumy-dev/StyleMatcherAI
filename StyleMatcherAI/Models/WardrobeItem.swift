import Foundation
import SwiftUI

struct WardrobeItem: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let userId: UUID
    let name: String
    let description: String?
    let category: ClothingCategory
    let subcategory: String?
    let brand: String?
    let colors: [ClothingColor]
    let patterns: [ClothingPattern]
    let materials: [String]
    let formality: FormalityLevel
    let season: [Season]
    let occasion: [String]
    let size: ClothingSize?
    let purchaseDate: Date?
    let purchasePrice: Double?
    let currency: String
    let condition: ItemCondition
    let careInstructions: [String]
    let tags: [String]
    let imageURLs: [String]
    let thumbnailURL: String?
    let isFavorite: Bool
    let timesWorn: Int
    let lastWornAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let isArchived: Bool
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case category
        case subcategory
        case brand
        case colors
        case patterns
        case materials
        case formality
        case season
        case occasion
        case size
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case currency
        case condition
        case careInstructions = "care_instructions"
        case tags
        case imageURLs = "image_urls"
        case thumbnailURL = "thumbnail_url"
        case isFavorite = "is_favorite"
        case timesWorn = "times_worn"
        case lastWornAt = "last_worn_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isArchived = "is_archived"
        case notes
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        description: String? = nil,
        category: ClothingCategory,
        subcategory: String? = nil,
        brand: String? = nil,
        colors: [ClothingColor] = [],
        patterns: [ClothingPattern] = [],
        materials: [String] = [],
        formality: FormalityLevel = .casual,
        season: [Season] = [],
        occasion: [String] = [],
        size: ClothingSize? = nil,
        purchaseDate: Date? = nil,
        purchasePrice: Double? = nil,
        currency: String = "USD",
        condition: ItemCondition = .excellent,
        careInstructions: [String] = [],
        tags: [String] = [],
        imageURLs: [String] = [],
        thumbnailURL: String? = nil,
        isFavorite: Bool = false,
        timesWorn: Int = 0,
        lastWornAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.category = category
        self.subcategory = subcategory
        self.brand = brand
        self.colors = colors
        self.patterns = patterns
        self.materials = materials
        self.formality = formality
        self.season = season
        self.occasion = occasion
        self.size = size
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.currency = currency
        self.condition = condition
        self.careInstructions = careInstructions
        self.tags = tags
        self.imageURLs = imageURLs
        self.thumbnailURL = thumbnailURL
        self.isFavorite = isFavorite
        self.timesWorn = timesWorn
        self.lastWornAt = lastWornAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.notes = notes
    }
}

enum ClothingCategory: String, Codable, CaseIterable {
    case tops = "tops"
    case bottoms = "bottoms"
    case outerwear = "outerwear"
    case dresses = "dresses"
    case shoes = "shoes"
    case accessories = "accessories"
    case underwear = "underwear"
    case activewear = "activewear"
    case sleepwear = "sleepwear"
    case swimwear = "swimwear"
    
    var displayName: String {
        switch self {
        case .tops:
            return "Tops"
        case .bottoms:
            return "Bottoms"
        case .outerwear:
            return "Outerwear"
        case .dresses:
            return "Dresses"
        case .shoes:
            return "Shoes"
        case .accessories:
            return "Accessories"
        case .underwear:
            return "Underwear"
        case .activewear:
            return "Activewear"
        case .sleepwear:
            return "Sleepwear"
        case .swimwear:
            return "Swimwear"
        }
    }
    
    var subcategories: [String] {
        switch self {
        case .tops:
            return ["T-shirt", "Shirt", "Blouse", "Sweater", "Tank Top", "Hoodie", "Cardigan", "Blazer", "Vest", "Tube Top", "Crop Top"]
        case .bottoms:
            return ["Jeans", "Trousers", "Shorts", "Skirt", "Leggings", "Sweatpants", "Chinos", "Culottes", "Capris"]
        case .outerwear:
            return ["Jacket", "Coat", "Trench Coat", "Puffer Jacket", "Windbreaker", "Poncho", "Cape", "Parka"]
        case .dresses:
            return ["Casual Dress", "Formal Dress", "Cocktail Dress", "Maxi Dress", "Mini Dress", "Midi Dress", "Wrap Dress", "Shift Dress"]
        case .shoes:
            return ["Sneakers", "Boots", "Heels", "Flats", "Sandals", "Loafers", "Oxfords", "Athletic Shoes", "Slippers"]
        case .accessories:
            return ["Hat", "Scarf", "Belt", "Bag", "Jewelry", "Sunglasses", "Watch", "Gloves", "Tie", "Bow Tie"]
        case .underwear:
            return ["Bra", "Panties", "Boxers", "Briefs", "Undershirt", "Shapewear", "Sports Bra"]
        case .activewear:
            return ["Sports Bra", "Athletic Top", "Yoga Pants", "Shorts", "Track Suit", "Athletic Shoes", "Swimsuit"]
        case .sleepwear:
            return ["Pajamas", "Nightgown", "Robe", "Sleep Shirt", "Sleep Shorts"]
        case .swimwear:
            return ["Bikini", "One-piece", "Swim Shorts", "Swim Trunks", "Cover-up", "Rashguard"]
        }
    }
}

struct ClothingColor: Codable, Equatable, Hashable {
    let name: String
    let hexCode: String?
    let isPrimary: Bool
    
    init(name: String, hexCode: String? = nil, isPrimary: Bool = false) {
        self.name = name
        self.hexCode = hexCode
        self.isPrimary = isPrimary
    }
    
    static let commonColors: [ClothingColor] = [
        ClothingColor(name: "Black", hexCode: "#000000"),
        ClothingColor(name: "White", hexCode: "#FFFFFF"),
        ClothingColor(name: "Gray", hexCode: "#808080"),
        ClothingColor(name: "Navy", hexCode: "#000080"),
        ClothingColor(name: "Blue", hexCode: "#0000FF"),
        ClothingColor(name: "Red", hexCode: "#FF0000"),
        ClothingColor(name: "Green", hexCode: "#008000"),
        ClothingColor(name: "Yellow", hexCode: "#FFFF00"),
        ClothingColor(name: "Orange", hexCode: "#FFA500"),
        ClothingColor(name: "Purple", hexCode: "#800080"),
        ClothingColor(name: "Pink", hexCode: "#FFC0CB"),
        ClothingColor(name: "Brown", hexCode: "#A52A2A"),
        ClothingColor(name: "Beige", hexCode: "#F5F5DC"),
        ClothingColor(name: "Cream", hexCode: "#FFFDD0"),
        ClothingColor(name: "Khaki", hexCode: "#F0E68C")
    ]
}

enum ClothingPattern: String, Codable, CaseIterable {
    case solid = "solid"
    case stripes = "stripes"
    case polkaDots = "polka_dots"
    case floral = "floral"
    case plaid = "plaid"
    case checkered = "checkered"
    case geometric = "geometric"
    case abstract = "abstract"
    case animal = "animal"
    case paisley = "paisley"
    case houndstooth = "houndstooth"
    case argyle = "argyle"
    case camouflage = "camouflage"
    case tribal = "tribal"
    case vintage = "vintage"
    
    var displayName: String {
        switch self {
        case .solid:
            return "Solid"
        case .stripes:
            return "Stripes"
        case .polkaDots:
            return "Polka Dots"
        case .floral:
            return "Floral"
        case .plaid:
            return "Plaid"
        case .checkered:
            return "Checkered"
        case .geometric:
            return "Geometric"
        case .abstract:
            return "Abstract"
        case .animal:
            return "Animal Print"
        case .paisley:
            return "Paisley"
        case .houndstooth:
            return "Houndstooth"
        case .argyle:
            return "Argyle"
        case .camouflage:
            return "Camouflage"
        case .tribal:
            return "Tribal"
        case .vintage:
            return "Vintage"
        }
    }
}

struct ClothingSize: Codable, Equatable, Hashable {
    let system: SizeSystem
    let value: String
    let numericValue: Double?
    
    init(system: SizeSystem, value: String, numericValue: Double? = nil) {
        self.system = system
        self.value = value
        self.numericValue = numericValue
    }
}

enum SizeSystem: String, Codable, CaseIterable {
    case us = "us"
    case uk = "uk"
    case eu = "eu"
    case international = "international"
    case numeric = "numeric"
    
    var displayName: String {
        switch self {
        case .us:
            return "US"
        case .uk:
            return "UK"
        case .eu:
            return "EU"
        case .international:
            return "International"
        case .numeric:
            return "Numeric"
        }
    }
}

enum Season: String, Codable, CaseIterable {
    case spring = "spring"
    case summer = "summer"
    case fall = "fall"
    case winter = "winter"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    static var current: Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:
            return .spring
        case 6...8:
            return .summer
        case 9...11:
            return .fall
        default:
            return .winter
        }
    }
}

enum ItemCondition: String, Codable, CaseIterable {
    case new = "new"
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .new:
            return "New"
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .fair:
            return "Fair"
        case .poor:
            return "Poor"
        }
    }
    
    var color: Color {
        switch self {
        case .new, .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .poor:
            return .red
        }
    }
}

extension WardrobeItem {
    var primaryColor: ClothingColor? {
        return colors.first { $0.isPrimary } ?? colors.first
    }
    
    var displayColors: String {
        let colorNames = colors.map { $0.name }
        return colorNames.joined(separator: ", ")
    }
    
    var displayPatterns: String {
        let patternNames = patterns.map { $0.displayName }
        return patternNames.joined(separator: ", ")
    }
    
    var isRecentlyAdded: Bool {
        return Calendar.current.isDate(createdAt, inSameDayAs: Date()) ||
               createdAt > Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    }
    
    var isFrequentlyWorn: Bool {
        return timesWorn > 10
    }
    
    var needsAttention: Bool {
        return condition == .fair || condition == .poor
    }
    
    mutating func markAsWorn() {
        timesWorn += 1
        lastWornAt = Date()
        updatedAt = Date()
    }
    
    func isAppropriateFor(season: Season) -> Bool {
        return self.season.isEmpty || self.season.contains(season)
    }
    
    func isAppropriateFor(formality: FormalityLevel) -> Bool {
        switch (self.formality, formality) {
        case (.casual, _):
            return formality == .casual || formality == .mixed
        case (.smartCasual, _):
            return [.casual, .smartCasual, .mixed].contains(formality)
        case (.business, _):
            return [.smartCasual, .business, .mixed].contains(formality)
        case (.formal, _):
            return [.business, .formal, .mixed].contains(formality)
        case (.mixed, _):
            return true
        }
    }
}