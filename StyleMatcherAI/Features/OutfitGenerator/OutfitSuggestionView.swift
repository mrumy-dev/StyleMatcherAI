import SwiftUI

struct OutfitSuggestionView: View {
    @StateObject private var viewModel = OutfitGeneratorViewModel()
    @State private var showFilters = false
    @State private var showSavedOutfits = false
    @State private var dragOffset: CGSize = .zero
    @State private var showRatingDialog = false
    @State private var selectedRating = 3.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.loadingOrEmpty {
                    emptyStateView
                } else {
                    outfitCardsView
                }
            }
            .navigationTitle("Outfit Suggestions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Filters") {
                        showFilters = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Saved Outfits") {
                            showSavedOutfits = true
                        }
                        Button("Refresh") {
                            Task {
                                await viewModel.refreshSuggestions()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheetView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSavedOutfits) {
                SavedOutfitsView(outfits: viewModel.savedOutfits)
            }
            .alert("Rate This Outfit", isPresented: $showRatingDialog) {
                Button("Cancel", role: .cancel) { }
                Button("Rate") {
                    if let currentSuggestion = viewModel.currentSuggestion {
                        Task {
                            await viewModel.rateOutfit(currentSuggestion.outfit, rating: selectedRating)
                        }
                    }
                }
            } message: {
                VStack {
                    Text("How much do you like this outfit combination?")
                    Slider(value: $selectedRating, in: 1...5, step: 1)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
        .task {
            if viewModel.suggestions.isEmpty {
                await viewModel.generateOutfitSuggestions()
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Generating outfit suggestions...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "tshirt")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("No Outfits Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if viewModel.canGenerateOutfits {
                    Text("Tap the button below to generate personalized outfit suggestions based on your wardrobe.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Generate Outfits") {
                        Task {
                            await viewModel.generateOutfitSuggestions()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Text("Add some clothing items to your wardrobe first to generate outfit suggestions.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    @ViewBuilder
    private var outfitCardsView: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<min(3, viewModel.suggestions.count), id: \.self) { index in
                    let actualIndex = viewModel.currentSuggestionIndex + index
                    if actualIndex < viewModel.suggestions.count {
                        OutfitCardView(
                            outfitWithScore: viewModel.suggestions[actualIndex],
                            isTopCard: index == 0,
                            dragOffset: index == 0 ? dragOffset : .zero
                        )
                        .scaleEffect(index == 0 ? 1.0 : 0.95 - CGFloat(index) * 0.05)
                        .offset(y: CGFloat(index) * 10)
                        .zIndex(Double(3 - index))
                        .gesture(
                            index == 0 ? cardDragGesture : nil
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 20)
        .overlay(alignment: .bottom) {
            actionButtonsView
        }
    }
    
    private var cardDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                
                withAnimation(.easeOut(duration: 0.3)) {
                    if value.translation.x > threshold {
                        dragOffset.x = 1000
                        Task {
                            await viewModel.likeOutfit()
                            viewModel.swipeToNext()
                        }
                    } else if value.translation.x < -threshold {
                        dragOffset.x = -1000
                        viewModel.swipeToNext()
                    } else if value.translation.y < -threshold {
                        selectedRating = 3.0
                        showRatingDialog = true
                    }
                    
                    dragOffset = .zero
                }
            }
    }
    
    @ViewBuilder
    private var actionButtonsView: some View {
        HStack(spacing: 40) {
            Button(action: {
                viewModel.swipeToNext()
            }) {
                Image(systemName: "xmark")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            
            Button(action: {
                selectedRating = 3.0
                showRatingDialog = true
            }) {
                Image(systemName: "star")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            
            Button(action: {
                Task {
                    await viewModel.likeOutfit()
                }
            }) {
                Image(systemName: "heart")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
        }
        .padding(.bottom, 40)
    }
}

struct OutfitCardView: View {
    let outfitWithScore: OutfitWithScore
    let isTopCard: Bool
    let dragOffset: CGSize
    
    var body: some View {
        VStack(spacing: 0) {
            outfitHeaderView
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(outfitWithScore.outfit.items) { item in
                        ClothingItemCardView(item: item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            scoreView
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: isTopCard ? 10 : 5)
        .offset(dragOffset)
        .rotation3DEffect(
            .degrees(Double(dragOffset.x) / 20),
            axis: (x: 0, y: 1, z: 0)
        )
        .opacity(isTopCard ? 1.0 : 0.8)
    }
    
    @ViewBuilder
    private var outfitHeaderView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(outfitWithScore.outfit.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(outfitWithScore.outfit.formality.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        if let weather = outfitWithScore.outfit.weather.first {
                            Text(weather.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                VStack {
                    Text(outfitWithScore.score.grade)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(gradeColor)
                    
                    Text("\(Int(outfitWithScore.score.total))/100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(gradeColor.opacity(0.1))
                .cornerRadius(12)
            }
            
            if !outfitWithScore.outfit.occasion.isEmpty {
                HStack {
                    ForEach(outfitWithScore.outfit.occasion, id: \.self) { occasion in
                        Text(occasion)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    @ViewBuilder
    private var scoreView: some View {
        HStack {
            ScoreComponentView(
                title: "Colors",
                score: outfitWithScore.score.colorHarmony,
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
            
            ScoreComponentView(
                title: "Formality",
                score: outfitWithScore.score.formalityMatch,
                color: .green
            )
            
            Divider()
                .frame(height: 40)
            
            ScoreComponentView(
                title: "Weather",
                score: outfitWithScore.score.weatherAppropriate,
                color: .orange
            )
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    private var gradeColor: Color {
        switch outfitWithScore.score.grade {
        case "A+", "A", "A-":
            return .green
        case "B+", "B", "B-":
            return .blue
        case "C+", "C", "C-":
            return .orange
        default:
            return .red
        }
    }
}

struct ClothingItemCardView: View {
    let item: WardrobeItem
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.thumbnailURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .overlay {
                        Image(systemName: categoryIcon)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !item.colors.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(item.colors.prefix(3), id: \.name) { color in
                            ColorDotView(color: color)
                        }
                        if item.colors.count > 3 {
                            Text("+\(item.colors.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            if item.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var categoryIcon: String {
        switch item.category {
        case .tops: return "tshirt"
        case .bottoms: return "pants"
        case .dresses: return "dress"
        case .shoes: return "shoe"
        case .outerwear: return "jacket"
        case .accessories: return "bag"
        default: return "tshirt"
        }
    }
}

struct ColorDotView: View {
    let color: ClothingColor
    
    var body: some View {
        Circle()
            .fill(colorFromHex(color.hexCode ?? "#808080"))
            .frame(width: 12, height: 12)
            .overlay {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            }
    }
    
    private func colorFromHex(_ hex: String) -> Color {
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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ScoreComponentView: View {
    let title: String
    let score: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text("\(Int(score * 100))%")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FilterSheetView: View {
    @ObservedObject var viewModel: OutfitGeneratorViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Formality") {
                    Picker("Formality Level", selection: $viewModel.selectedFormality) {
                        ForEach(FormalityLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Weather") {
                    ForEach(WeatherCondition.allCases, id: \.self) { condition in
                        HStack {
                            Image(systemName: condition.icon)
                            Text(condition.displayName)
                            Spacer()
                            if viewModel.selectedWeatherConditions.contains(condition) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if viewModel.selectedWeatherConditions.contains(condition) {
                                viewModel.selectedWeatherConditions.removeAll { $0 == condition }
                            } else {
                                viewModel.selectedWeatherConditions.append(condition)
                            }
                        }
                    }
                }
                
                Section("Occasions") {
                    ForEach(commonOccasions, id: \.self) { occasion in
                        HStack {
                            Text(occasion)
                            Spacer()
                            if viewModel.selectedOccasions.contains(occasion) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if viewModel.selectedOccasions.contains(occasion) {
                                viewModel.selectedOccasions.removeAll { $0 == occasion }
                            } else {
                                viewModel.selectedOccasions.append(occasion)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        Task {
                            await viewModel.generateOutfitSuggestions()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private let commonOccasions = [
        "Work", "Casual", "Date Night", "Party", "Wedding", "Business Meeting",
        "Travel", "Weekend", "Brunch", "Dinner", "Shopping", "Exercise"
    ]
}

struct SavedOutfitsView: View {
    let outfits: [Outfit]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(outfits) { outfit in
                VStack(alignment: .leading, spacing: 8) {
                    Text(outfit.name)
                        .font(.headline)
                    
                    Text("\(outfit.items.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if outfit.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                        }
                        
                        if let rating = outfit.rating {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Text("Worn \(outfit.timesWorn) times")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Saved Outfits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    OutfitSuggestionView()
}