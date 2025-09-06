import Foundation
import SwiftUI

@MainActor
final class WardrobeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var items: [WardrobeItem] = []
    @Published var searchText: String = ""
    @Published var filters = WardrobeFilters()
    @Published var sortOption: SortOption = .dateAdded
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: Error?
    @Published var isSelectionMode = false
    @Published var selectedItems: Set<UUID> = []
    
    // MARK: - Private Properties
    private let repository = WardrobeRepository()
    private let imageUploadService = ImageUploadService.shared
    private var currentPage = 0
    private let pageSize = 20
    private var hasMoreItems = true
    
    // MARK: - Computed Properties
    var filteredItems: [WardrobeItem] {
        let filtered = items
            .filter { matchesSearchText($0) }
            .filter { matchesFilters($0) }
        
        return sortItems(filtered)
    }
    
    var hasActiveFilters: Bool {
        return !filters.isEmpty
    }
    
    // MARK: - Initialization
    init() {
        setupSearchDebouncing()
    }
    
    // MARK: - Public Methods
    
    func loadItems() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        currentPage = 0
        hasMoreItems = true
        
        do {
            let userId = getCurrentUserId()
            let loadedItems = try await repository.getItems(for: userId)
            items = loadedItems
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func loadMoreItems() async {
        guard !isLoadingMore && hasMoreItems else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let userId = getCurrentUserId()
            // Implementation would depend on your pagination strategy
            let moreItems = try await repository.getItems(for: userId)
            
            if moreItems.count < pageSize {
                hasMoreItems = false
            }
            
            items.append(contentsOf: moreItems)
        } catch {
            self.error = error
            currentPage -= 1
        }
        
        isLoadingMore = false
    }
    
    func addItem(_ item: WardrobeItem) {
        items.insert(item, at: 0)
        trackItemAddedEvent(item)
    }
    
    func updateItem(_ updatedItem: WardrobeItem) {
        if let index = items.firstIndex(where: { $0.id == updatedItem.id }) {
            items[index] = updatedItem
        }
    }
    
    func deleteItem(_ item: WardrobeItem) {
        Task {
            do {
                try await repository.deleteItem(id: item.id)
                items.removeAll { $0.id == item.id }
                
                // Clean up images
                try await imageUploadService.deleteWardrobeImage(
                    userId: item.userId,
                    fileName: item.id.uuidString
                )
                
                trackItemDeletedEvent(item)
            } catch {
                self.error = error
            }
        }
    }
    
    func toggleFavorite(_ item: WardrobeItem) {
        Task {
            do {
                var updatedItem = item
                updatedItem = WardrobeItem(
                    id: item.id,
                    userId: item.userId,
                    name: item.name,
                    description: item.description,
                    category: item.category,
                    subcategory: item.subcategory,
                    brand: item.brand,
                    colors: item.colors,
                    patterns: item.patterns,
                    materials: item.materials,
                    formality: item.formality,
                    season: item.season,
                    occasion: item.occasion,
                    size: item.size,
                    purchaseDate: item.purchaseDate,
                    purchasePrice: item.purchasePrice,
                    currency: item.currency,
                    condition: item.condition,
                    careInstructions: item.careInstructions,
                    tags: item.tags,
                    imageURLs: item.imageURLs,
                    thumbnailURL: item.thumbnailURL,
                    isFavorite: !item.isFavorite,
                    timesWorn: item.timesWorn,
                    lastWornAt: item.lastWornAt,
                    createdAt: item.createdAt,
                    updatedAt: Date(),
                    isArchived: item.isArchived,
                    notes: item.notes
                )
                
                let result = try await repository.updateItem(updatedItem)
                updateItem(result)
                
                trackFavoriteToggledEvent(item, newState: !item.isFavorite)
            } catch {
                self.error = error
            }
        }
    }
    
    func markAsWorn(_ item: WardrobeItem) {
        Task {
            do {
                try await repository.markItemAsWorn(id: item.id)
                
                var updatedItem = item
                updatedItem.markAsWorn()
                updateItem(updatedItem)
                
                trackItemWornEvent(item)
            } catch {
                self.error = error
            }
        }
    }
    
    func archiveItem(_ item: WardrobeItem) {
        Task {
            do {
                try await repository.archiveItem(id: item.id)
                items.removeAll { $0.id == item.id }
                
                trackItemArchivedEvent(item)
            } catch {
                self.error = error
            }
        }
    }
    
    func sortBy(_ option: SortOption) {
        sortOption = option
        trackSortChangedEvent(option)
    }
    
    func clearFilters() {
        filters = WardrobeFilters()
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Selection Mode
    
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedItems.removeAll()
        }
    }
    
    func exitSelectionMode() {
        isSelectionMode = false
        selectedItems.removeAll()
    }
    
    func selectItem(_ item: WardrobeItem) {
        selectedItems.insert(item.id)
    }
    
    func deselectItem(_ item: WardrobeItem) {
        selectedItems.remove(item.id)
    }
    
    func markSelectedAsWorn() {
        let selectedItemsList = items.filter { selectedItems.contains($0.id) }
        
        Task {
            for item in selectedItemsList {
                markAsWorn(item)
            }
            exitSelectionMode()
        }
    }
    
    func addSelectedToFavorites() {
        let selectedItemsList = items.filter { selectedItems.contains($0.id) && !$0.isFavorite }
        
        Task {
            for item in selectedItemsList {
                toggleFavorite(item)
            }
            exitSelectionMode()
        }
    }
    
    func archiveSelected() {
        let selectedItemsList = items.filter { selectedItems.contains($0.id) }
        
        Task {
            for item in selectedItemsList {
                archiveItem(item)
            }
            exitSelectionMode()
        }
    }
    
    func deleteSelected() {
        let selectedItemsList = items.filter { selectedItems.contains($0.id) }
        
        Task {
            for item in selectedItemsList {
                deleteItem(item)
            }
            exitSelectionMode()
        }
    }
    
    // MARK: - Private Methods
    
    private func matchesSearchText(_ item: WardrobeItem) -> Bool {
        guard !searchText.isEmpty else { return true }
        
        let searchLower = searchText.lowercased()
        
        return item.name.lowercased().contains(searchLower) ||
               item.description?.lowercased().contains(searchLower) == true ||
               item.brand?.lowercased().contains(searchLower) == true ||
               item.category.displayName.lowercased().contains(searchLower) ||
               item.subcategory?.lowercased().contains(searchLower) == true ||
               item.colors.contains { $0.name.lowercased().contains(searchLower) } ||
               item.tags.contains { $0.lowercased().contains(searchLower) }
    }
    
    private func matchesFilters(_ item: WardrobeItem) -> Bool {
        // Category filter
        if !filters.categories.isEmpty && !filters.categories.contains(item.category) {
            return false
        }
        
        // Color filter
        if !filters.colors.isEmpty {
            let itemColorNames = item.colors.map { $0.name.lowercased() }
            let hasMatchingColor = filters.colors.contains { filterColor in
                itemColorNames.contains { $0.contains(filterColor.lowercased()) }
            }
            if !hasMatchingColor {
                return false
            }
        }
        
        // Formality filter
        if !filters.formalityLevels.isEmpty && !filters.formalityLevels.contains(item.formality) {
            return false
        }
        
        // Season filter
        if !filters.seasons.isEmpty {
            let hasMatchingSeason = filters.seasons.contains { season in
                item.season.contains(season)
            }
            if !hasMatchingSeason {
                return false
            }
        }
        
        // Favorite filter
        if filters.favoritesOnly && !item.isFavorite {
            return false
        }
        
        // Recently worn filter
        if filters.recentlyWorn {
            guard let lastWorn = item.lastWornAt else { return false }
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            if lastWorn < thirtyDaysAgo {
                return false
            }
        }
        
        // Condition filter
        if !filters.conditions.isEmpty && !filters.conditions.contains(item.condition) {
            return false
        }
        
        return true
    }
    
    private func sortItems(_ items: [WardrobeItem]) -> [WardrobeItem] {
        switch sortOption {
        case .dateAdded:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .name:
            return items.sorted { $0.name < $1.name }
        case .category:
            return items.sorted { $0.category.displayName < $1.category.displayName }
        case .timesWorn:
            return items.sorted { $0.timesWorn > $1.timesWorn }
        case .lastWorn:
            return items.sorted { ($0.lastWornAt ?? Date.distantPast) > ($1.lastWornAt ?? Date.distantPast) }
        case .color:
            return items.sorted { 
                ($0.colors.first?.name ?? "") < ($1.colors.first?.name ?? "")
            }
        }
    }
    
    private func setupSearchDebouncing() {
        // In a real implementation, you'd want to debounce search
        // This is a simplified version
    }
    
    private func getCurrentUserId() -> UUID {
        // This should get the current user's ID from your auth system
        // For now, return a placeholder
        return UUID()
    }
    
    // MARK: - Analytics
    
    func trackViewEvent() {
        // Track wardrobe view event
    }
    
    private func trackItemAddedEvent(_ item: WardrobeItem) {
        // Track item added event
    }
    
    private func trackItemDeletedEvent(_ item: WardrobeItem) {
        // Track item deleted event
    }
    
    private func trackFavoriteToggledEvent(_ item: WardrobeItem, newState: Bool) {
        // Track favorite toggled event
    }
    
    private func trackItemWornEvent(_ item: WardrobeItem) {
        // Track item worn event
    }
    
    private func trackItemArchivedEvent(_ item: WardrobeItem) {
        // Track item archived event
    }
    
    private func trackSortChangedEvent(_ option: SortOption) {
        // Track sort changed event
    }
}

