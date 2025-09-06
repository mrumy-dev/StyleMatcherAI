import SwiftUI

struct WardrobeFiltersView: View {
    @Binding var filters: WardrobeFilters
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempFilters: WardrobeFilters
    
    init(filters: Binding<WardrobeFilters>) {
        self._filters = filters
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                categorySection
                colorSection
                formalitySection
                seasonSection
                conditionSection
                quickFiltersSection
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
        }
    }
    
    private var categorySection: some View {
        Section("Categories") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(ClothingCategory.allCases, id: \.self) { category in
                    CategoryFilterChip(
                        category: category,
                        isSelected: tempFilters.categories.contains(category)
                    ) {
                        if tempFilters.categories.contains(category) {
                            tempFilters.categories.remove(category)
                        } else {
                            tempFilters.categories.insert(category)
                        }
                    }
                }
            }
            
            if !tempFilters.categories.isEmpty {
                Button("Clear Categories", role: .destructive) {
                    tempFilters.categories.removeAll()
                }
                .font(.caption)
            }
        }
    }
    
    private var colorSection: some View {
        Section("Colors") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(ClothingColor.commonColors, id: \.name) { color in
                    ColorFilterChip(
                        color: color,
                        isSelected: tempFilters.colors.contains(color.name)
                    ) {
                        if let index = tempFilters.colors.firstIndex(of: color.name) {
                            tempFilters.colors.remove(at: index)
                        } else {
                            tempFilters.colors.append(color.name)
                        }
                    }
                }
            }
            
            if !tempFilters.colors.isEmpty {
                Button("Clear Colors", role: .destructive) {
                    tempFilters.colors.removeAll()
                }
                .font(.caption)
            }
        }
    }
    
    private var formalitySection: some View {
        Section("Formality Level") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(FormalityLevel.allCases, id: \.self) { level in
                    FormalityFilterChip(
                        formality: level,
                        isSelected: tempFilters.formalityLevels.contains(level)
                    ) {
                        if tempFilters.formalityLevels.contains(level) {
                            tempFilters.formalityLevels.remove(level)
                        } else {
                            tempFilters.formalityLevels.insert(level)
                        }
                    }
                }
            }
            
            if !tempFilters.formalityLevels.isEmpty {
                Button("Clear Formality", role: .destructive) {
                    tempFilters.formalityLevels.removeAll()
                }
                .font(.caption)
            }
        }
    }
    
    private var seasonSection: some View {
        Section("Seasons") {
            HStack {
                ForEach(Season.allCases, id: \.self) { season in
                    SeasonFilterChip(
                        season: season,
                        isSelected: tempFilters.seasons.contains(season)
                    ) {
                        if tempFilters.seasons.contains(season) {
                            tempFilters.seasons.remove(season)
                        } else {
                            tempFilters.seasons.insert(season)
                        }
                    }
                }
                Spacer()
            }
            
            if !tempFilters.seasons.isEmpty {
                Button("Clear Seasons", role: .destructive) {
                    tempFilters.seasons.removeAll()
                }
                .font(.caption)
            }
        }
    }
    
    private var conditionSection: some View {
        Section("Condition") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(ItemCondition.allCases, id: \.self) { condition in
                    ConditionFilterChip(
                        condition: condition,
                        isSelected: tempFilters.conditions.contains(condition)
                    ) {
                        if tempFilters.conditions.contains(condition) {
                            tempFilters.conditions.remove(condition)
                        } else {
                            tempFilters.conditions.insert(condition)
                        }
                    }
                }
            }
            
            if !tempFilters.conditions.isEmpty {
                Button("Clear Conditions", role: .destructive) {
                    tempFilters.conditions.removeAll()
                }
                .font(.caption)
            }
        }
    }
    
    private var quickFiltersSection: some View {
        Section("Quick Filters") {
            VStack(spacing: 12) {
                Toggle("Favorites Only", isOn: $tempFilters.favoritesOnly)
                
                Toggle("Recently Worn (last 30 days)", isOn: $tempFilters.recentlyWorn)
            }
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Apply Filters") {
                        filters = tempFilters
                        dismiss()
                    }
                    .disabled(tempFilters.isEmpty)
                    
                    Divider()
                    
                    Button("Clear All", role: .destructive) {
                        tempFilters = WardrobeFilters()
                    }
                } label: {
                    Text("Done")
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var activeFiltersCount: Int {
        var count = 0
        count += tempFilters.categories.count
        count += tempFilters.colors.count
        count += tempFilters.formalityLevels.count
        count += tempFilters.seasons.count
        count += tempFilters.conditions.count
        if tempFilters.favoritesOnly { count += 1 }
        if tempFilters.recentlyWorn { count += 1 }
        return count
    }
}

// MARK: - Filter Chips

struct CategoryFilterChip: View {
    let category: ClothingCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: categoryIcon)
                    .font(.system(size: 20))
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    private var categoryIcon: String {
        switch category {
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
}

struct ColorFilterChip: View {
    let color: ClothingColor
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: color.hexCode ?? "#808080") ?? .gray)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
                
                Text(color.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

struct FormalityFilterChip: View {
    let formality: FormalityLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: formalityIcon)
                    .font(.system(size: 18))
                
                Text(formality.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    private var formalityIcon: String {
        switch formality {
        case .casual: return "tshirt"
        case .smartCasual: return "shirt"
        case .business: return "person.badge.key"
        case .formal: return "suit"
        case .mixed: return "rectangle.3.group"
        }
    }
}

struct SeasonFilterChip: View {
    let season: Season
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: seasonIcon)
                    .font(.system(size: 16))
                
                Text(season.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70, height: 45)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    private var seasonIcon: String {
        switch season {
        case .spring: return "leaf"
        case .summer: return "sun.max"
        case .fall: return "leaf.arrow.circlepath"
        case .winter: return "snowflake"
        }
    }
}

struct ConditionFilterChip: View {
    let condition: ItemCondition
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Circle()
                    .fill(condition.color)
                    .frame(width: 16, height: 16)
                
                Text(condition.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(isSelected ? condition.color.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? condition.color : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? condition.color : Color(.systemGray4), lineWidth: 1)
            )
        }
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
    @State var sampleFilters = WardrobeFilters()
    
    return WardrobeFiltersView(filters: $sampleFilters)
}