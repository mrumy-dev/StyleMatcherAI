import SwiftUI

struct WardrobeGridView: View {
    @StateObject private var viewModel = WardrobeViewModel()
    @State private var showingAddItem = false
    @State private var showingFilters = false
    @State private var selectedItem: WardrobeItem?
    @State private var showingSearch = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.items.isEmpty {
                    loadingView
                } else if viewModel.filteredItems.isEmpty && !viewModel.searchText.isEmpty {
                    searchEmptyStateView
                } else if viewModel.items.isEmpty {
                    emptyStateView
                } else {
                    mainContent
                }
            }
            .navigationTitle("My Wardrobe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search wardrobe..."
            )
            .refreshable {
                await viewModel.loadItems()
            }
            .sheet(isPresented: $showingAddItem) {
                AddWardrobeItemView { newItem in
                    viewModel.addItem(newItem)
                }
            }
            .sheet(item: $selectedItem) { item in
                WardrobeItemDetailView(item: item) { updatedItem in
                    viewModel.updateItem(updatedItem)
                } onDelete: {
                    viewModel.deleteItem(item)
                    selectedItem = nil
                }
            }
            .sheet(isPresented: $showingFilters) {
                WardrobeFiltersView(filters: $viewModel.filters)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
        .onAppear {
            if viewModel.items.isEmpty {
                Task {
                    await viewModel.loadItems()
                }
            }
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.hasActiveFilters {
                    filterSummaryView
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.filteredItems) { item in
                        WardrobeThumbnailView(
                            item: item,
                            size: .medium
                        ) {
                            selectedItem = item
                        }
                        .contextMenu {
                            contextMenuContent(for: item)
                        }
                    }
                }
                .padding(.horizontal)
                
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.top, 8)
        }
        .onAppear {
            viewModel.trackViewEvent()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            WardrobeGridSkeleton(
                columns: 2,
                rows: 4,
                thumbnailSize: .medium
            )
            
            Text("Loading your wardrobe...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            WardrobeEmptyStateView {
                showingAddItem = true
            }
        }
    }
    
    private var searchEmptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No items found")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Clear Search") {
                viewModel.searchText = ""
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var filterSummaryView: some View {
        HStack {
            Text("Filters applied")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Clear") {
                viewModel.clearFilters()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingAddItem = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    
                    Button {
                        showingFilters = true
                    } label: {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    
                    Menu("Sort By") {
                        Button("Recently Added") {
                            viewModel.sortBy(.dateAdded)
                        }
                        
                        Button("Name") {
                            viewModel.sortBy(.name)
                        }
                        
                        Button("Category") {
                            viewModel.sortBy(.category)
                        }
                        
                        Button("Most Worn") {
                            viewModel.sortBy(.timesWorn)
                        }
                    }
                    
                    if !viewModel.items.isEmpty {
                        Divider()
                        
                        Button("Select Multiple") {
                            viewModel.toggleSelectionMode()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.isSelectionMode {
                    Button("Cancel") {
                        viewModel.exitSelectionMode()
                    }
                } else {
                    EmptyView()
                }
            }
        }
    }
    
    @ViewBuilder
    private func contextMenuContent(for item: WardrobeItem) -> some View {
        Button {
            selectedItem = item
        } label: {
            Label("View Details", systemImage: "info.circle")
        }
        
        Button {
            viewModel.toggleFavorite(item)
        } label: {
            Label(
                item.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                systemImage: item.isFavorite ? "heart.slash" : "heart"
            )
        }
        
        Button {
            viewModel.markAsWorn(item)
        } label: {
            Label("Mark as Worn", systemImage: "checkmark.circle")
        }
        
        Divider()
        
        Button {
            viewModel.archiveItem(item)
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
        
        Button(role: .destructive) {
            viewModel.deleteItem(item)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Empty State View

struct WardrobeEmptyStateView: View {
    let onAddItem: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "tshirt")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Build Your Wardrobe")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Start by adding your first clothing item. Take a photo and let our AI analyze it for you!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            
            VStack(spacing: 12) {
                Button {
                    onAddItem()
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Add Your First Item")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                onboardingTips
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
    
    private var onboardingTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Getting Started Tips:")
                .font(.headline)
                .padding(.bottom, 4)
            
            OnboardingTipRow(
                icon: "camera.fill",
                title: "Take Clear Photos",
                description: "Use good lighting and center items in frame"
            )
            
            OnboardingTipRow(
                icon: "cpu",
                title: "AI Analysis",
                description: "Our AI identifies colors, patterns, and style"
            )
            
            OnboardingTipRow(
                icon: "rectangle.grid.2x2",
                title: "Organize & Browse",
                description: "Filter by type, color, and occasion"
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct OnboardingTipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Selection Mode Extensions

extension WardrobeGridView {
    private var selectionModeContent: some View {
        VStack {
            selectionToolbar
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.filteredItems) { item in
                        WardrobeSelectionThumbnail(
                            item: item,
                            isSelected: viewModel.selectedItems.contains(item.id),
                            onSelectionChanged: { isSelected in
                                if isSelected {
                                    viewModel.selectItem(item)
                                } else {
                                    viewModel.deselectItem(item)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var selectionToolbar: some View {
        HStack {
            Text("\(viewModel.selectedItems.count) selected")
                .font(.headline)
            
            Spacer()
            
            if !viewModel.selectedItems.isEmpty {
                Menu("Actions") {
                    Button("Mark as Worn") {
                        viewModel.markSelectedAsWorn()
                    }
                    
                    Button("Add to Favorites") {
                        viewModel.addSelectedToFavorites()
                    }
                    
                    Button("Archive") {
                        viewModel.archiveSelected()
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        viewModel.deleteSelected()
                    }
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct WardrobeSelectionThumbnail: View {
    let item: WardrobeItem
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    
    var body: some View {
        Button {
            onSelectionChanged(!isSelected)
        } label: {
            ZStack(alignment: .topTrailing) {
                WardrobeThumbnailView(item: item, size: .medium) {
                    onSelectionChanged(!isSelected)
                }
                
                Button {
                    onSelectionChanged(!isSelected)
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .white)
                        .background(
                            Circle()
                                .fill(isSelected ? .white : .black.opacity(0.3))
                                .frame(width: 28, height: 28)
                        )
                }
                .offset(x: 8, y: -8)
            }
        }
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    WardrobeGridView()
}