// MARK: - Supporting Types

enum SortOption: String, CaseIterable {
    case dateAdded = "date_added"
    case name = "name"
    case category = "category"
    case timesWorn = "times_worn"
    case lastWorn = "last_worn"
    case color = "color"
    
    var displayName: String {
        switch self {
        case .dateAdded:
            return "Recently Added"
        case .name:
            return "Name"
        case .category:
            return "Category"
        case .timesWorn:
            return "Most Worn"
        case .lastWorn:
            return "Recently Worn"
        case .color:
            return "Color"
        }
    }
}

struct WardrobeFilters {
    var categories: Set<ClothingCategory> = []
    var colors: [String] = []
    var formalityLevels: Set<FormalityLevel> = []
    var seasons: Set<Season> = []
    var conditions: Set<ItemCondition> = []
    var favoritesOnly: Bool = false
    var recentlyWorn: Bool = false
    
    var isEmpty: Bool {
        return categories.isEmpty &&
               colors.isEmpty &&
               formalityLevels.isEmpty &&
               seasons.isEmpty &&
               conditions.isEmpty &&
               !favoritesOnly &&
               !recentlyWorn
    }
}

// MARK: - Extensions

extension WardrobeViewModel {
    func refreshData() async {
        await loadItems()
    }
    
    func getItemsNeedingAttention() -> [WardrobeItem] {
        return items.filter { $0.needsAttention }
    }
    
    func getUnwornItems() -> [WardrobeItem] {
        return items.filter { $0.timesWorn == 0 }
    }
    
    func getFavoriteItems() -> [WardrobeItem] {
        return items.filter { $0.isFavorite }
    }
    
    func getItemsByCategory(_ category: ClothingCategory) -> [WardrobeItem] {
        return items.filter { $0.category == category }
    }
    
    func getRecentlyAddedItems(days: Int = 7) -> [WardrobeItem] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return items.filter { $0.createdAt > cutoffDate }
    }
}