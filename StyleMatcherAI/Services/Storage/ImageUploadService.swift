import Foundation
import Supabase
import UIKit

final class ImageUploadService {
    static let shared = ImageUploadService()
    
    private let supabase = SupabaseClient.shared
    private let imageProcessor = ImageProcessor.shared
    
    private init() {}
    
    // MARK: - Upload Methods
    
    func uploadWardrobeImage(
        _ image: UIImage,
        userId: UUID,
        itemId: UUID? = nil,
        progress: ((Double) -> Void)? = nil
    ) async throws -> WardrobeImageUploadResult {
        
        guard let processedImage = imageProcessor.processWardrobeImage(image) else {
            throw ImageUploadError.processingFailed
        }
        
        let fileName = itemId?.uuidString ?? UUID().uuidString
        let bucket = StorageBucket.wardrobeImages.rawValue
        
        let originalPath = "users/\(userId)/wardrobe/\(fileName)/original.jpg"
        let thumbnailPath = "users/\(userId)/wardrobe/\(fileName)/thumbnail.jpg"
        
        async let originalUpload = uploadImageData(
            processedImage.uploadData.originalData,
            to: originalPath,
            bucket: bucket,
            progress: { progressValue in
                progress?(progressValue * 0.7)
            }
        )
        
        async let thumbnailUpload = uploadImageData(
            processedImage.uploadData.thumbnailData,
            to: thumbnailPath,
            bucket: bucket,
            progress: { progressValue in
                progress?(0.7 + (progressValue * 0.3))
            }
        )
        
        let (originalURL, thumbnailURL) = try await (originalUpload, thumbnailUpload)
        
        return WardrobeImageUploadResult(
            originalURL: originalURL,
            thumbnailURL: thumbnailURL,
            fileName: fileName,
            fileSize: processedImage.uploadData.fileSize,
            dimensions: processedImage.uploadData.dimensions,
            metadata: processedImage.metadata
        )
    }
    
    func uploadOutfitImage(
        _ image: UIImage,
        userId: UUID,
        outfitId: UUID,
        progress: ((Double) -> Void)? = nil
    ) async throws -> OutfitImageUploadResult {
        
        guard let processedImage = imageProcessor.processWardrobeImage(image) else {
            throw ImageUploadError.processingFailed
        }
        
        let fileName = outfitId.uuidString
        let bucket = StorageBucket.outfitImages.rawValue
        
        let originalPath = "users/\(userId)/outfits/\(fileName)/original.jpg"
        let thumbnailPath = "users/\(userId)/outfits/\(fileName)/thumbnail.jpg"
        
        async let originalUpload = uploadImageData(
            processedImage.uploadData.originalData,
            to: originalPath,
            bucket: bucket,
            progress: { progressValue in
                progress?(progressValue * 0.7)
            }
        )
        
        async let thumbnailUpload = uploadImageData(
            processedImage.uploadData.thumbnailData,
            to: thumbnailPath,
            bucket: bucket,
            progress: { progressValue in
                progress?(0.7 + (progressValue * 0.3))
            }
        )
        
        let (originalURL, thumbnailURL) = try await (originalUpload, thumbnailUpload)
        
        return OutfitImageUploadResult(
            originalURL: originalURL,
            thumbnailURL: thumbnailURL,
            fileName: fileName,
            fileSize: processedImage.uploadData.fileSize,
            dimensions: processedImage.uploadData.dimensions
        )
    }
    
    func uploadProfileImage(
        _ image: UIImage,
        userId: UUID,
        progress: ((Double) -> Void)? = nil
    ) async throws -> ProfileImageUploadResult {
        
        guard let squareImage = imageProcessor.cropToSquare(image) else {
            throw ImageUploadError.processingFailed
        }
        
        guard let processedImage = imageProcessor.processWardrobeImage(squareImage) else {
            throw ImageUploadError.processingFailed
        }
        
        let fileName = "profile_\(userId.uuidString)"
        let bucket = StorageBucket.profileImages.rawValue
        let imagePath = "users/\(userId)/profile/\(fileName).jpg"
        
        let imageURL = try await uploadImageData(
            processedImage.uploadData.originalData,
            to: imagePath,
            bucket: bucket,
            progress: progress
        )
        
        return ProfileImageUploadResult(
            imageURL: imageURL,
            fileName: fileName,
            fileSize: processedImage.uploadData.fileSize
        )
    }
    
    // MARK: - Batch Upload
    
