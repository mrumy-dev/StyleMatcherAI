import SwiftUI
import PhotosUI

struct AddWardrobeItemView: View {
    let onSave: (WardrobeItem) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var name = ""
    @State private var description = ""
    @State private var selectedCategory: ClothingCategory = .tops
    @State private var subcategory = ""
    @State private var brand = ""
    @State private var selectedColors: [ClothingColor] = []
    @State private var selectedPatterns: [ClothingPattern] = [.solid]
    @State private var materials: [String] = []
    @State private var materialInput = ""
    @State private var formality: FormalityLevel = .casual
    @State private var selectedSeasons: Set<Season> = []
    @State private var occasions: [String] = []
    @State private var occasionInput = ""
    @State private var size: ClothingSize?
    @State private var purchaseDate: Date = Date()
    @State private var hasPurchaseDate = false
    @State private var purchasePrice: Double?
    @State private var currency = "USD"
    @State private var condition: ItemCondition = .excellent
    @State private var careInstructions: [String] = []
    @State private var careInstruction = ""
    @State private var tags: [String] = []
    @State private var tagInput = ""
    @State private var notes = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imageData: [Data] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isAnalyzing = false
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                imageSection
                basicInfoSection
                colorAndPatternSection
                detailsSection
                priceSection
                careSection
                notesSection
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotosPicker(
                    selection: $selectedImages,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    Text("Select Photos")
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(viewModel: cameraViewModel)
            }
            .onChange(of: selectedImages) { newItems in
                Task {
                    await loadImages(from: newItems)
                }
            }
            .onChange(of: cameraViewModel.capturedImage) { image in
                if let image = image,
                   let data = image.jpegData(compressionQuality: 0.8) {
                    imageData.append(data)
                    cameraViewModel.capturedImage = nil
                    
                    if imageData.count == 1 && name.isEmpty {
                        Task {
                            await analyzeImage(data)
                        }
                    }
                }
            }
            .disabled(isSaving)
        }
    }
    
    private var imageSection: some View {
        Section("Photos") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Add photo buttons
                    Menu {
                        Button("Camera", systemImage: "camera") {
                            showingCamera = true
                        }
                        Button("Photo Library", systemImage: "photo.stack") {
                            showingImagePicker = true
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 80)
                            .overlay {
                                VStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    Text("Add")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                    }
                    
                    // Image thumbnails
                    ForEach(Array(imageData.enumerated()), id: \.offset) { index, data in
                        if let uiImage = UIImage(data: data) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Button {
                                    imageData.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white, in: Circle())
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.horizontal, -16)
            
            if isAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing image with AI...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        Section("Basic Information") {
            TextField("Item name", text: $name)
            TextField("Description (optional)", text: $description)
            
            Picker("Category", selection: $selectedCategory) {
                ForEach(ClothingCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(category)
                }
            }
            
            Menu {
                ForEach(selectedCategory.subcategories, id: \.self) { sub in
                    Button(sub) { subcategory = sub }
                }
            } label: {
                HStack {
                    Text("Subcategory")
                    Spacer()
                    Text(subcategory.isEmpty ? "Select" : subcategory)
                        .foregroundColor(subcategory.isEmpty ? .secondary : .primary)
                }
            }
            
            TextField("Brand (optional)", text: $brand)
        }
    }
    
    private var colorAndPatternSection: some View {
        Section("Colors & Patterns") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Colors")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ClothingColor.commonColors, id: \.name) { color in
                            ColorSelectionChip(
                                color: color,
                                isSelected: selectedColors.contains { $0.name == color.name }
                            ) {
                                if let index = selectedColors.firstIndex(where: { $0.name == color.name }) {
                                    selectedColors.remove(at: index)
                                } else {
                                    selectedColors.append(color)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Patterns")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(ClothingPattern.allCases, id: \.self) { pattern in
                        PatternSelectionChip(
                            pattern: pattern,
                            isSelected: selectedPatterns.contains(pattern)
                        ) {
                            if selectedPatterns.contains(pattern) {
                                selectedPatterns.removeAll { $0 == pattern }
                            } else {
                                selectedPatterns.append(pattern)
                            }
                            
                            if selectedPatterns.isEmpty {
                                selectedPatterns = [.solid]
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var detailsSection: some View {
        Section("Details") {
            Picker("Formality", selection: $formality) {
                ForEach(FormalityLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Seasons")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    ForEach(Season.allCases, id: \.self) { season in
                        SeasonChip(
                            season: season,
                            isSelected: selectedSeasons.contains(season)
                        ) {
                            if selectedSeasons.contains(season) {
                                selectedSeasons.remove(season)
                            } else {
                                selectedSeasons.insert(season)
                            }
                        }
                    }
                    Spacer()
                }
            }
            
            Picker("Condition", selection: $condition) {
                ForEach(ItemCondition.allCases, id: \.self) { cond in
                    Text(cond.displayName).tag(cond)
                }
            }
            
            // Materials
            VStack(alignment: .leading, spacing: 8) {
                Text("Materials")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("Add material", text: $materialInput)
                    Button("Add") {
                        if !materialInput.isEmpty {
                            materials.append(materialInput)
                            materialInput = ""
                        }
                    }
                    .disabled(materialInput.isEmpty)
                }
                
                if !materials.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(materials.enumerated()), id: \.offset) { index, material in
                                TagChip(text: material) {
                                    materials.remove(at: index)
                                }
                            }
                        }
                    }
                }
            }
            
            // Occasions
            VStack(alignment: .leading, spacing: 8) {
                Text("Occasions")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("Add occasion", text: $occasionInput)
                    Button("Add") {
                        if !occasionInput.isEmpty {
                            occasions.append(occasionInput)
                            occasionInput = ""
                        }
                    }
                    .disabled(occasionInput.isEmpty)
                }
                
                if !occasions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(occasions.enumerated()), id: \.offset) { index, occasion in
                                TagChip(text: occasion) {
                                    occasions.remove(at: index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var priceSection: some View {
        Section("Purchase Information") {
            Toggle("Has purchase date", isOn: $hasPurchaseDate)
            
            if hasPurchaseDate {
                DatePicker("Purchase date", selection: $purchaseDate, displayedComponents: .date)
            }
            
            HStack {
                TextField("Price (optional)", value: $purchasePrice, format: .number)
                    .keyboardType(.decimalPad)
                
                Picker("Currency", selection: $currency) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("GBP").tag("GBP")
                    Text("CAD").tag("CAD")
                    Text("AUD").tag("AUD")
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    private var careSection: some View {
        Section("Care Instructions") {
            HStack {
                TextField("Add care instruction", text: $careInstruction)
                Button("Add") {
                    if !careInstruction.isEmpty {
                        careInstructions.append(careInstruction)
                        careInstruction = ""
                    }
                }
                .disabled(careInstruction.isEmpty)
            }
            
            if !careInstructions.isEmpty {
                ForEach(Array(careInstructions.enumerated()), id: \.offset) { index, instruction in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(instruction)
                            .font(.caption)
                        Spacer()
                        Button("Remove") {
                            careInstructions.remove(at: index)
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        Section("Notes") {
            TextField("Additional notes...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .disabled(isSaving)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await saveItem()
                    }
                }
                .disabled(name.isEmpty || isSaving)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                imageData.append(data)
                
                // Auto-analyze first image if name is empty
                if imageData.count == 1 && name.isEmpty {
                    await analyzeImage(data)
                }
            }
        }
        selectedImages.removeAll()
    }
    
    private func analyzeImage(_ data: Data) async {
        guard let image = UIImage(data: data) else { return }
        
        isAnalyzing = true
        
        do {
            let analysisService = AIClothingAnalysisService.shared
            let result = try await analysisService.analyzeClothing(image: image)
            
            await MainActor.run {
                // Update fields with AI analysis
                if name.isEmpty {
                    name = result.name
                }
                if description.isEmpty, let desc = result.description {
                    description = desc
                }
                selectedCategory = result.category
                if let sub = result.subcategory, subcategory.isEmpty {
                    subcategory = sub
                }
                selectedColors = result.colors
                selectedPatterns = result.patterns.isEmpty ? [.solid] : result.patterns
                materials = result.materials
                formality = result.formality
                selectedSeasons = Set(result.season)
                occasions = result.occasion
            }
        } catch {
            print("Failed to analyze image: \(error)")
        }
        
        isAnalyzing = false
    }
    
    private func saveItem() async {
        isSaving = true
        
        // Create wardrobe item
        let item = WardrobeItem(
            userId: UUID(), // This should come from auth service
            name: name,
            description: description.isEmpty ? nil : description,
            category: selectedCategory,
            subcategory: subcategory.isEmpty ? nil : subcategory,
            brand: brand.isEmpty ? nil : brand,
            colors: selectedColors,
            patterns: selectedPatterns,
            materials: materials,
            formality: formality,
            season: Array(selectedSeasons),
            occasion: occasions,
            purchaseDate: hasPurchaseDate ? purchaseDate : nil,
            purchasePrice: purchasePrice,
            currency: currency,
            condition: condition,
            careInstructions: careInstructions,
            notes: notes.isEmpty ? nil : notes
        )
        
        onSave(item)
        isSaving = false
        dismiss()
    }
}

// MARK: - Supporting Views

struct ColorSelectionChip: View {
    let color: ClothingColor
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: color.hexCode ?? "#808080") ?? .gray)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
                
                Text(color.name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

struct PatternSelectionChip: View {
    let pattern: ClothingPattern
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(pattern.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
                )
        }
    }
}

struct SeasonChip: View {
    let season: Season
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(season.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
                )
        }
    }
}

struct TagChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .foregroundColor(.primary)
        .cornerRadius(12)
    }
}

#Preview {
    AddWardrobeItemView { item in
        print("Saved item: \(item.name)")
    }
}