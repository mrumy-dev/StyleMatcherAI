import UIKit
import CoreGraphics
import ImageIO
import MobileCoreServices
import AVFoundation

final class ImageProcessor {
    static let shared = ImageProcessor()
    
    private init() {}
    
    // MARK: - Image Compression
    
    func compressImage(
        _ image: UIImage,
        maxSizeKB: Int = 500,
        maxDimension: CGFloat = 1024
    ) -> UIImage? {
        guard let resizedImage = resizeImage(image, maxDimension: maxDimension) else {
            return nil
        }
        
        return compressToTargetSize(resizedImage, targetSizeKB: maxSizeKB)
    }
    
    func compressImageData(
        _ image: UIImage,
        maxSizeKB: Int = 500,
        quality: CGFloat = 0.8
    ) -> Data? {
        guard let compressedImage = compressImage(image, maxSizeKB: maxSizeKB) else {
            return nil
        }
        
        return compressedImage.jpegData(compressionQuality: quality)
    }
    
    private func compressToTargetSize(_ image: UIImage, targetSizeKB: Int) -> UIImage? {
        let targetSizeBytes = targetSizeKB * 1024
        var compressionQuality: CGFloat = 1.0
        let decrementValue: CGFloat = 0.1
        
        guard var imageData = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        while imageData.count > targetSizeBytes && compressionQuality > 0.1 {
            compressionQuality -= decrementValue
            guard let compressedData = image.jpegData(compressionQuality: compressionQuality) else {
                break
            }
            imageData = compressedData
        }
        
        return UIImage(data: imageData)
    }
    
    // MARK: - Image Resizing
    
    func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        if newSize.width >= size.width && newSize.height >= size.height {
            return image
        }
        
        return resizeImage(image, to: newSize)
    }
    
    func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // MARK: - Thumbnail Generation
    
    func generateThumbnail(
        from image: UIImage,
        size: CGSize = CGSize(width: 150, height: 150),
        contentMode: ContentMode = .aspectFill
    ) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { _ in
            let imageRect: CGRect
            
            switch contentMode {
            case .aspectFill:
                imageRect = aspectFillRect(for: image.size, in: CGRect(origin: .zero, size: size))
            case .aspectFit:
                imageRect = aspectFitRect(for: image.size, in: CGRect(origin: .zero, size: size))
            case .fill:
                imageRect = CGRect(origin: .zero, size: size)
            }
            
            image.draw(in: imageRect)
        }
    }
    
    func generateThumbnails(
        from image: UIImage,
        sizes: [CGSize] = [
            CGSize(width: 150, height: 150),
            CGSize(width: 300, height: 300),
            CGSize(width: 600, height: 600)
        ]
    ) -> [String: UIImage] {
        var thumbnails: [String: UIImage] = [:]
        
        for size in sizes {
            let key = "\(Int(size.width))x\(Int(size.height))"
            if let thumbnail = generateThumbnail(from: image, size: size) {
                thumbnails[key] = thumbnail
            }
        }
        
        return thumbnails
    }
    
    // MARK: - Image Optimization
    
    func optimizeForUpload(_ image: UIImage) -> ImageUploadData? {
        guard let originalData = compressImageData(image, maxSizeKB: 2048, quality: 0.9) else {
            return nil
        }
        
        guard let thumbnailImage = generateThumbnail(from: image, size: CGSize(width: 300, height: 300)),
              let thumbnailData = compressImageData(thumbnailImage, maxSizeKB: 100, quality: 0.8) else {
            return nil
        }
        
        return ImageUploadData(
            originalData: originalData,
            thumbnailData: thumbnailData,
            dimensions: image.size,
            fileSize: originalData.count
        )
    }
    
    // MARK: - Image Correction
    
    func correctImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(at: .zero)
        }
    }
    
    func cropToSquare(_ image: UIImage) -> UIImage? {
        let size = image.size
        let minDimension = min(size.width, size.height)
        
        let cropRect = CGRect(
            x: (size.width - minDimension) / 2,
            y: (size.height - minDimension) / 2,
            width: minDimension,
            height: minDimension
        )
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // MARK: - Background Removal (Placeholder)
    
    func removeBackground(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let processedImage = self.performBackgroundRemoval(image)
            
            DispatchQueue.main.async {
                completion(processedImage)
            }
        }
    }
    
    private func performBackgroundRemoval(_ image: UIImage) -> UIImage? {
        return image
    }
    
    // MARK: - Utility Functions
    
    private func aspectFillRect(for imageSize: CGSize, in containerRect: CGRect) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerRect.width / containerRect.height
        
        var drawRect = containerRect
        
        if imageAspect > containerAspect {
            let newHeight = containerRect.width / imageAspect
            drawRect.origin.y = (containerRect.height - newHeight) / 2
            drawRect.size.height = newHeight
        } else {
            let newWidth = containerRect.height * imageAspect
            drawRect.origin.x = (containerRect.width - newWidth) / 2
            drawRect.size.width = newWidth
        }
        
        return drawRect
    }
    
    private func aspectFitRect(for imageSize: CGSize, in containerRect: CGRect) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerRect.width / containerRect.height
        
        var drawRect = containerRect
        
        if imageAspect > containerAspect {
            let newHeight = containerRect.width / imageAspect
            drawRect.origin.y = (containerRect.height - newHeight) / 2
            drawRect.size.height = newHeight
        } else {
            let newWidth = containerRect.height * imageAspect
            drawRect.origin.x = (containerRect.width - newWidth) / 2
            drawRect.size.width = newWidth
        }
        
        return drawRect
    }
    
    func calculateImageFileSize(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> Int {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            return 0
        }
        return data.count
    }
    
    func getImageMetadata(_ image: UIImage) -> ImageMetadata {
        let size = image.size
        let scale = image.scale
        let orientation = image.imageOrientation
        
        return ImageMetadata(
            width: Int(size.width * scale),
            height: Int(size.height * scale),
            scale: scale,
            orientation: orientation,
            hasAlpha: image.cgImage?.alphaInfo != .none
        )
    }
}

