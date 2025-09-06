import Foundation
import Supabase

protocol OutfitHistoryRepositoryProtocol {
    func createHistory(_ history: OutfitHistory) async throws -> OutfitHistory
    func getHistory(id: UUID) async throws -> OutfitHistory?
    func getHistory(for userId: UUID) async throws -> [OutfitHistory]
    func updateHistory(_ history: OutfitHistory) async throws -> OutfitHistory
    func deleteHistory(id: UUID) async throws
    func getHistoryForOutfit(outfitId: UUID) async throws -> [OutfitHistory]
    func getHistoryByDateRange(for userId: UUID, from: Date, to: Date) async throws -> [OutfitHistory]
    func getRecentHistory(for userId: UUID, limit: Int) async throws -> [OutfitHistory]
    func searchHistory(for userId: UUID, query: String) async throws -> [OutfitHistory]
}

final class OutfitHistoryRepository: OutfitHistoryRepositoryProtocol {
    private let supabase = SupabaseClient.shared.database
    private let tableName = "outfit_history"
    
    func createHistory(_ history: OutfitHistory) async throws -> OutfitHistory {
        let response = try await supabase
            .from(tableName)
            .insert(history)
            .select()
            .single()
            .execute()
        
        return try response.value
    }
    
    func getHistory(id: UUID) async throws -> OutfitHistory? {
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
    
    func getHistory(for userId: UUID) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func updateHistory(_ history: OutfitHistory) async throws -> OutfitHistory {
        var updatedHistory = history
        updatedHistory = OutfitHistory(
            id: history.id,
            userId: history.userId,
            outfitId: history.outfitId,
            wornDate: history.wornDate,
            occasion: history.occasion,
            location: history.location,
            weather: history.weather,
            mood: history.mood,
            confidence: history.confidence,
            feedback: history.feedback,
            photos: history.photos,
            notes: history.notes,
            rating: history.rating,
            tags: history.tags,
            duration: history.duration,
            companions: history.companions,
            activities: history.activities,
            createdAt: history.createdAt,
            updatedAt: Date()
        )
        
        let response = try await supabase
            .from(tableName)
            .update(updatedHistory)
            .eq("id", value: history.id)
            .select()
            .single()
            .execute()
        
        return try response.value
    }
    
    func deleteHistory(id: UUID) async throws {
        try await supabase
            .from(tableName)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    func getHistoryForOutfit(outfitId: UUID) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("outfit_id", value: outfitId)
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getHistoryByDateRange(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .gte("worn_date", value: startDate)
            .lte("worn_date", value: endDate)
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getRecentHistory(for userId: UUID, limit: Int = 20) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .order("worn_date", ascending: false)
            .limit(limit)
            .execute()
        
        return try response.value
    }
    
    func searchHistory(for userId: UUID, query: String) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .or("occasion.ilike.%\(query)%,location.ilike.%\(query)%,notes.ilike.%\(query)%,tags.cs.{\"\(query)\"}")
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
}

extension OutfitHistoryRepository {
    func getTodaysHistory(for userId: UUID) async throws -> [OutfitHistory] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        return try await getHistoryByDateRange(for: userId, from: today, to: tomorrow)
    }
    
    func getThisWeeksHistory(for userId: UUID) async throws -> [OutfitHistory] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        
        return try await getHistoryByDateRange(for: userId, from: startOfWeek, to: endOfWeek)
    }
    
