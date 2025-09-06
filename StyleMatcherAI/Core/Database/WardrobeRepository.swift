import Foundation
import Supabase

protocol WardrobeRepositoryProtocol {
    func createItem(_ item: WardrobeItem) async throws -> WardrobeItem
    func getItem(id: UUID) async throws -> WardrobeItem?
    func getItems(for userId: UUID) async throws -> [WardrobeItem]
    func updateItem(_ item: WardrobeItem) async throws -> WardrobeItem
    func deleteItem(id: UUID) async throws
    func searchItems(for userId: UUID, query: String) async throws -> [WardrobeItem]
    func getItemsByCategory(for userId: UUID, category: ClothingCategory) async throws -> [WardrobeItem]
    func getItemsByColor(for userId: UUID, colors: [String]) async throws -> [WardrobeItem]
    func getFavoriteItems(for userId: UUID) async throws -> [WardrobeItem]
    func getRecentlyAddedItems(for userId: UUID, limit: Int) async throws -> [WardrobeItem]
    func markItemAsWorn(id: UUID) async throws
    func updateItemImages(id: UUID, imageURLs: [String], thumbnailURL: String?) async throws
}

final class WardrobeRepository: WardrobeRepositoryProtocol {
    private let supabase = SupabaseClient.shared.database
    private let tableName = "wardrobe_items"
    
    func createItem(_ item: WardrobeItem) async throws -> WardrobeItem {
        let response = try await supabase
            .from(tableName)
            .insert(item)
            .select()
            .single()
            .execute()
        
        return try response.value
    }
    
    func getItem(id: UUID) async throws -> WardrobeItem? {
        do {
            let response = try await supabase
                .from(tableName)
                .select()
                .eq("id", value: id)
                .single()
                .execute()
            
            return try response.value
        } catch {
            if error.localizedDescription.contains("PGRST116") {
                return nil
            }
            throw error
        }
    }
    
    func getItems(for userId: UUID) async throws -> [WardrobeItem] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func updateItem(_ item: WardrobeItem) async throws -> WardrobeItem {
        var updatedItem = item
        updatedItem = WardrobeItem(
            id: item.id,
            userId: item.userId,
            name: item.name,
            description: item.description,
            category: item.category,
            subcategory: item.subcategory,
            brand: item.brand,
            colors: item.colors,
            patterns: item.patterns,
            materials: item.materials,
            formality: item.formality,
            season: item.season,
            occasion: item.occasion,
            size: item.size,
            purchaseDate: item.purchaseDate,
            purchasePrice: item.purchasePrice,
            currency: item.currency,
            condition: item.condition,
            careInstructions: item.careInstructions,
            tags: item.tags,
            imageURLs: item.imageURLs,
            thumbnailURL: item.thumbnailURL,
            isFavorite: item.isFavorite,
            timesWorn: item.timesWorn,
            lastWornAt: item.lastWornAt,
            createdAt: item.createdAt,
            updatedAt: Date(),
            isArchived: item.isArchived,
            notes: item.notes
        )
        
        let response = try await supabase
            .from(tableName)
            .update(updatedItem)
            .eq("id", value: item.id)
            .select()
            .single()
            .execute()
        
        return try response.value
    }
    
    func deleteItem(id: UUID) async throws {
        try await supabase
            .from(tableName)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    func searchItems(for userId: UUID, query: String) async throws -> [WardrobeItem] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: false)
            .or("name.ilike.%\(query)%,description.ilike.%\(query)%,brand.ilike.%\(query)%,tags.cs.{\"\(query)\"}")
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getItemsByCategory(for userId: UUID, category: ClothingCategory) async throws -> [WardrobeItem] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("category", value: category.rawValue)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getItemsByColor(for userId: UUID, colors: [String]) async throws -> [WardrobeItem] {
        let colorFilter = colors.map { "colors.cs.{\"\($0)\"}" }.joined(separator: ",")
        
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: false)
            .or(colorFilter)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getFavoriteItems(for userId: UUID) async throws -> [WardrobeItem] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_favorite", value: true)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getRecentlyAddedItems(for userId: UUID, limit: Int = 10) async throws -> [WardrobeItem] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        
        return try response.value
    }
    
    func markItemAsWorn(id: UUID) async throws {
        let updates: [String: AnyJSON] = [
            "times_worn": AnyJSON("times_worn + 1"),
            "last_worn_at": AnyJSON(Date()),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: id)
            .execute()
    }
    
    func updateItemImages(id: UUID, imageURLs: [String], thumbnailURL: String?) async throws {
        let updates: [String: AnyJSON] = [
            "image_urls": AnyJSON(imageURLs),
            "thumbnail_url": AnyJSON(thumbnailURL),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: id)
            .execute()
    }
}

