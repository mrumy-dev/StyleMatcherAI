import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onImageCaptured: (UIImage) -> Void
    
    @State private var showingImagePicker = false
    @State private var isShowingCapturedImage = false
    @State private var flashAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if viewModel.isCameraUnavailable {
                    cameraUnavailableView
                } else {
                    cameraPreviewView
                        .onAppear {
                            viewModel.startSession()
                        }
                        .onDisappear {
                            viewModel.stopSession()
                        }
                }
                
                VStack {
                    headerView
                    Spacer()
                    controlsView
                }
                .padding()
                
                if viewModel.isProcessingCapture {
                    processingOverlay
                }
                
                if flashAnimation {
                    flashOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
        .alert("Permission Required", isPresented: $viewModel.isShowingPermissionAlert) {
            Button("Settings") {
                openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(viewModel.permissionAlertMessage)
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoPicker { image in
                onImageCaptured(image)
                dismiss()
            }
        }
        .fullScreenCover(isPresented: $isShowingCapturedImage) {
            if let capturedImage = viewModel.capturedImage {
                CapturedImageView(
                    image: capturedImage,
                    onRetake: {
                        isShowingCapturedImage = false
                        viewModel.capturedImage = nil
                    },
                    onUse: { image in
                        onImageCaptured(image)
                        dismiss()
                    }
                )
            }
        }
        .onChange(of: viewModel.capturedImage) { image in
            if image != nil {
                isShowingCapturedImage = true
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            if viewModel.canToggleFlash {
                Button(action: { 
                    viewModel.toggleFlash()
                    withAnimation(.easeInOut(duration: 0.1)) {
                        flashAnimation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        flashAnimation = false
                    }
                }) {
                    Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                        .font(.title2)
                        .foregroundColor(viewModel.isFlashOn ? .yellow : .white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private var cameraPreviewView: some View {
        CameraPreview(session: viewModel.captureSession)
            .onTapGesture { location in
                let normalizedPoint = CGPoint(
                    x: location.x / UIScreen.main.bounds.width,
                    y: location.y / UIScreen.main.bounds.height
                )
                viewModel.focusAndExposeTap(at: normalizedPoint)
            }
            .clipped()
    }
    
    private var cameraUnavailableView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Camera Unavailable")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("The camera is not available on this device or access has been denied.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Open Photo Library") {
                showingImagePicker = true
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
    
    private var controlsView: some View {
        HStack(spacing: 40) {
            Button(action: { showingImagePicker = true }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.1)) {
                    flashAnimation = true
                }
                viewModel.capturePhoto()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    flashAnimation = false
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 70, height: 70)
                }
            }
            .disabled(viewModel.isProcessingCapture)
            .scaleEffect(viewModel.isProcessingCapture ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isProcessingCapture)
            
            if viewModel.canSwitchCamera {
                Button(action: { viewModel.switchCamera() }) {
                    Image(systemName: "camera.rotate")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            } else {
                Spacer()
                    .frame(width: 60, height: 60)
            }
        }
    }
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text("Processing...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }
    
    private var flashOverlay: some View {
        Color.white
            .ignoresSafeArea()
            .opacity(0.8)
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = UIColor.black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

final class VideoPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

struct CapturedImageView: View {
    let image: UIImage
    let onRetake: () -> Void
    let onUse: (UIImage) -> Void
    
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                
                Spacer()
                
                HStack(spacing: 40) {
                    Button("Retake") {
                        onRetake()
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(25)
                    
                    Button("Use Photo") {
                        isProcessing = true
                        onUse(image)
                    }
                    .foregroundColor(.black)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.white)
                    .cornerRadius(25)
                    .disabled(isProcessing)
                    .opacity(isProcessing ? 0.7 : 1.0)
                }
                .padding(.bottom, 50)
            }
            
            if isProcessing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    
                    Text("Processing image...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self.parent.onImageSelected(image)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CameraView { image in
        print("Image captured: \(image)")
    }
}