    func getThisMonthsHistory(for userId: UUID) async throws -> [OutfitHistory] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        return try await getHistoryByDateRange(for: userId, from: startOfMonth, to: endOfMonth)
    }
    
    func getHistoryByMood(for userId: UUID, mood: MoodRating) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("mood", value: mood.rawValue)
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getHistoryByConfidence(for userId: UUID, confidence: ConfidenceLevel) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("confidence", value: confidence.rawValue)
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getHistoryByRating(for userId: UUID, minRating: Int) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .gte("rating", value: minRating)
            .order("rating", ascending: false)
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getHistoryByOccasion(for userId: UUID, occasion: String) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .ilike("occasion", pattern: "%\(occasion)%")
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getHistoryWithPhotos(for userId: UUID) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .not("photos", operator: .eq, value: "[]")
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getHistoryWithFeedback(for userId: UUID) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .not("feedback", operator: .is, value: "null")
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getHistoryByWeatherCondition(for userId: UUID, condition: WeatherType) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .eq("weather->condition", value: condition.rawValue)
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getHistoryByTemperatureRange(
        for userId: UUID,
        minTemp: Double,
        maxTemp: Double
    ) async throws -> [OutfitHistory] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("user_id", value: userId)
            .gte("weather->temperature->min", value: minTemp)
            .lte("weather->temperature->max", value: maxTemp)
            .order("worn_date", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getHistoryAnalytics(for userId: UUID, period: AnalyticsPeriod = .month) async throws -> HistoryAnalytics {
        let response = try await supabase
            .rpc("get_history_analytics", parameters: [
                "user_id": userId,
                "period": period.rawValue
            ])
            .execute()
        
        return try response.value
    }
    
    func getWearPatterns(for userId: UUID) async throws -> WearPatterns {
        let response = try await supabase
            .rpc("get_wear_patterns", parameters: ["user_id": userId])
            .execute()
        
        return try response.value
    }
    
    func updatePhotos(historyId: UUID, photos: [String]) async throws {
        let updates: [String: AnyJSON] = [
            "photos": AnyJSON(photos),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: historyId)
            .execute()
    }
    
    func updateFeedback(historyId: UUID, feedback: OutfitFeedback) async throws {
        let updates: [String: AnyJSON] = [
            "feedback": AnyJSON(feedback),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: historyId)
            .execute()
    }
    
    func updateMoodAndConfidence(
        historyId: UUID,
        mood: MoodRating?,
        confidence: ConfidenceLevel?
    ) async throws {
        var updates: [String: AnyJSON] = [
            "updated_at": AnyJSON(Date())
        ]
        
        if let mood = mood {
            updates["mood"] = AnyJSON(mood.rawValue)
        }
        
        if let confidence = confidence {
            updates["confidence"] = AnyJSON(confidence.rawValue)
        }
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: historyId)
            .execute()
    }
    
    func getFrequentlyWornOutfits(for userId: UUID, limit: Int = 10) async throws -> [UUID: Int] {
        let response = try await supabase
            .rpc("get_frequently_worn_outfits", parameters: [
                "user_id": userId,
                "limit": limit
            ])
            .execute()
        
        let results: [[String: AnyJSON]] = try response.value
        var outfitCounts: [UUID: Int] = [:]
        
        for result in results {
            if let outfitIdString = result["outfit_id"]?.value as? String,
               let outfitId = UUID(uuidString: outfitIdString),
               let count = result["wear_count"]?.value as? Int {
                outfitCounts[outfitId] = count
            }
        }
        
        return outfitCounts
    }
    
    func getOutfitsNeverWorn(for userId: UUID) async throws -> [UUID] {
        let response = try await supabase
            .rpc("get_unworn_outfits", parameters: ["user_id": userId])
            .execute()
        
        let results: [String] = try response.value
        return results.compactMap { UUID(uuidString: $0) }
    }
}

enum AnalyticsPeriod: String, Codable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
}

struct HistoryAnalytics: Codable {
    let totalWears: Int
    let averageRating: Double?
    let mostWornDay: String?
    let favoriteOccasion: String?
    let averageMood: Double?
    let averageConfidence: Double?
    let totalPhotos: Int
    let weatherBreakdown: [String: Int]
    let moodDistribution: [String: Int]
    let confidenceDistribution: [String: Int]
    let wearsByWeek: [String: Int]
    
    enum CodingKeys: String, CodingKey {
        case totalWears = "total_wears"
        case averageRating = "average_rating"
        case mostWornDay = "most_worn_day"
        case favoriteOccasion = "favorite_occasion"
        case averageMood = "average_mood"
        case averageConfidence = "average_confidence"
        case totalPhotos = "total_photos"
        case weatherBreakdown = "weather_breakdown"
        case moodDistribution = "mood_distribution"
        case confidenceDistribution = "confidence_distribution"
        case wearsByWeek = "wears_by_week"
    }
}

struct WearPatterns: Codable {
    let mostActiveDay: String
    let leastActiveDay: String
    let peakWearTime: String?
    let averageWearDuration: Double?
    let seasonalPreferences: [String: Int]
    let occasionFrequency: [String: Int]
    let weatherPreferences: [String: Int]
    let favoriteCompanions: [String]
    let preferredActivities: [String]
    
    enum CodingKeys: String, CodingKey {
        case mostActiveDay = "most_active_day"
        case leastActiveDay = "least_active_day"
        case peakWearTime = "peak_wear_time"
        case averageWearDuration = "average_wear_duration"
        case seasonalPreferences = "seasonal_preferences"
        case occasionFrequency = "occasion_frequency"
        case weatherPreferences = "weather_preferences"
        case favoriteCompanions = "favorite_companions"
        case preferredActivities = "preferred_activities"
    }
}