    func uploadMultipleWardrobeImages(
        _ images: [UIImage],
        userId: UUID,
        itemId: UUID,
        overallProgress: ((Double) -> Void)? = nil
    ) async throws -> [WardrobeImageUploadResult] {
        
        var results: [WardrobeImageUploadResult] = []
        let totalImages = images.count
        
        for (index, image) in images.enumerated() {
            let result = try await uploadWardrobeImage(
                image,
                userId: userId,
                itemId: itemId
            ) { progress in
                let imageProgress = (Double(index) + progress) / Double(totalImages)
                overallProgress?(imageProgress)
            }
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Delete Methods
    
    func deleteWardrobeImage(userId: UUID, fileName: String) async throws {
        let bucket = StorageBucket.wardrobeImages.rawValue
        
        let originalPath = "users/\(userId)/wardrobe/\(fileName)/original.jpg"
        let thumbnailPath = "users/\(userId)/wardrobe/\(fileName)/thumbnail.jpg"
        
        async let originalDelete = deleteFile(at: originalPath, bucket: bucket)
        async let thumbnailDelete = deleteFile(at: thumbnailPath, bucket: bucket)
        
        try await (originalDelete, thumbnailDelete)
    }
    
    func deleteOutfitImage(userId: UUID, fileName: String) async throws {
        let bucket = StorageBucket.outfitImages.rawValue
        
        let originalPath = "users/\(userId)/outfits/\(fileName)/original.jpg"
        let thumbnailPath = "users/\(userId)/outfits/\(fileName)/thumbnail.jpg"
        
        async let originalDelete = deleteFile(at: originalPath, bucket: bucket)
        async let thumbnailDelete = deleteFile(at: thumbnailPath, bucket: bucket)
        
        try await (originalDelete, thumbnailDelete)
    }
    
    func deleteProfileImage(userId: UUID, fileName: String) async throws {
        let bucket = StorageBucket.profileImages.rawValue
        let imagePath = "users/\(userId)/profile/\(fileName).jpg"
        
        try await deleteFile(at: imagePath, bucket: bucket)
    }
    
    // MARK: - Download Methods
    
    func downloadImage(from url: String) async throws -> UIImage {
        guard let imageURL = URL(string: url) else {
            throw ImageUploadError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: imageURL)
        
        guard let image = UIImage(data: data) else {
            throw ImageUploadError.invalidImageData
        }
        
        return image
    }
    
    func getSignedURL(for path: String, bucket: String, expiresIn: Int = 3600) async throws -> URL {
        let response = try await supabase.storage
            .from(bucket)
            .createSignedURL(path: path, expiresIn: expiresIn)
        
        guard let url = URL(string: response.signedURL) else {
            throw ImageUploadError.invalidURL
        }
        
        return url
    }
    
    // MARK: - Storage Management
    
    func getStorageUsage(for userId: UUID) async throws -> StorageUsage {
        let buckets = StorageBucket.allCases
        var totalSize: Int64 = 0
        var fileCount = 0
        var usageByBucket: [String: StorageUsage.BucketUsage] = [:]
        
        for bucket in buckets {
            let usage = try await getBucketUsage(userId: userId, bucket: bucket.rawValue)
            usageByBucket[bucket.rawValue] = usage
            totalSize += usage.totalSize
            fileCount += usage.fileCount
        }
        
        return StorageUsage(
            totalSize: totalSize,
            fileCount: fileCount,
            usageByBucket: usageByBucket
        )
    }
    
    func cleanupOldImages(for userId: UUID, olderThan date: Date) async throws -> CleanupResult {
        var deletedFiles = 0
        var freedBytes: Int64 = 0
        
        for bucket in StorageBucket.allCases {
            let files = try await listFiles(userId: userId, bucket: bucket.rawValue)
            
            for file in files {
                if file.createdAt < date {
                    let fileSize = file.metadata?.size ?? 0
                    try await deleteFile(at: file.name, bucket: bucket.rawValue)
                    deletedFiles += 1
                    freedBytes += Int64(fileSize)
                }
            }
        }
        
        return CleanupResult(
            deletedFiles: deletedFiles,
            freedBytes: freedBytes
        )
    }
    
    // MARK: - Private Methods
    
    private func uploadImageData(
        _ data: Data,
        to path: String,
        bucket: String,
        progress: ((Double) -> Void)? = nil
    ) async throws -> String {
        
        let file = File(
            name: path,
            data: data,
            fileName: path.components(separatedBy: "/").last ?? "image.jpg",
            contentType: "image/jpeg"
        )
        
        try await supabase.storage
            .from(bucket)
            .upload(path: path, file: file, options: FileOptions(upsert: true))
        
        let publicURL = try supabase.storage
            .from(bucket)
            .getPublicURL(path: path)
        
        return publicURL.absoluteString
    }
    
    private func deleteFile(at path: String, bucket: String) async throws {
        try await supabase.storage
            .from(bucket)
            .remove(paths: [path])
    }
    
    private func listFiles(userId: UUID, bucket: String) async throws -> [FileObject] {
        let userPath = "users/\(userId)/"
        
        let response = try await supabase.storage
            .from(bucket)
            .list(path: userPath)
        
        return response
    }
    
    private func getBucketUsage(userId: UUID, bucket: String) async throws -> StorageUsage.BucketUsage {
        let files = try await listFiles(userId: userId, bucket: bucket)
        
        let totalSize = files.reduce(0) { sum, file in
            return sum + Int64(file.metadata?.size ?? 0)
        }
        
        return StorageUsage.BucketUsage(
            totalSize: totalSize,
            fileCount: files.count
        )
    }
}

// MARK: - Supporting Types

enum StorageBucket: String, CaseIterable {
    case wardrobeImages = "wardrobe-images"
    case outfitImages = "outfit-images"
    case profileImages = "profile-images"
}

enum ImageUploadError: LocalizedError {
    case processingFailed
    case uploadFailed(String)
    case invalidURL
    case invalidImageData
    case insufficientStorage
    case fileTooLarge
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .processingFailed:
            return "Failed to process image"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .invalidImageData:
            return "Invalid image data"
        case .insufficientStorage:
            return "Insufficient storage space"
        case .fileTooLarge:
            return "File is too large"
        case .networkError:
            return "Network error occurred"
        }
    }
}

