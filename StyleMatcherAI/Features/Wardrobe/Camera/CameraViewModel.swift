import AVFoundation
import SwiftUI
import Combine
import Photos

@MainActor
final class CameraViewModel: NSObject, ObservableObject {
    @Published var captureSession = AVCaptureSession()
    @Published var isSessionRunning = false
    @Published var isCameraUnavailable = false
    @Published var isFlashOn = false
    @Published var capturedImage: UIImage?
    @Published var isPhotoLibraryPresented = false
    @Published var isShowingPermissionAlert = false
    @Published var permissionAlertMessage = ""
    @Published var isProcessingCapture = false
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupCaptureSession()
        checkPermissions()
    }
    
    deinit {
        stopSession()
    }
    
    func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            self?.configureCaptureSession()
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let photoSettings = AVCapturePhotoSettings()
        
        if videoDeviceInput?.device.isFlashAvailable == true {
            photoSettings.flashMode = isFlashOn ? .on : .off
        }
        
        if let availableFormats = photoOutput.availablePhotoCodecTypes.first {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: availableFormats])
        }
        
        photoSettings.isHighResolutionPhotoEnabled = true
        
        if let connection = photoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = currentVideoOrientation()
            }
        }
        
        isProcessingCapture = true
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let newPosition: AVCaptureDevice.Position = self.currentCameraPosition == .back ? .front : .back
            
            guard let newDevice = self.getCameraDevice(for: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
                return
            }
            
            self.captureSession.beginConfiguration()
            
            if let currentInput = self.videoDeviceInput {
                self.captureSession.removeInput(currentInput)
            }
            
            if self.captureSession.canAddInput(newInput) {
                self.captureSession.addInput(newInput)
                self.videoDeviceInput = newInput
                self.currentCameraPosition = newPosition
            } else if let currentInput = self.videoDeviceInput {
                self.captureSession.addInput(currentInput)
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    func toggleFlash() {
        guard let device = videoDeviceInput?.device,
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isTorchAvailable {
                isFlashOn.toggle()
                device.torchMode = isFlashOn ? .on : .off
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Failed to toggle flash: \(error)")
        }
    }
    
    func focusAndExposeTap(at point: CGPoint) {
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Failed to focus and expose: \(error)")
        }
    }
    
    func openPhotoLibrary() {
        isPhotoLibraryPresented = true
    }
    
    private func configureCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        setupVideoInput()
        setupPhotoOutput()
        
        captureSession.commitConfiguration()
    }
    
    private func setupVideoInput() {
        guard let camera = getCameraDevice(for: currentCameraPosition),
              let videoInput = try? AVCaptureDeviceInput(device: camera) else {
            DispatchQueue.main.async {
                self.isCameraUnavailable = true
            }
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            videoDeviceInput = videoInput
        } else {
            DispatchQueue.main.async {
                self.isCameraUnavailable = true
            }
        }
    }
    
    private func setupPhotoOutput() {
        let photoOutput = AVCapturePhotoOutput()
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            self.photoOutput = photoOutput
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
        }
    }
    
    private func getCameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: position
        )
        
        return discoverySession.devices.first
    }
    
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        let orientation = UIDevice.current.orientation
        
        switch orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            requestCameraPermission()
        case .denied, .restricted:
            showPermissionAlert(
                message: "Camera access is required to take photos of your wardrobe items. Please enable camera access in Settings."
            )
        @unknown default:
            break
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.startSession()
                } else {
                    self?.showPermissionAlert(
                        message: "Camera access is required to take photos of your wardrobe items. Please enable camera access in Settings."
                    )
                }
            }
        }
    }
    
    private func showPermissionAlert(message: String) {
        permissionAlertMessage = message
        isShowingPermissionAlert = true
    }
    
    func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        case .denied, .restricted:
            showPermissionAlert(
                message: "Photo library access is required to select photos. Please enable photo library access in Settings."
            )
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func saveToPhotoLibrary(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        checkPhotoLibraryPermission { [weak self] granted in
            guard granted else {
                completion(false, CameraError.photoLibraryAccessDenied)
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer {
            isProcessingCapture = false
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to process captured photo: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        let processedImage = correctImageOrientation(image)
        capturedImage = processedImage
    }
    
    private func correctImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}

// MARK: - Error Types
enum CameraError: LocalizedError {
    case cameraUnavailable
    case photoLibraryAccessDenied
    case captureSessionConfigurationFailed
    case photoCaptureFailed
    
    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is not available on this device"
        case .photoLibraryAccessDenied:
            return "Photo library access is required"
        case .captureSessionConfigurationFailed:
            return "Failed to configure camera session"
        case .photoCaptureFailed:
            return "Failed to capture photo"
        }
    }
}

// MARK: - Extensions
extension CameraViewModel {
    var isBackCameraActive: Bool {
        return currentCameraPosition == .back
    }
    
    var isFrontCameraActive: Bool {
        return currentCameraPosition == .front
    }
    
    var canSwitchCamera: Bool {
        return getCameraDevice(for: .front) != nil && getCameraDevice(for: .back) != nil
    }
    
    var canToggleFlash: Bool {
        return videoDeviceInput?.device.hasTorch == true
    }
}