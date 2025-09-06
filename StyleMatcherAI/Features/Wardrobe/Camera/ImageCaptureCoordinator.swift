import SwiftUI
import UIKit

struct ImageCaptureCoordinator: View {
    let onImagesSelected: ([UIImage]) -> Void
    let maxSelectionCount: Int
    let allowsCamera: Bool
    let allowsPhotoLibrary: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingActionSheet = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingEnhancedPicker = false
    
    init(
        maxSelectionCount: Int = 1,
        allowsCamera: Bool = true,
        allowsPhotoLibrary: Bool = true,
        onImagesSelected: @escaping ([UIImage]) -> Void
    ) {
        self.maxSelectionCount = maxSelectionCount
        self.allowsCamera = allowsCamera
        self.allowsPhotoLibrary = allowsPhotoLibrary
        self.onImagesSelected = onImagesSelected
    }
    
    var body: some View {
        VStack {
            // This view is typically presented modally
        }
        .onAppear {
            if allowsCamera && allowsPhotoLibrary {
                showingActionSheet = true
            } else if allowsCamera {
                showingCamera = true
            } else if allowsPhotoLibrary {
                if maxSelectionCount == 1 {
                    showingPhotoLibrary = true
                } else {
                    showingEnhancedPicker = true
                }
            } else {
                dismiss()
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Select Image Source"),
                message: Text("Choose how you'd like to add images to your wardrobe."),
                buttons: [
                    .default(Text("Take Photo")) {
                        showingCamera = true
                    },
                    .default(Text(maxSelectionCount == 1 ? "Choose from Library" : "Choose Multiple")) {
                        if maxSelectionCount == 1 {
                            showingPhotoLibrary = true
                        } else {
                            showingEnhancedPicker = true
                        }
                    },
                    .cancel {
                        dismiss()
                    }
                ]
            )
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                onImagesSelected([image])
                dismiss()
            }
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoLibraryPicker(maxSelectionCount: 1) { images in
                onImagesSelected(images)
                dismiss()
            }
        }
        .sheet(isPresented: $showingEnhancedPicker) {
            EnhancedPhotoLibraryPicker(maxSelectionCount: maxSelectionCount) { images in
                onImagesSelected(images)
                dismiss()
            }
        }
    }
}

// MARK: - Wardrobe Item Image Capture Flow

struct WardrobeItemImageCaptureFlow: View {
    @State private var capturedImages: [UIImage] = []
    @State private var isUploading = false
    @State private var uploadProgress = 0.0
    @State private var showingImageCapture = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let wardrobeItem: WardrobeItem
    let onImagesUploaded: ([WardrobeImageUploadResult]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    private let imageUploadService = ImageUploadService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            if capturedImages.isEmpty {
                emptyStateView
            } else {
                capturedImagesView
            }
            
            if isUploading {
                uploadingView
            } else {
                actionButtons
            }
        }
        .padding()
        .navigationTitle("Add Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !capturedImages.isEmpty && !isUploading {
                    Button("Save") {
                        uploadImages()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImageCapture) {
            ImageCaptureCoordinator(
                maxSelectionCount: 5,
                allowsCamera: true,
                allowsPhotoLibrary: true
            ) { images in
                capturedImages.append(contentsOf: images)
            }
        }
        .alert("Upload Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Add Photos")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Take photos or select from your library to add to this wardrobe item.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private var capturedImagesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Photos (\(capturedImages.count)/5)")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Button(action: {
                                capturedImages.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Circle().fill(.white))
                            }
                            .offset(x: 8, y: -8)
                        }
                    }
                    
                    if capturedImages.count < 5 {
                        Button(action: {
                            showingImageCapture = true
                        }) {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    VStack {
                                        Image(systemName: "plus")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                        
                                        Text("Add More")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var uploadingView: some View {
        VStack(spacing: 16) {
            ProgressView(value: uploadProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("Uploading photos...")
                .font(.headline)
            
            Text("\(Int(uploadProgress * 100))% complete")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingImageCapture = true
            }) {
                HStack {
                    Image(systemName: "camera.badge.plus")
                    Text(capturedImages.isEmpty ? "Add Photos" : "Add More Photos")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            if !capturedImages.isEmpty {
                Button("Clear All") {
                    capturedImages.removeAll()
                }
                .foregroundColor(.red)
            }
        }
    }
    
    private func uploadImages() {
        guard !capturedImages.isEmpty else { return }
        
        isUploading = true
        uploadProgress = 0.0
        
        Task {
            do {
                let results = try await imageUploadService.uploadMultipleWardrobeImages(
                    capturedImages,
                    userId: wardrobeItem.userId,
                    itemId: wardrobeItem.id
                ) { progress in
                    await MainActor.run {
                        uploadProgress = progress
                    }
                }
                
                await MainActor.run {
                    isUploading = false
                    onImagesUploaded(results)
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isUploading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Quick Image Capture Button

struct QuickImageCaptureButton: View {
    let onImageCaptured: (UIImage) -> Void
    
    @State private var showingImageCapture = false
    
    var body: some View {
        Button(action: {
            showingImageCapture = true
        }) {
            Image(systemName: "camera.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.blue)
                .clipShape(Circle())
        }
        .sheet(isPresented: $showingImageCapture) {
            ImageCaptureCoordinator(
                maxSelectionCount: 1,
                allowsCamera: true,
                allowsPhotoLibrary: true
            ) { images in
                if let image = images.first {
                    onImageCaptured(image)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ImageCaptureCoordinator(maxSelectionCount: 3) { images in
            print("Selected \(images.count) images")
        }
    }
}