struct WardrobeImageUploadResult {
    let originalURL: String
    let thumbnailURL: String
    let fileName: String
    let fileSize: Int
    let dimensions: CGSize
    let metadata: ImageMetadata
    
    var fileSizeKB: Double {
        return Double(fileSize) / 1024.0
    }
    
    var fileSizeMB: Double {
        return fileSizeKB / 1024.0
    }
}

struct OutfitImageUploadResult {
    let originalURL: String
    let thumbnailURL: String
    let fileName: String
    let fileSize: Int
    let dimensions: CGSize
}

struct ProfileImageUploadResult {
    let imageURL: String
    let fileName: String
    let fileSize: Int
}

struct StorageUsage {
    let totalSize: Int64
    let fileCount: Int
    let usageByBucket: [String: BucketUsage]
    
    var totalSizeKB: Double {
        return Double(totalSize) / 1024.0
    }
    
    var totalSizeMB: Double {
        return totalSizeKB / 1024.0
    }
    
    var totalSizeGB: Double {
        return totalSizeMB / 1024.0
    }
    
    struct BucketUsage {
        let totalSize: Int64
        let fileCount: Int
        
        var totalSizeKB: Double {
            return Double(totalSize) / 1024.0
        }
        
        var totalSizeMB: Double {
            return totalSizeKB / 1024.0
        }
    }
}

struct CleanupResult {
    let deletedFiles: Int
    let freedBytes: Int64
    
    var freedKB: Double {
        return Double(freedBytes) / 1024.0
    }
    
    var freedMB: Double {
        return freedKB / 1024.0
    }
}

// MARK: - Extensions

extension ImageUploadService {
    func uploadWardrobeImageWithRetry(
        _ image: UIImage,
        userId: UUID,
        itemId: UUID? = nil,
        maxRetries: Int = 3,
        progress: ((Double) -> Void)? = nil
    ) async throws -> WardrobeImageUploadResult {
        
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await uploadWardrobeImage(
                    image,
                    userId: userId,
                    itemId: itemId,
                    progress: progress
                )
            } catch {
                lastError = error
                if attempt < maxRetries {
                    let delay = TimeInterval(attempt * 2)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? ImageUploadError.uploadFailed("Max retries exceeded")
    }
    
    func preloadImage(from url: String) async {
        do {
            _ = try await downloadImage(from: url)
        } catch {
            print("Failed to preload image: \(error)")
        }
    }
    
    func validateImageBeforeUpload(_ image: UIImage) throws {
        let metadata = image.metadata
        let fileSize = image.fileSize
        
        if fileSize > AppConfig.Business.maxPhotoSizeBytes {
            throw ImageUploadError.fileTooLarge
        }
        
        let minDimension: CGFloat = 100
        let maxDimension: CGFloat = 4000
        
        if metadata.width < Int(minDimension) || metadata.height < Int(minDimension) ||
           metadata.width > Int(maxDimension) || metadata.height > Int(maxDimension) {
            throw ImageUploadError.processingFailed
        }
    }
}