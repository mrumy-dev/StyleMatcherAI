import Foundation
import Supabase

protocol UserRepositoryProtocol {
    func createUser(_ user: AppUser) async throws -> AppUser
    func getUser(id: UUID) async throws -> AppUser?
    func getUserByEmail(_ email: String) async throws -> AppUser?
    func updateUser(_ user: AppUser) async throws -> AppUser
    func deleteUser(id: UUID) async throws
    func updateSubscription(userId: UUID, status: SubscriptionStatus, tier: SubscriptionTier, expiresAt: Date?) async throws
    func updatePreferences(userId: UUID, preferences: UserPreferences) async throws
    func updateOnboardingStatus(userId: UUID, completed: Bool) async throws
    func updateLastActiveAt(userId: UUID) async throws
    func getUserStats(userId: UUID) async throws -> UserStats
}

final class UserRepository: UserRepositoryProtocol {
    private let supabase = SupabaseClient.shared.database
    private let tableName = "users"
    
    func createUser(_ user: AppUser) async throws -> AppUser {
        let response = try await supabase
            .from(tableName)
            .insert(user)
            .select()
            .single()
            .execute()
        
        return try response.value
    }
    
    func getUser(id: UUID) async throws -> AppUser? {
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
    
    func getUserByEmail(_ email: String) async throws -> AppUser? {
        do {
            let response = try await supabase
                .from(tableName)
                .select()
                .eq("email", value: email)
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
    
    func updateUser(_ user: AppUser) async throws -> AppUser {
        let response = try await supabase
            .from(tableName)
            .update(user)
            .eq("id", value: user.id)
            .select()
            .single()
            .execute()
        
        return try response.value
    }
    
    func deleteUser(id: UUID) async throws {
        try await supabase
            .from(tableName)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    func updateSubscription(userId: UUID, status: SubscriptionStatus, tier: SubscriptionTier, expiresAt: Date?) async throws {
        let updates: [String: AnyJSON] = [
            "subscription_status": AnyJSON(status.rawValue),
            "subscription_tier": AnyJSON(tier.rawValue),
            "subscription_expires_at": AnyJSON(expiresAt),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: userId)
            .execute()
    }
    
    func updatePreferences(userId: UUID, preferences: UserPreferences) async throws {
        let updates: [String: AnyJSON] = [
            "preferences": AnyJSON(preferences),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: userId)
            .execute()
    }
    
    func updateOnboardingStatus(userId: UUID, completed: Bool) async throws {
        let updates: [String: AnyJSON] = [
            "onboarding_completed": AnyJSON(completed),
            "updated_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: userId)
            .execute()
    }
    
    func updateLastActiveAt(userId: UUID) async throws {
        let updates: [String: AnyJSON] = [
            "last_active_at": AnyJSON(Date())
        ]
        
        try await supabase
            .from(tableName)
            .update(updates)
            .eq("id", value: userId)
            .execute()
    }
    
    func getUserStats(userId: UUID) async throws -> UserStats {
        let response = try await supabase
            .rpc("get_user_stats", parameters: ["user_id": userId])
            .execute()
        
        return try response.value
    }
}

struct UserStats: Codable {
    let totalWardrobeItems: Int
    let totalOutfits: Int
    let totalWears: Int
    let favoriteCategory: String?
    let favoriteColor: String?
    let averageOutfitRating: Double?
    let weeklyWears: Int
    let monthlyWears: Int
    let accountAgeInDays: Int
    let lastActiveDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case totalWardrobeItems = "total_wardrobe_items"
        case totalOutfits = "total_outfits"
        case totalWears = "total_wears"
        case favoriteCategory = "favorite_category"
        case favoriteColor = "favorite_color"
        case averageOutfitRating = "average_outfit_rating"
        case weeklyWears = "weekly_wears"
        case monthlyWears = "monthly_wears"
        case accountAgeInDays = "account_age_in_days"
        case lastActiveDate = "last_active_date"
    }
}

extension UserRepository {
    func syncUserWithAuth(_ authUser: Supabase.User) async throws -> AppUser {
        if let existingUser = try await getUser(id: authUser.id) {
            let updatedUser = AppUser(
                id: existingUser.id,
                email: authUser.email ?? existingUser.email,
                displayName: authUser.userMetadata["display_name"] as? String ?? existingUser.displayName,
                avatarURL: authUser.userMetadata["avatar_url"] as? String ?? existingUser.avatarURL,
                subscriptionStatus: existingUser.subscriptionStatus,
                subscriptionTier: existingUser.subscriptionTier,
                subscriptionExpiresAt: existingUser.subscriptionExpiresAt,
                preferences: existingUser.preferences,
                createdAt: existingUser.createdAt,
                updatedAt: Date(),
                lastActiveAt: Date(),
                onboardingCompleted: existingUser.onboardingCompleted,
                profileSetupCompleted: existingUser.profileSetupCompleted
            )
            
            return try await updateUser(updatedUser)
        } else {
            let newUser = AppUser.from(supabaseUser: authUser)
            return try await createUser(newUser)
        }
    }
    
    func searchUsers(query: String, limit: Int = 10) async throws -> [AppUser] {
        let response = try await supabase
            .from(tableName)
            .select()
            .or("display_name.ilike.%\(query)%,email.ilike.%\(query)%")
            .limit(limit)
            .execute()
        
        return try response.value
    }
    
    func getActiveUsers(since date: Date) async throws -> [AppUser] {
        let response = try await supabase
            .from(tableName)
            .select()
            .gte("last_active_at", value: date)
            .order("last_active_at", ascending: false)
            .execute()
        
        return try response.value
    }
    
    func getUsersBySubscriptionTier(_ tier: SubscriptionTier) async throws -> [AppUser] {
        let response = try await supabase
            .from(tableName)
            .select()
            .eq("subscription_tier", value: tier.rawValue)
            .execute()
        
        return try response.value
    }
    
    func getExpiredSubscriptions() async throws -> [AppUser] {
        let response = try await supabase
            .from(tableName)
            .select()
            .lt("subscription_expires_at", value: Date())
            .neq("subscription_status", value: SubscriptionStatus.free.rawValue)
            .execute()
        
        return try response.value
    }
}