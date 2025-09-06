import Foundation
import SwiftUI

@MainActor
final class OutfitsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var outfits: [Outfit] = []
    @Published var filteredOutfits: [Outfit] = []
    @Published var todaysOutfit: Outfit?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentFilter: OutfitFilter = .all
    
    // MARK: - Private Properties
    private let outfitRepository = OutfitRepository()
    private let authService = AuthenticationService.shared
    
    // MARK: - Public Methods
    
    func loadOutfits() async {
        isLoading = true
        error = nil
        
        do {
            guard let userId = authService.currentUser?.id else { return }
            
            let loadedOutfits = try await outfitRepository.getOutfits(for: userId)
            outfits = loadedOutfits
            applyCurrentFilter()
            
            // Set today's outfit suggestion
            todaysOutfit = loadedOutfits.randomElement()
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func filterBy(_ filter: OutfitFilter) {
        currentFilter = filter
        applyCurrentFilter()
    }
    
    func addOutfit(_ outfit: Outfit) {
        outfits.insert(outfit, at: 0)
        applyCurrentFilter()
    }
    
    func updateOutfit(_ outfit: Outfit) {
        if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
            outfits[index] = outfit
            applyCurrentFilter()
        }
    }
    
    func deleteOutfit(_ outfit: Outfit) {
        Task {
            do {
                try await outfitRepository.deleteOutfit(id: outfit.id)
                outfits.removeAll { $0.id == outfit.id }
                applyCurrentFilter()
            } catch {
                self.error = error
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func applyCurrentFilter() {
        switch currentFilter {
        case .all:
            filteredOutfits = outfits
        case .favorites:
            filteredOutfits = outfits.filter { $0.isFavorite }
        case .recent:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            filteredOutfits = outfits.filter { $0.createdAt > thirtyDaysAgo }
        case .seasonal:
            let currentSeason = Season.current
            filteredOutfits = outfits.filter { $0.season.contains(currentSeason) }
        }
    }
}

enum OutfitFilter: String, CaseIterable {
    case all = "all"
    case favorites = "favorites"
    case recent = "recent"
    case seasonal = "seasonal"
    
    var displayName: String {
        switch self {
        case .all:
            return "All Outfits"
        case .favorites:
            return "Favorites"
        case .recent:
            return "Recent"
        case .seasonal:
            return "This Season"
        }
    }
}