import Foundation
import UIKit

@MainActor
final class AIClothingAnalysisService: ObservableObject {
    static let shared = AIClothingAnalysisService()
    
    @Published var isAnalyzing = false
    @Published var analysisProgress = 0.0
    @Published var lastAnalysisResult: ClothingAnalysis?
    @Published var analysisError: Error?
    
    private let openAIService = OpenAIService.shared
    private let imageProcessor = ImageProcessor.shared
    private let cacheCleanupService = CacheCleanupService.shared
    
    private init() {}
    
    // MARK: - Main Analysis Method
    
    func analyzeWardrobeItem(
        _ image: UIImage,
        progress: ((Double) -> Void)? = nil
    ) async throws -> WardrobeItemAnalysisResult {
        
        isAnalyzing = true
        analysisProgress = 0.0
        analysisError = nil
        defer {
            isAnalyzing = false
            analysisProgress = 1.0
        }
        
        // Step 1: Process image for optimal analysis
        await updateProgress(0.1, progress)
        guard let processedImage = await preprocessImageForAnalysis(image) else {
            throw AIAnalysisError.imageProcessingFailed
        }
        
        // Step 2: Perform AI analysis
        await updateProgress(0.3, progress)
        let analysis = try await performAnalysisWithFallback(processedImage)
        lastAnalysisResult = analysis
        
        // Step 3: Generate wardrobe item suggestions
        await updateProgress(0.8, progress)
        let wardrobeItem = createWardrobeItem(from: analysis, originalImage: image)
        
        await updateProgress(1.0, progress)
        
        return WardrobeItemAnalysisResult(
            analysis: analysis,
            suggestedWardrobeItem: wardrobeItem,
            processingMetadata: AnalysisProcessingMetadata(
                totalProcessingTime: analysis.aiAnalysis.processingTime,
                imagePreprocessingApplied: true,
                analysisMethod: analysis.aiAnalysis.model,
                confidenceScore: analysis.confidence.overall
            )
        )
    }
    
    // MARK: - Batch Analysis
    
    func analyzeBatch(
        _ images: [UIImage],
        maxConcurrency: Int = 3,
        progress: ((Double, Int, Int) -> Void)? = nil
    ) async throws -> [WardrobeItemAnalysisResult] {
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        var results: [WardrobeItemAnalysisResult] = []
        let totalImages = images.count
        
        // Process images in batches to avoid overwhelming the API
        let batches = images.chunked(into: maxConcurrency)
        
        for (batchIndex, batch) in batches.enumerated() {
            let batchResults = try await withThrowingTaskGroup(
                of: WardrobeItemAnalysisResult.self
            ) { group in
                // Add tasks for each image in the batch
                for (imageIndex, image) in batch.enumerated() {
                    group.addTask {
                        return try await self.analyzeWardrobeItem(image)
                    }
                }
                
                // Collect results
                var batchResults: [WardrobeItemAnalysisResult] = []
                for try await result in group {
                    batchResults.append(result)
                    
                    let completedCount = results.count + batchResults.count
                    await MainActor.run {
                        progress?(
                            Double(completedCount) / Double(totalImages),
                            completedCount,
                            totalImages
                        )
                    }
                }
                return batchResults
            }
            
            results.append(contentsOf: batchResults)
            
            // Add delay between batches to respect rate limits
            if batchIndex < batches.count - 1 {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
            }
        }
        
        return results
    }
    
    // MARK: - Analysis Quality Assessment
    
    func assessAnalysisQuality(_ analysis: ClothingAnalysis) -> AnalysisQualityReport {
        let confidence = analysis.confidence
        
        var issues: [AnalysisIssue] = []
        var strengths: [AnalysisStrength] = []
        
        // Check confidence scores
        if confidence.overall < 0.5 {
            issues.append(.lowOverallConfidence(confidence.overall))
        }
        
        if confidence.category < 0.6 {
            issues.append(.uncertainCategoryDetection(confidence.category))
        }
        
        if confidence.colors < 0.6 {
            issues.append(.uncertainColorDetection(confidence.colors))
        }
        
        // Check for strengths
        if confidence.overall > 0.8 {
            strengths.append(.highOverallConfidence)
        }
        
        if analysis.colors.count > 2 {
            strengths.append(.richColorInformation)
        }
        
        if !analysis.materials.isEmpty {
            strengths.append(.materialInformationDetected)
        }
        
        let qualityScore = calculateQualityScore(analysis)
        
        return AnalysisQualityReport(
            overallScore: qualityScore,
            qualityLevel: confidence.qualityScore,
            issues: issues,
            strengths: strengths,
            recommendations: generateRecommendations(issues: issues, analysis: analysis)
        )
    }
    
    // MARK: - Private Methods
    
    private func preprocessImageForAnalysis(_ image: UIImage) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Optimize image for AI analysis
                let corrected = self.imageProcessor.correctImageOrientation(image)
                
