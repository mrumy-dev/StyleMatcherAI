import Foundation

enum Environment: String, CaseIterable {
    case development = "development"
    case staging = "staging"
    case production = "production"
    
    static var current: Environment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
    
    var displayName: String {
        switch self {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
    
    var baseURL: String {
        switch self {
        case .development:
            return "https://dev-api.stylematcher.ai"
        case .staging:
            return "https://staging-api.stylematcher.ai"
        case .production:
            return "https://api.stylematcher.ai"
        }
    }
    
    var supabaseURL: String {
        switch self {
        case .development:
            return "https://your-dev-project.supabase.co"
        case .staging:
            return "https://your-staging-project.supabase.co"
        case .production:
            return "https://your-prod-project.supabase.co"
        }
    }
    
    var supabaseAnonKey: String {
        switch self {
        case .development:
            return "your-dev-anon-key"
        case .staging:
            return "your-staging-anon-key"
        case .production:
            return "your-prod-anon-key"
        }
    }
    
    var openAIAPIKey: String {
        switch self {
        case .development:
            return "your-dev-openai-key"
        case .staging:
            return "your-staging-openai-key"
        case .production:
            return "your-prod-openai-key"
        }
    }
    
    var isDebugMode: Bool {
        return self == .development
    }
    
    var logLevel: LogLevel {
        switch self {
        case .development:
            return .verbose
        case .staging:
            return .info
        case .production:
            return .error
        }
    }
}

enum LogLevel: String, CaseIterable {
    case verbose = "verbose"
    case info = "info"
    case warning = "warning"
    case error = "error"
}