// MARK: - Supporting Types

enum ContentMode {
    case aspectFill
    case aspectFit
    case fill
}

struct ImageUploadData {
    let originalData: Data
    let thumbnailData: Data
    let dimensions: CGSize
    let fileSize: Int
    
    var fileSizeKB: Double {
        return Double(fileSize) / 1024.0
    }
    
    var fileSizeMB: Double {
        return fileSizeKB / 1024.0
    }
}

struct ImageMetadata {
    let width: Int
    let height: Int
    let scale: CGFloat
    let orientation: UIImage.Orientation
    let hasAlpha: Bool
    
    var aspectRatio: Double {
        return Double(width) / Double(height)
    }
    
    var megapixels: Double {
        return Double(width * height) / 1_000_000.0
    }
}

// MARK: - Extensions

extension UIImage {
    func compressed(maxSizeKB: Int = 500) -> UIImage? {
        return ImageProcessor.shared.compressImage(self, maxSizeKB: maxSizeKB)
    }
    
    func resized(maxDimension: CGFloat) -> UIImage? {
        return ImageProcessor.shared.resizeImage(self, maxDimension: maxDimension)
    }
    
    func thumbnail(size: CGSize = CGSize(width: 150, height: 150)) -> UIImage? {
        return ImageProcessor.shared.generateThumbnail(from: self, size: size)
    }
    
    func correctedOrientation() -> UIImage {
        return ImageProcessor.shared.correctImageOrientation(self)
    }
    
    func cropped() -> UIImage? {
        return ImageProcessor.shared.cropToSquare(self)
    }
    
    var fileSize: Int {
        return ImageProcessor.shared.calculateImageFileSize(self)
    }
    
    var metadata: ImageMetadata {
        return ImageProcessor.shared.getImageMetadata(self)
    }
}

// MARK: - Wardrobe Specific Processing

extension ImageProcessor {
    func processWardrobeImage(_ image: UIImage) -> ProcessedWardrobeImage? {
        guard let correctedImage = correctImageOrientation(image).correctedOrientation() as UIImage? else {
            return nil
        }
        
        guard let uploadData = optimizeForUpload(correctedImage) else {
            return nil
        }
        
        let thumbnails = generateThumbnails(from: correctedImage)
        
        return ProcessedWardrobeImage(
            originalImage: correctedImage,
            uploadData: uploadData,
            thumbnails: thumbnails,
            metadata: getImageMetadata(correctedImage)
        )
    }
}

struct ProcessedWardrobeImage {
    let originalImage: UIImage
    let uploadData: ImageUploadData
    let thumbnails: [String: UIImage]
    let metadata: ImageMetadata
    
    var smallThumbnail: UIImage? {
        return thumbnails["150x150"]
    }
    
    var mediumThumbnail: UIImage? {
        return thumbnails["300x300"]
    }
    
    var largeThumbnail: UIImage? {
        return thumbnails["600x600"]
    }
}