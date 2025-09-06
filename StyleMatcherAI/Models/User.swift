import Foundation
import Supabase

struct AppUser: Codable, Identifiable, Equatable {
    let id: UUID
    let email: String?
    let displayName: String?
    let avatarURL: String?
    let subscriptionStatus: SubscriptionStatus
    let subscriptionTier: SubscriptionTier
    let subscriptionExpiresAt: Date?
    let preferences: UserPreferences?
    let createdAt: Date
    let updatedAt: Date
    let lastActiveAt: Date?
    let onboardingCompleted: Bool
    let profileSetupCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case subscriptionStatus = "subscription_status"
        case subscriptionTier = "subscription_tier"
        case subscriptionExpiresAt = "subscription_expires_at"
        case preferences
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastActiveAt = "last_active_at"
        case onboardingCompleted = "onboarding_completed"
        case profileSetupCompleted = "profile_setup_completed"
    }
}

enum SubscriptionStatus: String, Codable, CaseIterable {
    case free = "free"
    case active = "active"
    case pastDue = "past_due"
    case canceled = "canceled"
    case expired = "expired"
    case trialing = "trialing"
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .active:
            return "Active"
        case .pastDue:
            return "Past Due"
        case .canceled:
            return "Canceled"
        case .expired:
            return "Expired"
        case .trialing:
            return "Trial"
        }
    }
    
    var isPaid: Bool {
        return [.active, .pastDue, .trialing].contains(self)
    }
}

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case premium = "premium"
    case pro = "pro"
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        case .pro:
            return "Pro"
        }
    }
    
    var maxWardrobeItems: Int? {
        switch self {
        case .free:
            return 50
        case .premium:
            return 500
        case .pro:
            return nil
        }
    }
    
    var maxOutfitsPerDay: Int? {
        switch self {
        case .free:
            return 3
        case .premium:
            return 20
        case .pro:
            return nil
        }
    }
    
    var hasAdvancedAI: Bool {
        switch self {
        case .free:
            return false
        case .premium, .pro:
            return true
        }
    }
}

struct UserPreferences: Codable, Equatable {
    var style: StylePreference?
    var occasions: [String]
    var colors: ColorPreferences
    var brands: [String]
    var budgetRange: BudgetRange?
    var bodyType: BodyType?
    var notifications: NotificationPreferences
    var privacy: PrivacyPreferences
    
    enum CodingKeys: String, CodingKey {
        case style
        case occasions
        case colors
        case brands
        case budgetRange = "budget_range"
        case bodyType = "body_type"
        case notifications
        case privacy
    }
    
    init() {
        self.style = nil
        self.occasions = []
        self.colors = ColorPreferences()
        self.brands = []
        self.budgetRange = nil
        self.bodyType = nil
        self.notifications = NotificationPreferences()
        self.privacy = PrivacyPreferences()
    }
}

struct StylePreference: Codable, Equatable {
    let primary: String
    let secondary: [String]
    let formality: FormalityLevel
    
    enum CodingKeys: String, CodingKey {
        case primary
        case secondary
        case formality
    }
}

enum FormalityLevel: String, Codable, CaseIterable {
    case casual = "casual"
    case smartCasual = "smart_casual"
    case business = "business"
    case formal = "formal"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .casual:
            return "Casual"
        case .smartCasual:
            return "Smart Casual"
        case .business:
            return "Business"
        case .formal:
            return "Formal"
        case .mixed:
            return "Mixed"
        }
    }
}

struct ColorPreferences: Codable, Equatable {
    var preferred: [String]
    var avoided: [String]
    var neutral: [String]
    
    init() {
        self.preferred = []
        self.avoided = []
        self.neutral = ["black", "white", "gray", "navy", "beige"]
    }
}

struct BudgetRange: Codable, Equatable {
    let min: Double
    let max: Double
    let currency: String
    
    init(min: Double = 0, max: Double = 1000, currency: String = "USD") {
        self.min = min
        self.max = max
        self.currency = currency
    }
}

enum BodyType: String, Codable, CaseIterable {
    case rectangle = "rectangle"
    case pear = "pear"
    case apple = "apple"
    case hourglass = "hourglass"
    case invertedTriangle = "inverted_triangle"
    
    var displayName: String {
        switch self {
        case .rectangle:
            return "Rectangle"
        case .pear:
            return "Pear"
        case .apple:
            return "Apple"
        case .hourglass:
            return "Hourglass"
        case .invertedTriangle:
            return "Inverted Triangle"
        }
    }
}

struct NotificationPreferences: Codable, Equatable {
    var outfitReminders: Bool
    var weeklyStyleTips: Bool
    var newFeatures: Bool
    var promotional: Bool
    
    init() {
        self.outfitReminders = true
        self.weeklyStyleTips = true
        self.newFeatures = true
        self.promotional = false
    }
}

struct PrivacyPreferences: Codable, Equatable {
    var profileVisibility: ProfileVisibility
    var dataSharing: Bool
    var analytics: Bool
    
    init() {
        self.profileVisibility = .private
        self.dataSharing = false
        self.analytics = true
    }
}

enum ProfileVisibility: String, Codable, CaseIterable {
    case `private` = "private"
    case friends = "friends"
    case `public` = "public"
    
    var displayName: String {
        switch self {
        case .private:
            return "Private"
        case .friends:
            return "Friends Only"
        case .public:
            return "Public"
        }
    }
}

extension AppUser {
    static func from(supabaseUser: Supabase.User) -> AppUser {
        AppUser(
            id: supabaseUser.id,
            email: supabaseUser.email,
            displayName: supabaseUser.userMetadata["display_name"] as? String,
            avatarURL: supabaseUser.userMetadata["avatar_url"] as? String,
            subscriptionStatus: .free,
            subscriptionTier: .free,
            subscriptionExpiresAt: nil,
            preferences: UserPreferences(),
            createdAt: supabaseUser.createdAt,
            updatedAt: supabaseUser.updatedAt ?? Date(),
            lastActiveAt: Date(),
            onboardingCompleted: false,
            profileSetupCompleted: false
        )
    }
}