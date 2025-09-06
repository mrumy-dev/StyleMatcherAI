import Foundation
import Supabase

protocol OutfitRepositoryProtocol {
    func createOutfit(_ outfit: Outfit) async throws -> Outfit
    func getOutfit(id: UUID) async throws -> Outfit?
    func getOutfits(for userId: UUID) async throws -> [Outfit]
    func updateOutfit(_ outfit: Outfit) async throws -> Outfit
    func deleteOutfit(id: UUID) async throws
    func searchOutfits(for userId: UUID, query: String) async throws -> [Outfit]
    func getOutfitsByOccasion(for userId: UUID, occasion: String) async throws -> [Outfit]
    func getOutfitsBySeason(for userId: UUID, season: Season) async throws -> [Outfit]
    func getFavoriteOutfits(for userId: UUID) async throws -> [Outfit]
    func getRecentOutfits(for userId: UUID, limit: Int) async throws -> [Outfit]
    func markOutfitAsWorn(id: UUID, rating: Int?) async throws
}

final class OutfitRepository: OutfitRepositoryProtocol {
    private let supabase = SupabaseClient.shared.database
    private let tableName = "outfits"
    
    func createOutfit(_ outfit: Outfit) async throws -> Outfit {
        let response = try await supabase
            .from(tableName)
            .insert(outfit)
            .select()
            .single()
            .execute()
        
        return try response.value
    }
    
    func getOutfit(id: UUID) async throws -> Outfit? {
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
    
    func getOutfits(for userId: UUID) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func updateOutfit(_ outfit: Outfit) async throws -> Outfit {
        var updatedOutfit = outfit
        updatedOutfit = Outfit(
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
            color: outfit.color,
            style: outfit.style,
            imageURL: outfit.imageURL,
            thumbnailURL: outfit.thumbnailURL,
            isFavorite: outfit.isFavorite,
            isPublic: outfit.isPublic,
            timesWorn: outfit.timesWorn,
            lastWornAt: outfit.lastWornAt,
            rating: outfit.rating,
            notes: outfit.notes,
            createdAt: outfit.createdAt,
            updatedAt: Date(),
            createdBy: outfit.createdBy,
            aiGeneratedScore: outfit.aiGeneratedScore,
            aiStyleTips: outfit.aiStyleTips
        )
        
        let response = try await supabase
            .from(tableName)
            .update(updatedOutfit)
            .eq("id", value: outfit.id)
            .select()
            .single()
            .execute()
        
        return try response.value
    }
    
    func deleteOutfit(id: UUID) async throws {
        try await supabase
            .from(tableName)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    func searchOutfits(for userId: UUID, query: String) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .or("name.ilike.%\(query)%,description.ilike.%\(query)%,tags.cs.{\"\(query)\"}")
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getOutfitsByOccasion(for userId: UUID, occasion: String) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .contains("occasion", value: [occasion])
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getOutfitsBySeason(for userId: UUID, season: Season) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .contains("season", value: [season.rawValue])
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getFavoriteOutfits(for userId: UUID) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("is_favorite", value: true)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getRecentOutfits(for userId: UUID, limit: Int = 10) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        
        return try response.value
    }
    
    func markOutfitAsWorn(id: UUID, rating: Int? = nil) async throws {
        var updates: [String: AnyJSON] = [
            "times_worn": AnyJSON("times_worn + 1"),
            "last_worn_at": AnyJSON(Date()),
            "updated_at": AnyJSON(Date())
        ]
        
        if let rating = rating {
            updates["rating"] = AnyJSON(rating)
        }
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: id)
            .execute()
    }
}

extension OutfitRepository {
    func getOutfitsByFormality(for userId: UUID, formality: FormalityLevel) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("formality", value: formality.rawValue)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getOutfitsByCreator(for userId: UUID, creator: OutfitCreator) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("created_by", value: creator.rawValue)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getPublicOutfits(limit: Int = 20, offset: Int = 0) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .limit(limit)
            .range(from: offset, to: offset + limit - 1)
            .execute()
        
