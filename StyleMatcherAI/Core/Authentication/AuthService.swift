import Foundation
import Supabase
import Combine

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let supabase = SupabaseClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthStateListener()
        checkInitialAuthState()
    }
    
    private func setupAuthStateListener() {
        supabase.auth.onAuthStateChange { [weak self] event, session in
            Task { @MainActor in
                self?.handleAuthStateChange(event: event, session: session)
            }
        }
    }
    
    private func checkInitialAuthState() {
        currentUser = supabase.currentUser
        isAuthenticated = currentUser != nil
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) {
        switch event {
        case .signedIn:
            currentUser = session?.user
            isAuthenticated = true
        case .signedOut, .tokenRefreshed:
            if session == nil {
                currentUser = nil
                isAuthenticated = false
            } else {
                currentUser = session?.user
                isAuthenticated = true
            }
        case .passwordRecovery, .userUpdated:
            currentUser = session?.user
        @unknown default:
            break
        }
    }
}

extension AuthService {
    func signInWithEmail(_ email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await supabase.auth.signIn(email: email, password: password)
        currentUser = response.user
        isAuthenticated = true
    }
    
    func signUpWithEmail(_ email: String, password: String, metadata: [String: AnyJSON]? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: metadata
        )
        currentUser = response.user
        isAuthenticated = response.session != nil
    }
    
    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        currentUser = response.user
        isAuthenticated = true
    }
    
    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let response = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
        currentUser = response.user
        isAuthenticated = true
    }
    
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await supabase.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    func updatePassword(_ newPassword: String) async throws {
        try await supabase.auth.update(user: UserAttributes(password: newPassword))
    }
    
    func updateProfile(displayName: String? = nil, avatarURL: String? = nil) async throws {
        var metadata: [String: AnyJSON] = [:]
        
        if let displayName = displayName {
            metadata["display_name"] = AnyJSON(displayName)
        }
        
        if let avatarURL = avatarURL {
            metadata["avatar_url"] = AnyJSON(avatarURL)
        }
        
        try await supabase.auth.update(user: UserAttributes(data: metadata))
    }
    
    func refreshSession() async throws {
        try await supabase.auth.refreshSession()
    }
    
    func deleteAccount() async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.userNotFound
        }
        
        try await supabase.database
            .rpc("delete_user_account", parameters: ["user_id": userId])
            .execute()
        
        try await signOut()
    }
}

enum AuthError: LocalizedError {
    case userNotFound
    case invalidCredentials
    case emailNotConfirmed
    case weakPassword
    case emailAlreadyInUse
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailNotConfirmed:
            return "Please confirm your email address"
        case .weakPassword:
            return "Password is too weak"
        case .emailAlreadyInUse:
            return "Email is already in use"
        case .networkError:
            return "Network error occurred"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}