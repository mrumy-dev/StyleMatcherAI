import SwiftUI
import Foundation

@MainActor
final class NavigationCoordinator: ObservableObject {
    // Navigation paths for each tab
    @Published var homePath = NavigationPath()
    @Published var wardrobePath = NavigationPath()
    @Published var outfitsPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    
    // MARK: - Navigation Methods
    
    func navigateToHome(_ destination: HomeDestination) {
        homePath.append(destination)
    }
    
    func navigateToWardrobe(_ destination: WardrobeDestination) {
        wardrobePath.append(destination)
    }
    
    func navigateToOutfits(_ destination: OutfitDestination) {
        outfitsPath.append(destination)
    }
    
    func navigateToProfile(_ destination: ProfileDestination) {
        profilePath.append(destination)
    }
    
    func popToRoot(for tab: AppTab) {
        switch tab {
        case .home:
            homePath = NavigationPath()
        case .wardrobe:
            wardrobePath = NavigationPath()
        case .outfits:
            outfitsPath = NavigationPath()
        case .profile:
            profilePath = NavigationPath()
        case .add:
            break // Add tab doesn't have a navigation stack
        }
    }
    
    func goBack(for tab: AppTab) {
        switch tab {
        case .home:
            if !homePath.isEmpty {
                homePath.removeLast()
            }
        case .wardrobe:
            if !wardrobePath.isEmpty {
                wardrobePath.removeLast()
            }
        case .outfits:
            if !outfitsPath.isEmpty {
                outfitsPath.removeLast()
            }
        case .profile:
            if !profilePath.isEmpty {
                profilePath.removeLast()
            }
        case .add:
            break
        }
    }
    
    // MARK: - View Factory
    
    @ViewBuilder
    func view(for destination: HomeDestination) -> some View {
        switch destination {
        case .wardrobe:
            WardrobeGridView()
        case .addItem:
            AddWardrobeItemView { _ in
                // Handle item addition
            }
        case .outfits:
            OutfitsView()
        case .profile:
            ProfileView()
        case .analytics:
            AnalyticsView()
        case .recommendations:
            RecommendationsView()
        }
    }
    
    @ViewBuilder
    func view(for destination: WardrobeDestination) -> some View {
        switch destination {
        case .itemDetail(let item):
            WardrobeItemDetailView(
                item: item,
                onUpdate: { _ in },
                onDelete: { }
            )
        case .addItem:
            AddWardrobeItemView { _ in
                // Handle item addition
            }
        case .filters:
            WardrobeFiltersView(filters: .constant(WardrobeFilters()))
        case .camera:
            CameraView(viewModel: CameraViewModel())
        }
    }
    
    @ViewBuilder
    func view(for destination: OutfitDestination) -> some View {
        switch destination {
        case .outfitDetail(let outfit):
            OutfitDetailView(outfit: outfit)
        case .createOutfit:
            CreateOutfitView()
        case .editOutfit(let outfit):
            EditOutfitView(outfit: outfit)
        }
    }
    
    @ViewBuilder
    func view(for destination: ProfileDestination) -> some View {
        switch destination {
        case .settings:
            SettingsView()
        case .preferences:
            PreferencesView()
        case .subscription:
            SubscriptionView()
        case .about:
            AboutView()
        case .help:
            HelpView()
        }
    }
    
    // MARK: - Deep Linking
    
    func handleDeepLink(url: URL, selectedTab: Binding<AppTab>) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        // Parse the URL and navigate accordingly
        switch host {
        case "wardrobe":
            selectedTab.wrappedValue = .wardrobe
            handleWardrobeDeepLink(components: components)
            
        case "outfits":
            selectedTab.wrappedValue = .outfits
            handleOutfitsDeepLink(components: components)
            
        case "profile":
            selectedTab.wrappedValue = .profile
            handleProfileDeepLink(components: components)
            
        case "add":
            selectedTab.wrappedValue = .add
            
        default:
            selectedTab.wrappedValue = .home
        }
    }
    
    private func handleWardrobeDeepLink(components: URLComponents) {
        guard let pathComponents = components.path.components(separatedBy: "/").filter({ !$0.isEmpty }),
              !pathComponents.isEmpty else { return }
        
        switch pathComponents[0] {
        case "item":
            if pathComponents.count > 1, let itemId = UUID(uuidString: pathComponents[1]) {
                // Navigate to specific item - would need to fetch item by ID
                // navigateToWardrobe(.itemDetail(item))
            }
        case "add":
            navigateToWardrobe(.addItem)
        case "filters":
            navigateToWardrobe(.filters)
        default:
            break
        }
    }
    
    private func handleOutfitsDeepLink(components: URLComponents) {
        guard let pathComponents = components.path.components(separatedBy: "/").filter({ !$0.isEmpty }),
              !pathComponents.isEmpty else { return }
        
        switch pathComponents[0] {
        case "create":
            navigateToOutfits(.createOutfit)
        case "outfit":
            if pathComponents.count > 1, let outfitId = UUID(uuidString: pathComponents[1]) {
                // Navigate to specific outfit - would need to fetch outfit by ID
                // navigateToOutfits(.outfitDetail(outfit))
            }
        default:
            break
        }
    }
    
    private func handleProfileDeepLink(components: URLComponents) {
        guard let pathComponents = components.path.components(separatedBy: "/").filter({ !$0.isEmpty }),
              !pathComponents.isEmpty else { return }
        
        switch pathComponents[0] {
        case "settings":
            navigateToProfile(.settings)
        case "preferences":
            navigateToProfile(.preferences)
        case "subscription":
            navigateToProfile(.subscription)
        default:
            break
        }
    }
}

// MARK: - Navigation Destinations

enum HomeDestination: Hashable {
    case wardrobe
    case addItem
    case outfits
    case profile
    case analytics
    case recommendations
}

enum WardrobeDestination: Hashable {
    case itemDetail(WardrobeItem)
    case addItem
    case filters
    case camera
}

enum OutfitDestination: Hashable {
    case outfitDetail(Outfit)
    case createOutfit
    case editOutfit(Outfit)
}

enum ProfileDestination: Hashable {
    case settings
    case preferences
    case subscription
    case about
    case help
}

// MARK: - URL Schemes

extension URL {
    static func wardrobeItem(_ itemId: UUID) -> URL {
        URL(string: "stylematcher://wardrobe/item/\(itemId.uuidString)")!
    }
    
    static func wardrobeAdd() -> URL {
        URL(string: "stylematcher://wardrobe/add")!
    }
    
    static func outfitDetail(_ outfitId: UUID) -> URL {
        URL(string: "stylematcher://outfits/outfit/\(outfitId.uuidString)")!
    }
    
    static func createOutfit() -> URL {
        URL(string: "stylematcher://outfits/create")!
    }
    
    static func profileSettings() -> URL {
        URL(string: "stylematcher://profile/settings")!
    }
}