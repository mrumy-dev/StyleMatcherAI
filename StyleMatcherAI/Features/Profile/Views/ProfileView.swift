import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeaderSection
                    statisticsSection
                    preferencesSection
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotoLibraryPicker { images in
                    // Handle avatar update
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadProfile()
            }
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            Button {
                showingImagePicker = true
            } label: {
                AsyncImage(url: URL(string: viewModel.user?.avatarURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.secondary)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 2)
                )
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                )
            }
            
            VStack(spacing: 4) {
                Text(viewModel.user?.displayName ?? "Your Name")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(viewModel.user?.email ?? "email@example.com")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let subscription = viewModel.subscriptionInfo {
                    SubscriptionBadge(subscription: subscription)
                }
            }
        }
    }
    
    private var statisticsSection: Some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Style Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Items",
                    value: "\(viewModel.stats.totalItems)",
                    icon: "tshirt",
                    color: .blue
                )
                
                StatCard(
                    title: "Outfits",
                    value: "\(viewModel.stats.totalOutfits)",
                    icon: "person.2",
                    color: .purple
                )
                
                StatCard(
                    title: "Favorites",
                    value: "\(viewModel.stats.favoriteItems)",
                    icon: "heart.fill",
                    color: .red
                )
                
                StatCard(
                    title: "This Month",
                    value: "\(viewModel.stats.itemsWornThisMonth)",
                    icon: "calendar",
                    color: .green
                )
                
                StatCard(
                    title: "Categories",
                    value: "\(viewModel.stats.categoriesOwned)",
                    icon: "square.grid.2x2",
                    color: .orange
                )
                
                StatCard(
                    title: "Avg. Wear",
                    value: String(format: "%.1f", viewModel.stats.averageWearCount),
                    icon: "repeat",
                    color: .cyan
                )
            }
        }
    }
    
    private var preferencesSection: Some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Style Preferences")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                PreferenceRow(
                    title: "Preferred Style",
                    value: viewModel.user?.preferences?.stylePreference.primary ?? "Not set",
                    icon: "paintbrush"
                )
                
                PreferenceRow(
                    title: "Formality Level",
                    value: viewModel.user?.preferences?.stylePreference.formality.displayName ?? "Not set",
                    icon: "person.badge.key"
                )
                
                PreferenceRow(
                    title: "Size System",
                    value: viewModel.user?.preferences?.sizeSystem.displayName ?? "US",
                    icon: "ruler"
                )
                
                PreferenceRow(
                    title: "Currency",
                    value: viewModel.user?.preferences?.currency ?? "USD",
                    icon: "dollarsign.circle"
                )
            }
        }
    }
    
    private var actionsSection: Some View {
        VStack(spacing: 12) {
            ProfileActionButton(
                title: "Settings",
                icon: "gearshape",
                color: .blue
            ) {
                showingSettings = true
            }
            
            ProfileActionButton(
                title: "Analytics",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            ) {
                // Navigate to analytics
            }
            
            ProfileActionButton(
                title: "Export Data",
                icon: "square.and.arrow.up",
                color: .orange
            ) {
                Task {
                    await viewModel.exportUserData()
                }
            }
            
            ProfileActionButton(
                title: "Help & Support",
                icon: "questionmark.circle",
                color: .purple
            ) {
                // Navigate to help
            }
            
            if viewModel.user?.subscriptionStatus == .free {
                ProfileActionButton(
                    title: "Upgrade to Premium",
                    icon: "crown",
                    color: .yellow
                ) {
                    // Navigate to subscription
                }
            }
        }
    }
    
    private var toolbarContent: Some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
        }
    }
}

struct SubscriptionBadge: View {
    let subscription: SubscriptionInfo
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: subscription.isPremium ? "crown.fill" : "person.crop.circle")
                .font(.caption2)
            
            Text(subscription.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(subscription.color.opacity(0.2))
        .foregroundColor(subscription.color)
        .cornerRadius(8)
    }
}

struct PreferenceRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ProfileActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Models

struct ProfileStats {
    let totalItems: Int
    let totalOutfits: Int
    let favoriteItems: Int
    let itemsWornThisMonth: Int
    let categoriesOwned: Int
    let averageWearCount: Double
    
    init(
        totalItems: Int = 0,
        totalOutfits: Int = 0,
        favoriteItems: Int = 0,
        itemsWornThisMonth: Int = 0,
        categoriesOwned: Int = 0,
        averageWearCount: Double = 0
    ) {
        self.totalItems = totalItems
        self.totalOutfits = totalOutfits
        self.favoriteItems = favoriteItems
        self.itemsWornThisMonth = itemsWornThisMonth
        self.categoriesOwned = categoriesOwned
        self.averageWearCount = averageWearCount
    }
}

struct SubscriptionInfo {
    let isPremium: Bool
    let displayName: String
    let color: Color
    
    init(status: SubscriptionStatus) {
        switch status {
        case .free:
            self.isPremium = false
            self.displayName = "Free"
            self.color = .secondary
        case .active:
            self.isPremium = true
            self.displayName = "Premium"
            self.color = .yellow
        case .trialing:
            self.isPremium = true
            self.displayName = "Trial"
            self.color = .blue
        default:
            self.isPremium = false
            self.displayName = "Free"
            self.color = .secondary
        }
    }
}

#Preview {
    ProfileView()
}