import SwiftUI
import Kingfisher

struct WardrobeItemDetailView: View {
    let item: WardrobeItem
    let onUpdate: (WardrobeItem) -> Void
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var showingWornSheet = false
    @State private var showingImageGallery = false
    @State private var selectedImageIndex = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    imageSection
                    itemDetailsSection
                    colorsAndPatternsSection
                    styleSectionView
                    usageStatsSection
                    notesSection
                }
                .padding()
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingEditView) {
                EditWardrobeItemView(item: item) { updatedItem in
                    onUpdate(updatedItem)
                }
            }
            .sheet(isPresented: $showingImageGallery) {
                ImageGalleryView(
                    imageURLs: item.imageURLs,
                    selectedIndex: $selectedImageIndex
                )
            }
            .sheet(isPresented: $showingWornSheet) {
                WornTrackingView(item: item) { updatedItem in
                    onUpdate(updatedItem)
                }
            }
            .alert("Delete Item", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("Are you sure you want to delete \"\(item.name)\"? This action cannot be undone.")
            }
        }
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !item.imageURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(item.imageURLs.enumerated()), id: \.offset) { index, imageURL in
                            Button {
                                selectedImageIndex = index
                                showingImageGallery = true
                            } label: {
                                KFImage(URL(string: imageURL))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 200, height: 240)
                                    .clipped()
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal, -16)
            } else {
                placeholderImageView
            }
            
            if item.imageURLs.count > 1 {
                HStack {
                    Text("\(item.imageURLs.count) photos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("View All") {
                        showingImageGallery = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var placeholderImageView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray5))
            .frame(height: 240)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No photos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Add Photos") {
                        showingEditView = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
    }
    
    private var itemDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and favorite button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let brand = item.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(item.isFavorite ? .red : .secondary)
                }
            }
            
            // Category and subcategory
            HStack {
                Label(item.category.displayName, systemImage: categoryIcon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let subcategory = item.subcategory {
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(subcategory)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ConditionBadge(condition: item.condition)
            }
            
            // Description
            if let description = item.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var colorsAndPatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Colors & Patterns")
                .font(.headline)
            
            // Colors
            if !item.colors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Colors")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(item.colors, id: \.name) { color in
                                ColorChip(color: color)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
            
            // Patterns
            if !item.patterns.isEmpty && item.patterns != [.solid] {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Patterns")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        ForEach(item.patterns, id: \.self) { pattern in
                            PatternChip(pattern: pattern)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var styleSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Style Details")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StyleDetailCard(
                    title: "Formality",
                    value: item.formality.displayName,
                    icon: "person.badge.key"
                )
                
                if !item.materials.isEmpty {
                    StyleDetailCard(
                        title: "Materials",
                        value: item.materials.joined(separator: ", "),
                        icon: "textformat"
                    )
                }
                
                if !item.season.isEmpty {
                    StyleDetailCard(
                        title: "Seasons",
                        value: item.season.map { $0.displayName }.joined(separator: ", "),
                        icon: "calendar"
                    )
                }
                
                if !item.occasion.isEmpty {
                    StyleDetailCard(
                        title: "Occasions",
                        value: item.occasion.joined(separator: ", "),
                        icon: "star"
                    )
                }
                
                if let size = item.size {
                    StyleDetailCard(
                        title: "Size",
                        value: "\(size.system.displayName) \(size.value)",
                        icon: "ruler"
                    )
                }
                
                if let purchasePrice = item.purchasePrice {
                    StyleDetailCard(
                        title: "Price",
                        value: String(format: "%.2f %@", purchasePrice, item.currency),
                        icon: "dollarsign.circle"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var usageStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Usage Statistics")
                    .font(.headline)
                
                Spacer()
                
                Button("Mark as Worn") {
                    showingWornSheet = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 20) {
                UsageStatCard(
                    title: "Times Worn",
                    value: "\(item.timesWorn)",
                    icon: "repeat",
                    color: .blue
                )
                
                UsageStatCard(
                    title: "Last Worn",
                    value: lastWornText,
                    icon: "clock",
                    color: .green
                )
                
                UsageStatCard(
                    title: "Added",
                    value: RelativeDateTimeFormatter().localizedString(for: item.createdAt, relativeTo: Date()),
                    icon: "plus.circle",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
            
            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            } else {
                Text("No notes added")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Button("Edit Notes") {
                showingEditView = true
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditView = true
                    } label: {
                        Label("Edit Item", systemImage: "pencil")
                    }
                    
                    Button {
                        toggleFavorite()
                    } label: {
                        Label(
                            item.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: item.isFavorite ? "heart.slash" : "heart"
                        )
                    }
                    
                    Button {
                        showingWornSheet = true
                    } label: {
                        Label("Mark as Worn", systemImage: "checkmark.circle")
                    }
                    
                    Divider()
                    
                    Button("Archive", systemImage: "archivebox") {
                        // Archive functionality
                    }
                    
                    Button("Duplicate", systemImage: "doc.on.doc") {
                        // Duplicate functionality
                    }
                    
                    Divider()
                    
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private var categoryIcon: String {
        switch item.category {
        case .tops: return "tshirt"
        case .bottoms: return "pants"
        case .dresses: return "dress"
        case .outerwear: return "coat"
        case .shoes: return "shoe.2"
        case .accessories: return "bag"
        case .underwear: return "underwear"
        case .activewear: return "sportscourt"
        case .sleepwear: return "bed.double"
        case .swimwear: return "drop.triangle"
        }
    }
    
    private var lastWornText: String {
        if let lastWorn = item.lastWornAt {
            return RelativeDateTimeFormatter().localizedString(for: lastWorn, relativeTo: Date())
        } else {
            return "Never"
        }
    }
    
    private func toggleFavorite() {
        // This would typically be handled by the parent view
        // For now, we'll just simulate the toggle
        let updatedItem = WardrobeItem(
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
        
        onUpdate(updatedItem)
    }
}

// MARK: - Supporting Views

struct ColorChip: View {
    let color: ClothingColor
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: color.hexCode) ?? .gray)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
            
            Text(color.name)
                .font(.caption)
                .fontWeight(color.isPrimary ? .medium : .regular)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

struct PatternChip: View {
    let pattern: ClothingPattern
    
    var body: some View {
        Text(pattern.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
    }
}

struct ConditionBadge: View {
    let condition: ItemCondition
    
    var body: some View {
        Text(condition.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(condition.color.opacity(0.1))
            .foregroundColor(condition.color)
            .cornerRadius(8)
    }
}

struct StyleDetailCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct UsageStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Additional Views (placeholders)

struct EditWardrobeItemView: View {
    let item: WardrobeItem
    let onUpdate: (WardrobeItem) -> Void
    
    var body: some View {
        NavigationView {
            Text("Edit Item View")
                .navigationTitle("Edit Item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            // Dismiss
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            // Save changes
                        }
                    }
                }
        }
    }
}

struct WornTrackingView: View {
    let item: WardrobeItem
    let onUpdate: (WardrobeItem) -> Void
    
    var body: some View {
        NavigationView {
            Text("Worn Tracking View")
                .navigationTitle("Mark as Worn")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ImageGalleryView: View {
    let imageURLs: [String]
    @Binding var selectedIndex: Int
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, imageURL in
                KFImage(URL(string: imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .background(Color.black)
    }
}

// MARK: - Extensions

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    let sampleItem = WardrobeItem(
        userId: UUID(),
        name: "Navy Blazer",
        description: "Classic navy blazer perfect for business occasions",
        category: .outerwear,
        subcategory: "Blazer",
        brand: "Hugo Boss",
        colors: [
            ClothingColor(name: "Navy", hexCode: "#1E3A8A", isPrimary: true),
            ClothingColor(name: "Silver", hexCode: "#C0C0C0", isPrimary: false)
        ],
        patterns: [.solid],
        formality: .business,
        timesWorn: 5,
        lastWornAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())
    )
    
    WardrobeItemDetailView(
        item: sampleItem,
        onUpdate: { _ in },
        onDelete: { }
    )
}