import Foundation
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: AppUser?
    @Published var stats = ProfileStats()
    @Published var subscriptionInfo: SubscriptionInfo?
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    private let authService = AuthenticationService.shared
    private let wardrobeRepository = WardrobeRepository()
    private let outfitRepository = OutfitRepository()
    
    // MARK: - Public Methods
    
    func loadProfile() async {
        isLoading = true
        error = nil
        
        // Load user data
        user = authService.currentUser
        
        if let user = user {
            subscriptionInfo = SubscriptionInfo(status: user.subscriptionStatus)
        }
        
        // Load statistics
        await loadStatistics()
        
        isLoading = false
    }
    
    func updateProfile(_ updatedUser: AppUser) {
        user = updatedUser
    }
    
    func exportUserData() async {
        // TODO: Implement data export functionality
        print("Exporting user data...")
    }
    
    // MARK: - Private Methods
    
    private func loadStatistics() async {
        guard let userId = user?.id else { return }
        
        do {
            // Load wardrobe stats
            let items = try await wardrobeRepository.getItems(for: userId)
            let outfits = try await outfitRepository.getOutfits(for: userId)
            
            // Calculate statistics
            let totalItems = items.count
            let favoriteItems = items.filter { $0.isFavorite }.count
            let categoriesOwned = Set(items.map { $0.category }).count
            let averageWearCount = items.isEmpty ? 0 : Double(items.map { $0.timesWorn }.reduce(0, +)) / Double(items.count)
            
            // Items worn this month
            let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
            let itemsWornThisMonth = items.filter { item in
                guard let lastWorn = item.lastWornAt else { return false }
                return lastWorn >= startOfMonth
            }.count
            
            stats = ProfileStats(
                totalItems: totalItems,
                totalOutfits: outfits.count,
                favoriteItems: favoriteItems,
                itemsWornThisMonth: itemsWornThisMonth,
                categoriesOwned: categoriesOwned,
                averageWearCount: averageWearCount
            )
            
        } catch {
            self.error = error
            print("Failed to load profile statistics: \(error)")
        }
    }
}