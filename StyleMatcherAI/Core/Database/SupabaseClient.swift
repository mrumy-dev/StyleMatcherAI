import Foundation
import Supabase

final class SupabaseClient {
    static let shared = SupabaseClient()
    
    private let client: SupabaseSwift.Client
    
    private init() {
        guard let url = URL(string: Configuration.supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        
        self.client = SupabaseSwift.Client(
            supabaseURL: url,
            supabaseKey: Configuration.supabaseAnonKey
        )
    }
    
    var supabase: SupabaseSwift.Client {
        return client
    }
    
    var auth: AuthClient {
        return client.auth
    }
    
    var database: PostgrestClient {
        return client.database
    }
    
    var storage: StorageClient {
        return client.storage
    }
    
    var realtime: RealtimeClient {
        return client.realtime
    }
}

extension SupabaseClient {
    func signOut() async throws {
        try await auth.signOut()
    }
    
    var isAuthenticated: Bool {
        return auth.currentUser != nil
    }
    
    var currentUser: User? {
        return auth.currentUser
    }
    
    var currentSession: Session? {
        return auth.currentSession
    }
}