        return try response.value
    }
    
    func getTopRatedOutfits(for userId: UUID, limit: Int = 10) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .not("rating", operator: .is, value: "null")
            .order("rating", ascending: false)
            .order("times_worn", ascending: false)
            .limit(limit)
            .execute()
        
        return try response.value
    }
    
    func getMostWornOutfits(for userId: UUID, limit: Int = 10) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .order("times_worn", ascending: false)
            .limit(limit)
            .execute()
        
        return try response.value
    }
    
    func getUnwornOutfits(for userId: UUID) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("times_worn", value: 0)
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getOutfitsContainingItem(for userId: UUID, itemId: UUID) async throws -> [Outfit] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .contains("items", value: [["wardrobe_item_id": itemId.uuidString]])
            .order("created_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getOutfitsForWeather(
        for userId: UUID,
        weather: WeatherCondition,
        limit: Int = 10
    ) async throws -> [Outfit] {
        let tempRange = weather.temperature
        
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .gte("weather->temperature->min", value: tempRange.min - 5)
            .lte("weather->temperature->max", value: tempRange.max + 5)
            .order("ai_generated_score", ascending: false)
            .limit(limit)
            .execute()
        
        return try response.value
    }
    
    func getOutfitRecommendations(
        for userId: UUID,
        occasion: [String] = [],
        season: Season? = nil,
        formality: FormalityLevel? = nil,
        weather: WeatherCondition? = nil,
        limit: Int = 10
    ) async throws -> [Outfit] {
        var query = supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
        
        if !occasion.isEmpty {
            let occasionFilter = occasion.map { "occasion.cs.{\"\($0)\"}" }.joined(separator: ",")
            query = query.or(occasionFilter)
        }
        
        if let season = season {
            query = query.contains("season", value: [season.rawValue])
        }
        
        if let formality = formality {
            query = query.eq("formality", value: formality.rawValue)
        }
        
        query = query
            .order("ai_generated_score", ascending: false)
            .order("rating", ascending: false)
            .limit(limit)
        
        let response = try await query.execute()
        return try response.value
    }
    
    func updateOutfitAIScore(id: UUID, score: Double, tips: [String]) async throws {
        let updates: [String: AnyJSON] = [
            "ai_generated_score": AnyJSON(score),
            "ai_style_tips": AnyJSON(tips),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: id)
            .execute()
    }
    
    func toggleFavorite(id: UUID) async throws -> Bool {
        let outfit = try await getOutfit(id: id)
        guard let currentOutfit = outfit else {
            throw RepositoryError.itemNotFound
        }
        
        let newFavoriteStatus = !currentOutfit.isFavorite
        
        let updates: [String: AnyJSON] = [
            "is_favorite": AnyJSON(newFavoriteStatus),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: id)
            .execute()
        
        return newFavoriteStatus
    }
    
    func updateOutfitVisibility(id: UUID, isPublic: Bool) async throws {
        let updates: [String: AnyJSON] = [
            "is_public": AnyJSON(isPublic),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: id)
            .execute()
    }
    
    func duplicateOutfit(id: UUID, newName: String) async throws -> Outfit {
        guard let originalOutfit = try await getOutfit(id: id) else {
            throw RepositoryError.itemNotFound
        }
        
        let duplicatedOutfit = Outfit(
            userId: originalOutfit.userId,
            name: newName,
            description: originalOutfit.description,
            items: originalOutfit.items,
            occasion: originalOutfit.occasion,
            season: originalOutfit.season,
            formality: originalOutfit.formality,
            weather: originalOutfit.weather,
            tags: originalOutfit.tags,
            color: originalOutfit.color,
            style: originalOutfit.style,
            createdBy: .user,
            aiGeneratedScore: originalOutfit.aiGeneratedScore,
            aiStyleTips: originalOutfit.aiStyleTips
        )
        
        return try await createOutfit(duplicatedOutfit)
    }
    
    func getOutfitStats(for userId: UUID) async throws -> OutfitStats {
        let response = try await supabase
            .rpc("get_outfit_stats", parameters: ["user_id": userId])
            .execute()
        
        return try response.value
    }
}

struct OutfitStats: Codable {
    let totalOutfits: Int
    let favoriteOutfits: Int
    let publicOutfits: Int
    let aiGeneratedOutfits: Int
    let userCreatedOutfits: Int
    let totalWears: Int
    let averageRating: Double?
    let mostWornOutfit: UUID?
    let favoriteFormality: String?
    let favoriteOccasion: String?
    let outfitsThisMonth: Int
    let outfitsThisWeek: Int
    
    enum CodingKeys: String, CodingKey {
        case totalOutfits = "total_outfits"
        case favoriteOutfits = "favorite_outfits"
        case publicOutfits = "public_outfits"
        case aiGeneratedOutfits = "ai_generated_outfits"
        case userCreatedOutfits = "user_created_outfits"
        case totalWears = "total_wears"
        case averageRating = "average_rating"
        case mostWornOutfit = "most_worn_outfit"
        case favoriteFormality = "favorite_formality"
        case favoriteOccasion = "favorite_occasion"
        case outfitsThisMonth = "outfits_this_month"
        case outfitsThisWeek = "outfits_this_week"
    }
}

enum RepositoryError: LocalizedError {
    case itemNotFound
    case invalidData
    case unauthorized
    case networkError
    case databaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found"
        case .invalidData:
            return "Invalid data provided"
        case .unauthorized:
            return "Unauthorized access"
        case .networkError:
            return "Network connection error"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}