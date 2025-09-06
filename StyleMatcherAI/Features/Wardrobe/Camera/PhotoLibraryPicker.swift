import SwiftUI
import PhotosUI
import Photos

struct PhotoLibraryPicker: View {
    let onImageSelected: ([UIImage]) -> Void
    let maxSelectionCount: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var loadingProgress = 0.0
    @State private var showingPermissionAlert = false
    
    init(
        maxSelectionCount: Int = 1,
        onImageSelected: @escaping ([UIImage]) -> Void
    ) {
        self.maxSelectionCount = maxSelectionCount
        self.onImageSelected = onImageSelected
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    loadingView
                } else {
                    photoPickerView
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: selectedItems.isEmpty ? nil : Button("Done") {
                    processSelectedImages()
                }
            )
        }
        .onAppear {
            checkPhotoLibraryPermission()
        }
        .alert("Photo Access Required", isPresented: $showingPermissionAlert) {
            Button("Settings") { openSettings() }
            Button("Cancel", role: .cancel) { dismiss() }
        } message: {
            Text("Please allow access to your photo library to select images for your wardrobe.")
        }
    }
    
    private var photoPickerView: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxSelectionCount,
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Select Photos")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text(maxSelectionCount == 1 ? 
                         "Choose a photo from your library" : 
                         "Choose up to \(maxSelectionCount) photos from your library")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                if !selectedItems.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("\(selectedItems.count) photo\(selectedItems.count == 1 ? "" : "s") selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(40)
        }
        .onChange(of: selectedItems) { _ in
            if selectedItems.count == maxSelectionCount && maxSelectionCount == 1 {
                processSelectedImages()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: loadingProgress, total: 1.0)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("Processing Images...")
                    .font(.headline)
                
                Text("\(Int(loadingProgress * 100))% Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
    }
    
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus != .authorized && newStatus != .limited {
                        showingPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        case .authorized, .limited:
            break
        @unknown default:
            showingPermissionAlert = true
        }
    }
    
    private func processSelectedImages() {
        guard !selectedItems.isEmpty else { return }
        
        isLoading = true
        loadingProgress = 0.0
        
        Task {
            var images: [UIImage] = []
            let totalItems = Double(selectedItems.count)
            
            for (index, item) in selectedItems.enumerated() {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
                
                await MainActor.run {
                    loadingProgress = Double(index + 1) / totalItems
                }
            }
            
            await MainActor.run {
                isLoading = false
                onImageSelected(images)
                dismiss()
            }
        }
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
}

// MARK: - Enhanced Photo Picker with Grid View

struct EnhancedPhotoLibraryPicker: View {
    let onImagesSelected: ([UIImage]) -> Void
    let maxSelectionCount: Int
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PhotoLibraryPickerViewModel()
    
    init(
        maxSelectionCount: Int = 10,
        onImagesSelected: @escaping ([UIImage]) -> Void
    ) {
        self.maxSelectionCount = maxSelectionCount
        self.onImagesSelected = onImagesSelected
    }
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.authorizationStatus {
                case .authorized, .limited:
                    photoGridView
                case .denied, .restricted:
                    permissionDeniedView
                case .notDetermined:
                    loadingView
                @unknown default:
                    permissionDeniedView
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.selectedImages.isEmpty {
                        Button("Done") {
                            onImagesSelected(viewModel.selectedImages.map { $0.image })
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.requestPermission()
        }
    }
    
    private var photoGridView: some View {
        VStack {
            if !viewModel.selectedImages.isEmpty {
                selectionSummary
            }
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                    ForEach(viewModel.photos, id: \.localIdentifier) { asset in
                        PhotoThumbnailView(
                            asset: asset,
                            isSelected: viewModel.isSelected(asset),
                            selectionIndex: viewModel.selectionIndex(for: asset)
                        ) {
                            viewModel.toggleSelection(for: asset, maxCount: maxSelectionCount)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .onAppear {
            viewModel.loadPhotos()
        }
    }
    
    private var selectionSummary: some View {
        HStack {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("\(viewModel.selectedImages.count) of \(maxSelectionCount) selected")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            if viewModel.selectedImages.count == maxSelectionCount {
                Text("Maximum reached")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
    }
    
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Photo Access Required")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Please allow access to your photo library to select images for your wardrobe.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Open Settings") {
                openSettings()
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding(40)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Photos...")
                .font(.headline)
        }
        .padding(40)
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
}

struct PhotoThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool
    let selectionIndex: Int?
    let onTap: () -> Void
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(UIColor.systemGray5))
                .aspectRatio(1, contentMode: .fit)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            VStack {
                HStack {
                    Spacer()
                    selectionIndicator
                }
                Spacer()
            }
            .padding(8)
            
            if isSelected {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
            }
        }
        .onTapGesture {
            onTap()
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private var selectionIndicator: some View {
        Group {
            if isSelected, let index = selectionIndex {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 24, height: 24)
                    
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            } else {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .background(Circle().fill(Color.black.opacity(0.3)))
                    .frame(width: 24, height: 24)
            }
        }
    }
    
    private func loadThumbnail() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        
        let targetSize = CGSize(width: 200, height: 200)
        
        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            DispatchQueue.main.async {
                self.image = result
                self.isLoading = false
            }
        }
    }
}

@MainActor
final class PhotoLibraryPickerViewModel: ObservableObject {
    @Published var photos: [PHAsset] = []
    @Published var selectedImages: [(asset: PHAsset, image: UIImage)] = []
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    private let imageManager = PHImageManager.default()
    
    func requestPermission() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if authorizationStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                }
            }
        }
    }
    
    func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var assets: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        self.photos = assets
    }
    
    func toggleSelection(for asset: PHAsset, maxCount: Int) {
        if let existingIndex = selectedImages.firstIndex(where: { $0.asset == asset }) {
            selectedImages.remove(at: existingIndex)
        } else if selectedImages.count < maxCount {
            loadFullSizeImage(for: asset) { [weak self] image in
                if let image = image {
                    self?.selectedImages.append((asset: asset, image: image))
                }
            }
        }
    }
    
    func isSelected(_ asset: PHAsset) -> Bool {
        return selectedImages.contains { $0.asset == asset }
    }
    
    func selectionIndex(for asset: PHAsset) -> Int? {
        return selectedImages.firstIndex { $0.asset == asset }
    }
    
    private func loadFullSizeImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}

#Preview {
    PhotoLibraryPicker(maxSelectionCount: 1) { images in
        print("Selected \(images.count) images")
    }
}