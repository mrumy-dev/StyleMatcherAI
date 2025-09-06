import SwiftUI

struct MainTabView: View {
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @State private var selectedTab: AppTab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $navigationCoordinator.homePath) {
                HomeView()
                    .navigationDestination(for: HomeDestination.self) { destination in
                        navigationCoordinator.view(for: destination)
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(AppTab.home)
            
            NavigationStack(path: $navigationCoordinator.wardrobePath) {
                WardrobeGridView()
                    .navigationDestination(for: WardrobeDestination.self) { destination in
                        navigationCoordinator.view(for: destination)
                    }
            }
            .tabItem {
                Label("Wardrobe", systemImage: "tshirt")
            }
            .tag(AppTab.wardrobe)
            
            NavigationStack {
                AddItemView()
            }
            .tabItem {
                Label("Add", systemImage: "plus.circle.fill")
            }
            .tag(AppTab.add)
            
            NavigationStack(path: $navigationCoordinator.outfitsPath) {
                OutfitsView()
                    .navigationDestination(for: OutfitDestination.self) { destination in
                        navigationCoordinator.view(for: destination)
                    }
            }
            .tabItem {
                Label("Outfits", systemImage: "person.2")
            }
            .tag(AppTab.outfits)
            
            NavigationStack(path: $navigationCoordinator.profilePath) {
                ProfileView()
                    .navigationDestination(for: ProfileDestination.self) { destination in
                        navigationCoordinator.view(for: destination)
                    }
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
            .tag(AppTab.profile)
        }
        .onOpenURL { url in
            navigationCoordinator.handleDeepLink(url: url, selectedTab: $selectedTab)
        }
        .environmentObject(navigationCoordinator)
    }
}

enum AppTab: String, CaseIterable {
    case home = "home"
    case wardrobe = "wardrobe"
    case add = "add"
    case outfits = "outfits"
    case profile = "profile"
    
    var displayName: String {
        switch self {
        case .home: return "Home"
        case .wardrobe: return "Wardrobe"
        case .add: return "Add"
        case .outfits: return "Outfits"
        case .profile: return "Profile"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .wardrobe: return "tshirt"
        case .add: return "plus.circle.fill"
        case .outfits: return "person.2"
        case .profile: return "person.circle"
        }
    }
}

#Preview {
    MainTabView()
}