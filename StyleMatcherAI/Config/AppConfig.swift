import Foundation
import UIKit

struct AppConfig {
    
    // MARK: - App Information
    struct App {
        static let name = "StyleMatcher AI"
        static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        static let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.stylematcher.ai"
        
        static var displayVersion: String {
            return "\(version) (\(buildNumber))"
        }
    }
    
    // MARK: - Network Configuration
    struct Network {
        static let requestTimeoutInterval: TimeInterval = 30.0
        static let resourceTimeoutInterval: TimeInterval = 60.0
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 2.0
        
        static var baseURL: String {
            return Environment.current.baseURL
        }
        
        static var supabaseURL: String {
            return Environment.current.supabaseURL
        }
    }
    
    // MARK: - Feature Flags
    struct FeatureFlags {
        static let isAnalyticsEnabled = Environment.current != .development
        static let isCrashReportingEnabled = Environment.current == .production
        static let isDebugMenuEnabled = Environment.current == .development
        static let isOnboardingEnabled = true
        static let isSubscriptionRequired = Environment.current == .production
        
        static var shouldShowDeveloperOptions: Bool {
            return Environment.current.isDebugMode
        }
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let animationDuration: TimeInterval = 0.3
        static let shortAnimationDuration: TimeInterval = 0.15
        static let longAnimationDuration: TimeInterval = 0.5
        
        static let cornerRadius: CGFloat = 12.0
        static let smallCornerRadius: CGFloat = 8.0
        static let largeCornerRadius: CGFloat = 20.0
        
        static let defaultPadding: CGFloat = 16.0
        static let smallPadding: CGFloat = 8.0
        static let largePadding: CGFloat = 24.0
        
        static let minimumTouchTarget: CGFloat = 44.0
        static let maxImageCacheSize = 100 * 1024 * 1024 // 100MB
    }
    
    // MARK: - Business Logic
    struct Business {
        static let maxPhotosPerUser = 100
        static let maxPhotoSizeMB = 10.0
        static let supportedImageFormats = ["jpg", "jpeg", "png", "heic"]
        static let freeTrialDays = 7
        static let maxFreeMatches = 3
        
        static var maxPhotoSizeBytes: Int {
            return Int(maxPhotoSizeMB * 1024 * 1024)
        }
    }
    
    // MARK: - Cache Configuration
    struct Cache {
        static let userPreferencesCacheKey = "user_preferences"
        static let onboardingCompletedKey = "onboarding_completed"
        static let lastSyncTimestampKey = "last_sync_timestamp"
        
        static let imageCacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours
        static let apiResponseCacheDuration: TimeInterval = 5 * 60 // 5 minutes
        
        struct UserDefaults {
            static let suiteName = "group.stylematcher.ai"
        }
    }
    
    // MARK: - Security
    struct Security {
        static let keychainService = "StyleMatcherAI"
        static let biometricAuthTimeout: TimeInterval = 5.0
        static let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
        
        static let allowedDomains = [
            "stylematcher.ai",
            "supabase.co",
            "revenuecat.com"
        ]
    }
    
    // MARK: - Logging
    struct Logging {
        static let maxLogFileSize = 10 * 1024 * 1024 // 10MB
        static let maxLogFiles = 5
        
        static var logLevel: LogLevel {
            return Environment.current.logLevel
        }
        
        static var shouldLogToConsole: Bool {
            return Environment.current.isDebugMode
        }
    }
    
    // MARK: - Analytics
    struct Analytics {
        static let sessionTimeoutMinutes = 30
        static let batchUploadSize = 50
        static let maxEventsInMemory = 1000
        
        static let enabledInEnvironment: Bool = {
            switch Environment.current {
            case .development:
                return false
            case .staging:
                return true
            case .production:
                return true
            }
        }()
    }
    
    // MARK: - Subscription
    struct Subscription {
        static let monthlyProductId = "stylematcher_monthly"
        static let yearlyProductId = "stylematcher_yearly"
        static let lifetimeProductId = "stylematcher_lifetime"
        
        static let gracePeriodDays = 3
        static let renewalReminderDays = 2
    }
}

// MARK: - Environment Helpers
extension AppConfig {
    static var isDevelopment: Bool {
        return Environment.current == .development
    }
    
    static var isStaging: Bool {
        return Environment.current == .staging
    }
    
    static var isProduction: Bool {
        return Environment.current == .production
    }
    
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}