                // Resize to optimal dimensions (not too large to avoid token limits)
                let resized = self.imageProcessor.resizeImage(
                    corrected,
                    maxDimension: 1024
                )
                
                continuation.resume(returning: resized)
            }
        }
    }
    
    private func performAnalysisWithFallback(_ image: UIImage) async throws -> ClothingAnalysis {
        do {
            // Try OpenAI Vision API first
            return try await openAIService.analyzeClothingItem(image)
        } catch let error as OpenAIError {
            print("OpenAI analysis failed: \(error.localizedDescription)")
            
            // Use fallback for certain error types
            switch error {
            case .quotaExceeded, .rateLimitExceeded:
                // These might be temporary, so we can retry later
                throw error
            default:
                // For other errors, use fallback
                let fallbackAnalyzer = FallbackClothingAnalyzer()
                return try await fallbackAnalyzer.analyzeImage(image)
            }
        } catch {
            print("Unexpected error in OpenAI analysis: \(error.localizedDescription)")
            
            // Use fallback for any unexpected errors
            let fallbackAnalyzer = FallbackClothingAnalyzer()
            return try await fallbackAnalyzer.analyzeImage(image)
        }
    }
    
    private func createWardrobeItem(
        from analysis: ClothingAnalysis,
        originalImage: UIImage
    ) -> WardrobeItem {
        
        // This would typically require a user ID, but we'll create a template
        let userId = UUID() // Placeholder - should come from current user
        
        return WardrobeItem(
            userId: userId,
            name: generateItemName(from: analysis),
            description: generateItemDescription(from: analysis),
            category: analysis.category,
            subcategory: analysis.subcategory,
            brand: nil, // AI doesn't detect brands reliably
            colors: analysis.colors,
            patterns: analysis.patterns,
            materials: analysis.materials,
            formality: analysis.formality,
            season: analysis.seasons,
            occasion: analysis.occasions,
            condition: analysis.condition,
            tags: generateTags(from: analysis),
            imageURLs: [], // Would be populated after upload
            thumbnailURL: nil, // Would be populated after upload
            notes: generateNotes(from: analysis)
        )
    }
    
    private func generateItemName(from analysis: ClothingAnalysis) -> String {
        let colorName = analysis.colors.first?.name ?? "Colored"
        let subcategory = analysis.subcategory ?? analysis.category.displayName
        
        return "\(colorName) \(subcategory)"
    }
    
    private func generateItemDescription(from analysis: ClothingAnalysis) -> String {
        var description = "A \(analysis.formality.displayName.lowercased()) "
        
        if let subcategory = analysis.subcategory {
            description += subcategory.lowercased()
        } else {
            description += analysis.category.displayName.lowercased()
        }
        
        if let primaryColor = analysis.colors.first {
            description += " in \(primaryColor.name.lowercased())"
            
            if analysis.colors.count > 1 {
                let additionalColors = analysis.colors.dropFirst().map { $0.name.lowercased() }
                description += " with \(additionalColors.joined(separator: ", "))"
            }
        }
        
        if let pattern = analysis.patterns.first, pattern != .solid {
            description += " featuring a \(pattern.displayName.lowercased()) pattern"
        }
        
        if !analysis.materials.isEmpty {
            description += ". Made from \(analysis.materials.joined(separator: " and "))."
        }
        
        return description
    }
    
    private func generateTags(from analysis: ClothingAnalysis) -> [String] {
        var tags: [String] = []
        
        // Add formality as tag
        tags.append(analysis.formality.displayName.lowercased())
        
        // Add primary color as tag
        if let primaryColor = analysis.colors.first {
            tags.append(primaryColor.name.lowercased())
        }
        
        // Add pattern as tag
        if let pattern = analysis.patterns.first, pattern != .solid {
            tags.append(pattern.displayName.lowercased())
        }
        
        // Add occasions as tags
        tags.append(contentsOf: analysis.occasions.map { $0.lowercased() })
        
        // Add AI-generated tag
        tags.append("ai-analyzed")
        
        return Array(Set(tags)) // Remove duplicates
    }
    
    private func generateNotes(from analysis: ClothingAnalysis) -> String? {
        if analysis.confidence.overall < 0.7 {
            return "Note: AI analysis confidence was \(Int(analysis.confidence.overall * 100))%. You may want to review and adjust the details."
        }
        return nil
    }
    
    private func calculateQualityScore(_ analysis: ClothingAnalysis) -> Double {
        var score = analysis.confidence.overall
        
        // Bonus for rich information
        if analysis.colors.count > 1 { score += 0.05 }
        if !analysis.materials.isEmpty { score += 0.05 }
        if analysis.patterns.first != .solid { score += 0.05 }
        if !analysis.occasions.isEmpty { score += 0.05 }
        
        return min(score, 1.0)
    }
    
    private func generateRecommendations(
        issues: [AnalysisIssue],
        analysis: ClothingAnalysis
    ) -> [String] {
        var recommendations: [String] = []
        
        for issue in issues {
            switch issue {
            case .lowOverallConfidence:
                recommendations.append("Consider retaking the photo with better lighting")
            case .uncertainCategoryDetection:
                recommendations.append("Ensure the clothing item is clearly visible and centered")
            case .uncertainColorDetection:
                recommendations.append("Try taking the photo in natural lighting for better color accuracy")
            case .noMaterialDetected:
                recommendations.append("Material detection works better with close-up shots of the fabric")
            }
        }
        
        if recommendations.isEmpty {
            recommendations.append("Analysis looks good! No improvements needed.")
        }
        
        return recommendations
    }
    
    private func updateProgress(_ progress: Double, _ callback: ((Double) -> Void)?) async {
        await MainActor.run {
            self.analysisProgress = progress
            callback?(progress)
        }
    }
}

