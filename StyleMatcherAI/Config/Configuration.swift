import Foundation

struct Configuration {
    static let supabaseURL: String = Environment.current.supabaseURL
    static let supabaseAnonKey: String = Environment.current.supabaseAnonKey
    
    static let baseURL: String = Environment.current.baseURL
    static let openAIAPIKey: String = Environment.current.openAIAPIKey
    
    private init() {}
}