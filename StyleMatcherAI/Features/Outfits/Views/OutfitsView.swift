import SwiftUI

struct OutfitsView: View {
    @StateObject private var viewModel = OutfitsViewModel()
    @State private var showingCreateOutfit = false
    @State private var selectedOutfit: Outfit?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.outfits.isEmpty {
                    loadingView
                } else if viewModel.outfits.isEmpty {
                    emptyStateView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Outfits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .refreshable {
                await viewModel.loadOutfits()
            }
            .sheet(isPresented: $showingCreateOutfit) {
                CreateOutfitView()
            }
            .sheet(item: $selectedOutfit) { outfit in
                OutfitDetailView(outfit: outfit)
            }
        }
        .onAppear {
            if viewModel.outfits.isEmpty {
                Task {
                    await viewModel.loadOutfits()
                }
            }
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                featuredSection
                myOutfitsSection
            }
            .padding()
        }
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Suggestion")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let todaysOutfit = viewModel.todaysOutfit {
                TodaysOutfitCard(outfit: todaysOutfit) {
                    selectedOutfit = todaysOutfit
                }
            } else {
                CreateOutfitPromptCard {
                    showingCreateOutfit = true
                }
            }
        }
    }
    
    private var myOutfitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Outfits")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Menu {
                    Button("All Outfits") {
                        viewModel.filterBy(.all)
                    }
                    Button("Favorites") {
                        viewModel.filterBy(.favorites)
                    }
                    Button("Recent") {
                        viewModel.filterBy(.recent)
                    }
                    Button("By Season") {
                        viewModel.filterBy(.seasonal)
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.filteredOutfits) { outfit in
                    OutfitCard(outfit: outfit) {
                        selectedOutfit = outfit
                    }
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading outfits...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Create Your First Outfit")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Mix and match items from your wardrobe to create stylish outfits")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingCreateOutfit = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Outfit")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 32)
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateOutfit = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
    }
}

struct TodaysOutfitCard: View {
    let outfit: Outfit
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Perfect for today's weather")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text(outfit.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(outfit.items.count) items")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // Outfit items preview
                HStack(spacing: 8) {
                    ForEach(outfit.items.prefix(4), id: \.id) { item in
                        AsyncImage(url: URL(string: item.thumbnailURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray5))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    if outfit.items.count > 4 {
                        Text("+\(outfit.items.count - 4)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CreateOutfitPromptCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Get AI Outfit Suggestion")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Let AI create the perfect outfit for today's weather and your style")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OutfitCard: View {
    let outfit: Outfit
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Outfit preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .aspectRatio(1, contentMode: .fit)
                    
                    if let firstItem = outfit.items.first,
                       let imageURL = firstItem.thumbnailURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack {
                            Image(systemName: "person.2")
                                .font(.title)
                                .foregroundColor(.secondary)
                            
                            Text("\(outfit.items.count) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Favorite indicator
                    if outfit.isFavorite {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                                    .background(
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 24, height: 24)
                                    )
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(outfit.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(outfit.occasion.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OutfitsView()
}