extension WardrobeRepository {
    func getItemsForOutfit(
        for userId: UUID,
        category: ClothingCategory? = nil,
        formality: FormalityLevel? = nil,
        season: Season? = nil,
        colors: [String] = [],
        excludeItems: [UUID] = []
    ) async throws -> [WardrobeItem] {
        var query = supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: false)
        
        if let category = category {
            query = query.eq("category", value: category.rawValue)
        }
        
        if let formality = formality {
            query = query.eq("formality", value: formality.rawValue)
        }
        
        if let season = season {
            query = query.contains("season", value: [season.rawValue])
        }
        
        if !colors.isEmpty {
            let colorFilter = colors.map { "colors.cs.{\"\($0)\"}" }.joined(separator: ",")
            query = query.or(colorFilter)
        }
        
        if !excludeItems.isEmpty {
            let excludeFilter = excludeItems.map { "id.neq.\($0)" }.joined(separator: ",")
            query = query.or(excludeFilter)
        }
        
        query = query.order("times_worn", ascending: true)
        
        let response = try await query.execute()
        return try response.value
    }
    
    func getItemsByPattern(for userId: UUID, patterns: [ClothingPattern]) async throws -> [WardrobeItem] {
        let patternFilters = patterns.map { "patterns.cs.{\"\($0.rawValue)\"}" }.joined(separator: ",")
        
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: false)
            .or(patternFilters)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getItemsByBrand(for userId: UUID, brand: String) async throws -> [WardrobeItem] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("brand", value: brand)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getItemsByCondition(for userId: UUID, condition: ItemCondition) async throws -> [WardrobeItem] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("condition", value: condition.rawValue)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getItemsNeedingAttention(for userId: UUID) async throws -> [WardrobeItem] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: false)
            .in("condition", values: [ItemCondition.fair.rawValue, ItemCondition.poor.rawValue])
            .order("condition", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getMostWornItems(for userId: UUID, limit: Int = 10) async throws -> [WardrobeItem] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: false)
            .order("times_worn", ascending: false)
            .limit(limit)
            .execute()
        
        return try response.value
    }
    
    func getLeastWornItems(for userId: UUID, limit: Int = 10) async throws -> [WardrobeItem] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: false)
            .order("times_worn", ascending: true)
            .limit(limit)
            .execute()
        
        return try response.value
    }
    
    func archiveItem(id: UUID) async throws {
        let updates: [String: AnyJSON] = [
            "is_archived": AnyJSON(true),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: id)
            .execute()
    }
    
    func unarchiveItem(id: UUID) async throws {
        let updates: [String: AnyJSON] = [
            "is_archived": AnyJSON(false),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: id)
            .execute()
    }
    
    func getArchivedItems(for userId: UUID) async throws -> [WardrobeItem] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: true)
            .order("updated_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getWardrobeStats(for userId: UUID) async throws -> WardrobeStats {
        let response = try await supabase
            .rpc("get_wardrobe_stats", parameters: ["user_id": userId])
            .execute()
        
        return try response.value
    }
}

struct WardrobeStats: Codable {
    let totalItems: Int
    let itemsByCategory: [String: Int]
    let favoriteItems: Int
    let averageTimesWorn: Double
    let mostWornCategory: String?
    let leastWornCategory: String?
    let totalValue: Double?
    let newestItem: Date?
    let oldestItem: Date?
    let itemsNeedingAttention: Int
    
    enum CodingKeys: String, CodingKey {
        case totalItems = "total_items"
        case itemsByCategory = "items_by_category"
        case favoriteItems = "favorite_items"
        case averageTimesWorn = "average_times_worn"
        case mostWornCategory = "most_worn_category"
        case leastWornCategory = "least_worn_category"
        case totalValue = "total_value"
        case newestItem = "newest_item"
        case oldestItem = "oldest_item"
        case itemsNeedingAttention = "items_needing_attention"
    }
}