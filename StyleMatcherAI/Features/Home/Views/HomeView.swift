import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @StateObject private var homeViewModel = HomeViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                quickActionsSection
                wardrobeOverviewSection
                recentActivitySection
                recommendationsSection
            }
            .padding()
        }
        .navigationTitle("StyleMatcher AI")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await homeViewModel.refreshData()
        }
        .onAppear {
            Task {
                await homeViewModel.loadData()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Good \(timeOfDayGreeting)")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Ready to style?")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Button {
                    navigationCoordinator.navigateToProfile(.settings)
                } label: {
                    AsyncImage(url: URL(string: homeViewModel.userAvatarURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                }
            }
            
            if let weatherInfo = homeViewModel.weatherInfo {
                WeatherBanner(weather: weatherInfo)
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "Add Item",
                    subtitle: "Scan & analyze",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    navigationCoordinator.navigateToHome(.addItem)
                }
                
                QuickActionCard(
                    title: "Browse Wardrobe",
                    subtitle: "\(homeViewModel.wardrobeItemCount) items",
                    icon: "tshirt.fill",
                    color: .purple
                ) {
                    navigationCoordinator.navigateToHome(.wardrobe)
                }
                
                QuickActionCard(
                    title: "Create Outfit",
                    subtitle: "AI suggestions",
                    icon: "sparkles",
                    color: .orange
                ) {
                    navigationCoordinator.navigateToHome(.outfits)
                }
                
                QuickActionCard(
                    title: "Style Analytics",
                    subtitle: "Your trends",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                ) {
                    navigationCoordinator.navigateToHome(.analytics)
                }
            }
        }
    }
    
    private var wardrobeOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Wardrobe Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    navigationCoordinator.navigateToHome(.wardrobe)
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if homeViewModel.isLoading {
                WardrobeOverviewSkeleton()
            } else {
                WardrobeOverviewCards(stats: homeViewModel.wardrobeStats)
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            if homeViewModel.recentItems.isEmpty {
                RecentActivityEmptyState {
                    navigationCoordinator.navigateToHome(.addItem)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(homeViewModel.recentItems) { item in
                            RecentItemCard(item: item) {
                                navigationCoordinator.navigateToWardrobe(.itemDetail(item))
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    navigationCoordinator.navigateToHome(.recommendations)
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if let recommendations = homeViewModel.recommendations, !recommendations.isEmpty {
                ForEach(recommendations.prefix(3), id: \.id) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            } else {
                RecommendationEmptyState()
            }
        }
    }
    
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        default:
            return "evening"
        }
    }
}

// MARK: - Supporting Views

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .frame(height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WeatherBanner: View {
    let weather: WeatherInfo
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: weather.icon)
                .foregroundColor(.blue)
            
            Text("\(weather.temperature)° - \(weather.description)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Perfect for \(weather.clothingRecommendation)")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct WardrobeOverviewCards: View {
    let stats: WardrobeStats
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total Items",
                value: "\(stats.totalItems)",
                icon: "tshirt",
                color: .blue
            )
            
            StatCard(
                title: "Favorites",
                value: "\(stats.favoriteItems)",
                icon: "heart.fill",
                color: .red
            )
            
            StatCard(
                title: "Most Worn",
                value: stats.mostWornCategory,
                icon: "chart.bar.fill",
                color: .green
            )
        }
    }
}

struct WardrobeOverviewSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 60)
                    .redacted(reason: .placeholder)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct RecentItemCard: View {
    let item: WardrobeItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: item.thumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "tshirt")
                                .foregroundColor(.gray)
                        }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
            .frame(width: 90)
        }
    }
}

struct RecentActivityEmptyState: View {
    let onAddItem: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tshirt")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No items yet")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Add your first clothing item to get started")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Item", action: onAddItem)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationCard: View {
    let recommendation: StyleRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendation.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("No recommendations yet")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Add more items to get personalized suggestions")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        HomeView()
            .environmentObject(NavigationCoordinator())
    }
}