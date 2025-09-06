import Foundation

actor AIResponseCache {
    private var memoryCache: [String: CachedAnalysis] = [:]
    private let maxCacheSize = 100
    private let cacheExpirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
    private let fileManager = FileManager.default
    
    private var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = urls[0].appendingPathComponent("AIAnalysisCache")
        
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        
        return cacheDir
    }
    
    func getCachedAnalysis(for key: String) async -> ClothingAnalysis? {
        // First check memory cache
        if let cached = memoryCache[key],
           !cached.isExpired {
            return cached.analysis
        }
        
        // Then check disk cache
        if let diskCached = await loadFromDisk(key: key),
           !diskCached.isExpired {
            memoryCache[key] = diskCached
            return diskCached.analysis
        }
        
        // Clean up expired entry if it exists
        memoryCache.removeValue(forKey: key)
        await removeFromDisk(key: key)
        
        return nil
    }
    
    func cacheAnalysis(_ analysis: ClothingAnalysis, for key: String) async {
        let cached = CachedAnalysis(analysis: analysis, timestamp: Date())
        
        // Store in memory cache
        memoryCache[key] = cached
        
        // Store on disk
        await saveToDisk(cached: cached, key: key)
        
        // Clean up old entries if cache is too large
        await cleanupCacheIfNeeded()
    }
    
    func clearCache() async {
        memoryCache.removeAll()
        await clearDiskCache()
    }
    
    func getCacheSize() async -> (memoryCount: Int, diskSize: Int64) {
        let memoryCount = memoryCache.count
        let diskSize = await calculateDiskCacheSize()
        return (memoryCount, diskSize)
    }
    
    func getCacheStatistics() async -> CacheStatistics {
        let (memoryCount, diskSize) = await getCacheSize()
        let expiredCount = memoryCache.values.filter { $0.isExpired }.count
        
        return CacheStatistics(
            totalEntries: memoryCount,
            expiredEntries: expiredCount,
            diskSizeBytes: diskSize,
            cacheHitRate: 0.0 // Would need to track hits/misses to calculate
        )
    }
    
    // MARK: - Private Methods
    
    private func loadFromDisk(key: String) async -> CachedAnalysis? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let cached = try JSONDecoder().decode(CachedAnalysis.self, from: data)
            return cached
        } catch {
            // Remove corrupted file
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }
    
    private func saveToDisk(cached: CachedAnalysis, key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        do {
            let data = try JSONEncoder().encode(cached)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save cache to disk: \(error)")
        }
    }
    
    private func removeFromDisk(key: String) async {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        try? fileManager.removeItem(at: fileURL)
    }
    
    private func clearDiskCache() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to clear disk cache: \(error)")
        }
    }
    
    private func cleanupCacheIfNeeded() async {
        guard memoryCache.count > maxCacheSize else { return }
        
        // Remove expired entries first
        let expiredKeys = memoryCache.compactMap { key, value in
            value.isExpired ? key : nil
        }
        
        for key in expiredKeys {
            memoryCache.removeValue(forKey: key)
            await removeFromDisk(key: key)
        }
        
        // If still over limit, remove oldest entries
        if memoryCache.count > maxCacheSize {
            let sortedByDate = memoryCache.sorted { $0.value.timestamp < $1.value.timestamp }
            let toRemove = sortedByDate.prefix(memoryCache.count - maxCacheSize)
            
            for (key, _) in toRemove {
                memoryCache.removeValue(forKey: key)
                await removeFromDisk(key: key)
            }
        }
    }
    
    private func calculateDiskCacheSize() async -> Int64 {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            var totalSize: Int64 = 0
            
            for file in files {
                let resourceValues = try file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
            
            return totalSize
        } catch {
            return 0
        }
    }
}

// MARK: - Supporting Types

struct CachedAnalysis: Codable {
    let analysis: ClothingAnalysis
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 24 * 60 * 60 // 24 hours
    }
}

extension ClothingAnalysis: Codable {
    enum CodingKeys: String, CodingKey {
        case category, subcategory, colors, patterns, formality
        case materials, seasons, occasions, condition
        case confidence, aiAnalysis
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(category.rawValue, forKey: .category)
        try container.encode(subcategory, forKey: .subcategory)
        try container.encode(colors, forKey: .colors)
        try container.encode(patterns.map { $0.rawValue }, forKey: .patterns)
        try container.encode(formality.rawValue, forKey: .formality)
        try container.encode(materials, forKey: .materials)
        try container.encode(seasons.map { $0.rawValue }, forKey: .seasons)
        try container.encode(occasions, forKey: .occasions)
        try container.encode(condition.rawValue, forKey: .condition)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(aiAnalysis, forKey: .aiAnalysis)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let categoryString = try container.decode(String.self, forKey: .category)
        category = ClothingCategory(rawValue: categoryString) ?? .tops
        
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory)
        colors = try container.decode([ClothingColor].self, forKey: .colors)
        
        let patternsStrings = try container.decode([String].self, forKey: .patterns)
        patterns = patternsStrings.compactMap { ClothingPattern(rawValue: $0) }
        
        let formalityString = try container.decode(String.self, forKey: .formality)
        formality = FormalityLevel(rawValue: formalityString) ?? .casual
        
        materials = try container.decode([String].self, forKey: .materials)
        
        let seasonsStrings = try container.decode([String].self, forKey: .seasons)
        seasons = seasonsStrings.compactMap { Season(rawValue: $0) }
        
        occasions = try container.decode([String].self, forKey: .occasions)
        
        let conditionString = try container.decode(String.self, forKey: .condition)
        condition = ItemCondition(rawValue: conditionString) ?? .excellent
        
        confidence = try container.decode(ClothingAnalysisConfidence.self, forKey: .confidence)
        aiAnalysis = try container.decode(AIAnalysisMetadata.self, forKey: .aiAnalysis)
    }
}

extension ClothingAnalysisConfidence: Codable {}
extension AIAnalysisMetadata: Codable {}

struct CacheStatistics {
    let totalEntries: Int
    let expiredEntries: Int
    let diskSizeBytes: Int64
    let cacheHitRate: Double
    
    var diskSizeKB: Double {
        return Double(diskSizeBytes) / 1024.0
    }
    
    var diskSizeMB: Double {
        return diskSizeKB / 1024.0
    }
    
    var activeEntries: Int {
        return totalEntries - expiredEntries
    }
}

// MARK: - Cache Management Protocol

protocol CacheManaging {
    func getCachedAnalysis(for key: String) async -> ClothingAnalysis?
    func cacheAnalysis(_ analysis: ClothingAnalysis, for key: String) async
    func clearCache() async
    func getCacheStatistics() async -> CacheStatistics
}

extension AIResponseCache: CacheManaging {}

// MARK: - Cache Cleanup Service

final class CacheCleanupService {
    static let shared = CacheCleanupService()
    
    private let cache = AIResponseCache()
    private var cleanupTimer: Timer?
    
    private init() {
        startPeriodicCleanup()
    }
    
    func startPeriodicCleanup() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task {
                await self.performCleanup()
            }
        }
    }
    
    func stopPeriodicCleanup() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
    
    func performCleanup() async {
        let stats = await cache.getCacheStatistics()
        
        // If cache is too large or has too many expired entries, clear it
        if stats.diskSizeMB > 100 || stats.expiredEntries > 50 {
            await cache.clearCache()
            print("AI cache cleanup completed. Freed \(stats.diskSizeMB) MB")
        }
    }
    
    deinit {
        stopPeriodicCleanup()
    }
}