// MARK: - Supporting Types

struct WardrobeItemAnalysisResult {
    let analysis: ClothingAnalysis
    let suggestedWardrobeItem: WardrobeItem
    let processingMetadata: AnalysisProcessingMetadata
}

struct AnalysisProcessingMetadata {
    let totalProcessingTime: TimeInterval
    let imagePreprocessingApplied: Bool
    let analysisMethod: String
    let confidenceScore: Double
}

struct AnalysisQualityReport {
    let overallScore: Double
    let qualityLevel: AnalysisQuality
    let issues: [AnalysisIssue]
    let strengths: [AnalysisStrength]
    let recommendations: [String]
}

enum AnalysisIssue {
    case lowOverallConfidence(Double)
    case uncertainCategoryDetection(Double)
    case uncertainColorDetection(Double)
    case noMaterialDetected
    
    var description: String {
        switch self {
        case .lowOverallConfidence(let confidence):
            return "Low overall confidence (\(Int(confidence * 100))%)"
        case .uncertainCategoryDetection(let confidence):
            return "Uncertain category detection (\(Int(confidence * 100))%)"
        case .uncertainColorDetection(let confidence):
            return "Uncertain color detection (\(Int(confidence * 100))%)"
        case .noMaterialDetected:
            return "No material information detected"
        }
    }
}

enum AnalysisStrength {
    case highOverallConfidence
    case richColorInformation
    case materialInformationDetected
    case patternDetected
    
    var description: String {
        switch self {
        case .highOverallConfidence:
            return "High overall confidence"
        case .richColorInformation:
            return "Rich color information detected"
        case .materialInformationDetected:
            return "Material information detected"
        case .patternDetected:
            return "Pattern successfully detected"
        }
    }
}

enum AIAnalysisError: LocalizedError {
    case imageProcessingFailed
    case noValidImageProvided
    case analysisServiceUnavailable
    case batchProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image for analysis"
        case .noValidImageProvided:
            return "No valid image provided for analysis"
        case .analysisServiceUnavailable:
            return "AI analysis service is currently unavailable"
        case .batchProcessingFailed:
            return "Batch processing failed"
        }
    }
}

// MARK: - Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Usage Analytics

extension AIClothingAnalysisService {
    
    func recordAnalysisUsage(_ result: WardrobeItemAnalysisResult) {
        let analytics = AnalyticsUsage(
            timestamp: Date(),
            processingTime: result.processingMetadata.totalProcessingTime,
            confidenceScore: result.processingMetadata.confidenceScore,
            method: result.processingMetadata.analysisMethod,
            category: result.analysis.category.rawValue,
            success: true
        )
        
        // Record analytics (implementation depends on analytics service)
        Task {
            await AnalyticsService.shared.record(usage: analytics)
        }
    }
    
    func getUsageStatistics() async -> UsageStatistics {
        // Get usage statistics from analytics service
        return await AnalyticsService.shared.getAIUsageStats()
    }
}

struct AnalyticsUsage {
    let timestamp: Date
    let processingTime: TimeInterval
    let confidenceScore: Double
    let method: String
    let category: String
    let success: Bool
}

struct UsageStatistics {
    let totalAnalyses: Int
    let averageProcessingTime: TimeInterval
    let averageConfidence: Double
    let successRate: Double
    let mostAnalyzedCategory: String
    let fallbackUsageRate: Double
}

// Placeholder for analytics service
final class AnalyticsService {
    static let shared = AnalyticsService()
    
    func record(usage: AnalyticsUsage) async {
        // Implementation depends on your analytics provider
    }
    
    func getAIUsageStats() async -> UsageStatistics {
        // Return usage statistics
        return UsageStatistics(
            totalAnalyses: 0,
            averageProcessingTime: 0,
            averageConfidence: 0,
            successRate: 0,
            mostAnalyzedCategory: "",
            fallbackUsageRate: 0
        )
    }
}