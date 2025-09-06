import Foundation
import UIKit

final class OpenAIService {
    static let shared = OpenAIService()
    
    private let baseURL = "https://api.openai.com/v1"
    private let model = "gpt-4-vision-preview"
    private let maxRetries = 3
    private let initialRetryDelay: TimeInterval = 1.0
    
    private var apiKey: String {
        return Configuration.openAIAPIKey
    }
    
    private let urlSession: URLSession
    private let cache = AIResponseCache()
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: configuration)
    }
    
    // MARK: - Main Clothing Analysis Method
    
    func analyzeClothingItem(_ image: UIImage) async throws -> ClothingAnalysis {
        let cacheKey = generateCacheKey(for: image)
        
        if let cachedResult = await cache.getCachedAnalysis(for: cacheKey) {
            return cachedResult
        }
        
        let analysis = try await performClothingAnalysisWithRetry(image)
        await cache.cacheAnalysis(analysis, for: cacheKey)
        
        return analysis
    }
    
    // MARK: - Vision API Integration
    
    private func performClothingAnalysisWithRetry(_ image: UIImage) async throws -> ClothingAnalysis {
        var lastError: Error?
        var retryDelay = initialRetryDelay
        
        for attempt in 1...maxRetries {
            do {
                return try await performClothingAnalysis(image)
            } catch let error as OpenAIError {
                lastError = error
                
                switch error {
                case .rateLimitExceeded, .serverError, .networkError:
                    if attempt < maxRetries {
                        try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                        retryDelay *= 2.0 // Exponential backoff
                        continue
                    }
                case .invalidAPIKey, .invalidRequest, .contentPolicyViolation:
                    // Don't retry these errors
                    throw error
                case .quotaExceeded:
                    throw error
                }
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    retryDelay *= 2.0
                    continue
                }
            }
        }
        
        // If all retries failed, try fallback analysis
        do {
            return try await fallbackClothingAnalysis(image)
        } catch {
            // If fallback also fails, throw the original API error
            throw lastError ?? OpenAIError.networkError
        }
    }
    
    private func performClothingAnalysis(_ image: UIImage) async throws -> ClothingAnalysis {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw OpenAIError.invalidRequest
        }
        
        let base64Image = imageData.base64EncodedString()
        let prompt = createClothingAnalysisPrompt()
        
        let requestBody = OpenAIVisionRequest(
            model: model,
            messages: [
                OpenAIMessage(
                    role: "user",
                    content: [
                        .text(prompt),
                        .image(base64Image)
                    ]
                )
            ],
            maxTokens: 1000,
            temperature: 0.1
        )
        
        let response = try await makeOpenAIRequest(requestBody)
        return try parseClothingAnalysisResponse(response)
    }
    
    // MARK: - Prompt Engineering
    
    private func createClothingAnalysisPrompt() -> String {
        return """
        Analyze this clothing item image and provide a detailed JSON response with the following structure:
        
        {
            "clothingType": {
                "category": "tops|bottoms|dresses|outerwear|shoes|accessories|underwear|activewear|sleepwear|swimwear",
                "subcategory": "specific type like 'shirt', 'jeans', 'sneakers', etc.",
                "confidence": 0.95
            },
            "colors": {
                "dominant": {
                    "name": "Blue",
                    "hexCode": "#1E3A8A",
                    "percentage": 70
                },
                "accent": [
                    {
                        "name": "White",
                        "hexCode": "#FFFFFF",
                        "percentage": 20
                    }
                ]
            },
            "patterns": {
                "primary": "solid|stripes|polka_dots|plaid|checkered|floral|geometric|abstract|animal|paisley",
                "description": "Detailed pattern description",
                "confidence": 0.90
            },
            "formality": {
                "level": "casual|smart_casual|business|formal",
                "confidence": 0.85,
                "reasoning": "Brief explanation"
            },
            "materials": [
                {
                    "type": "cotton|wool|silk|polyester|denim|leather|etc",
                    "confidence": 0.80
                }
            ],
            "style": {
                "fit": "slim|regular|loose|oversized|fitted",
                "sleeves": "short|long|sleeveless|3/4|etc",
                "neckline": "crew|v-neck|scoop|etc",
                "closure": "buttons|zipper|pullover|etc"
            },
            "condition": {
                "assessment": "excellent|good|fair|poor",
                "visible_wear": "boolean",
                "stains_or_damage": "boolean"
            },
            "versatility": {
                "seasons": ["spring", "summer", "fall", "winter"],
                "occasions": ["work", "casual", "formal", "athletic", "etc"],
                "styling_difficulty": "easy|moderate|challenging"
            }
        }
        
        Be precise with hex codes and ensure all confidence scores are realistic. If you're uncertain about any aspect, lower the confidence score accordingly.
        """
    }
    
    // MARK: - API Communication
    
    private func makeOpenAIRequest(_ requestBody: OpenAIVisionRequest) async throws -> OpenAIResponse {
        guard !apiKey.isEmpty else {
            throw OpenAIError.invalidAPIKey
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw OpenAIError.invalidRequest
        }
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try JSONDecoder().decode(OpenAIResponse.self, from: data)
            case 400:
                throw OpenAIError.invalidRequest
            case 401:
                throw OpenAIError.invalidAPIKey
            case 429:
                throw OpenAIError.rateLimitExceeded
            case 500...599:
                throw OpenAIError.serverError
            default:
                throw OpenAIError.networkError
            }
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError
        }
    }
    
    // MARK: - Response Parsing
    
    private func parseClothingAnalysisResponse(_ response: OpenAIResponse) throws -> ClothingAnalysis {
        guard let choice = response.choices.first,
              let content = choice.message.content else {
            throw OpenAIError.invalidResponse
        }
        
        // Extract JSON from the response content
        let jsonString = extractJSON(from: content)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        do {
            let analysisData = try JSONDecoder().decode(OpenAIClothingAnalysisData.self, from: jsonData)
            return convertToClothingAnalysis(analysisData)
        } catch {
            // If structured parsing fails, try fallback parsing
            return try parseClothingAnalysisWithFallback(content)
        }
    }
    
    private func extractJSON(from content: String) -> String {
        // Look for JSON content between ```json and ``` or { and }
        if let range = content.range(of: "```json"),
           let endRange = content.range(of: "```", range: range.upperBound..<content.endIndex) {
            return String(content[range.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Look for JSON object
        if let startIndex = content.firstIndex(of: "{"),
           let endIndex = content.lastIndex(of: "}") {
            return String(content[startIndex...endIndex])
        }
        
        return content
    }
    
    private func convertToClothingAnalysis(_ data: OpenAIClothingAnalysisData) -> ClothingAnalysis {
        // Convert colors
        let dominantColor = ClothingColor(
            name: data.colors.dominant.name,
            hexCode: data.colors.dominant.hexCode,
            isPrimary: true
        )
        
        let accentColors = data.colors.accent?.map { accent in
            ClothingColor(
                name: accent.name,
                hexCode: accent.hexCode,
                isPrimary: false
            )
        } ?? []
        
        let allColors = [dominantColor] + accentColors
        
        // Convert patterns
        let patterns = [ClothingPattern(rawValue: data.patterns.primary) ?? .solid]
        
        // Convert formality
        let formality = FormalityLevel(rawValue: data.formality.level) ?? .casual
        
        // Convert clothing category
        let category = ClothingCategory(rawValue: data.clothingType.category) ?? .tops
        
        // Convert seasons
        let seasons = data.versatility?.seasons.compactMap { Season(rawValue: $0) } ?? []
        
        // Convert condition
        let condition = ItemCondition(rawValue: data.condition?.assessment ?? "excellent") ?? .excellent
        
        return ClothingAnalysis(
            category: category,
            subcategory: data.clothingType.subcategory,
            colors: allColors,
            patterns: patterns,
            formality: formality,
            materials: data.materials?.map { $0.type } ?? [],
            seasons: seasons,
            occasions: data.versatility?.occasions ?? [],
            condition: condition,
            confidence: ClothingAnalysisConfidence(
                overall: min(data.clothingType.confidence, data.patterns.confidence, data.formality.confidence),
                category: data.clothingType.confidence,
                colors: 0.85, // Default confidence for colors
                patterns: data.patterns.confidence,
                formality: data.formality.confidence
            ),
            aiAnalysis: AIAnalysisMetadata(
                model: model,
                timestamp: Date(),
                processingTime: 0,
                rawResponse: nil
            )
        )
    }
    
    // MARK: - Fallback Analysis
    
    private func fallbackClothingAnalysis(_ image: UIImage) async throws -> ClothingAnalysis {
        // Implement rule-based fallback analysis
        let fallbackAnalyzer = FallbackClothingAnalyzer()
        return try await fallbackAnalyzer.analyzeImage(image)
    }
    
    private func parseClothingAnalysisWithFallback(_ content: String) throws -> ClothingAnalysis {
        // Simple keyword-based parsing as fallback
        let fallbackParser = FallbackResponseParser()
        return try fallbackParser.parseResponse(content)
    }
    
    // MARK: - Utility Methods
    
    private func generateCacheKey(for image: UIImage) -> String {
        let imageData = image.pngData() ?? Data()
        let hash = imageData.sha256
        return "clothing_analysis_\(hash)"
    }
}

// MARK: - Supporting Types

enum OpenAIError: LocalizedError {
    case invalidAPIKey
    case invalidRequest
    case rateLimitExceeded
    case serverError
    case networkError
    case quotaExceeded
    case contentPolicyViolation
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid OpenAI API key"
        case .invalidRequest:
            return "Invalid request format"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError:
            return "OpenAI server error"
        case .networkError:
            return "Network connection error"
        case .quotaExceeded:
            return "API quota exceeded"
        case .contentPolicyViolation:
            return "Content violates OpenAI policy"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        }
    }
}

struct OpenAIVisionRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: [MessageContent]
}

enum MessageContent: Codable {
    case text(String)
    case image(String)
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let base64):
            try container.encode("image_url", forKey: .type)
            let imageUrl = ImageURL(url: "data:image/jpeg;base64,\(base64)")
            try container.encode(imageUrl, forKey: .imageUrl)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "image_url":
            let imageUrl = try container.decode(ImageURL.self, forKey: .imageUrl)
            // Extract base64 from data URL
            let base64 = imageUrl.url.components(separatedBy: ",").last ?? ""
            self = .image(base64)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown content type")
            )
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, text
        case imageUrl = "image_url"
    }
    
    private struct ImageURL: Codable {
        let url: String
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    let usage: Usage?
    
    struct Choice: Codable {
        let message: ResponseMessage
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct ResponseMessage: Codable {
        let role: String
        let content: String?
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// MARK: - Analysis Data Structures

struct OpenAIClothingAnalysisData: Codable {
    let clothingType: ClothingTypeData
    let colors: ColorsData
    let patterns: PatternsData
    let formality: FormalityData
    let materials: [MaterialData]?
    let style: StyleData?
    let condition: ConditionData?
    let versatility: VersatilityData?
    
    struct ClothingTypeData: Codable {
        let category: String
        let subcategory: String
        let confidence: Double
    }
    
    struct ColorsData: Codable {
        let dominant: ColorData
        let accent: [ColorData]?
        
        struct ColorData: Codable {
            let name: String
            let hexCode: String
            let percentage: Double?
        }
    }
    
    struct PatternsData: Codable {
        let primary: String
        let description: String?
        let confidence: Double
    }
    
    struct FormalityData: Codable {
        let level: String
        let confidence: Double
        let reasoning: String?
    }
    
    struct MaterialData: Codable {
        let type: String
        let confidence: Double
    }
    
    struct StyleData: Codable {
        let fit: String?
        let sleeves: String?
        let neckline: String?
        let closure: String?
    }
    
    struct ConditionData: Codable {
        let assessment: String
        let visibleWear: Bool?
        let stainsOrDamage: Bool?
        
        enum CodingKeys: String, CodingKey {
            case assessment
            case visibleWear = "visible_wear"
            case stainsOrDamage = "stains_or_damage"
        }
    }
    
    struct VersatilityData: Codable {
        let seasons: [String]
        let occasions: [String]
        let stylingDifficulty: String?
        
        enum CodingKeys: String, CodingKey {
            case seasons, occasions
            case stylingDifficulty = "styling_difficulty"
        }
    }
}

// MARK: - Main Analysis Result

struct ClothingAnalysis {
    let category: ClothingCategory
    let subcategory: String?
    let colors: [ClothingColor]
    let patterns: [ClothingPattern]
    let formality: FormalityLevel
    let materials: [String]
    let seasons: [Season]
    let occasions: [String]
    let condition: ItemCondition
    let confidence: ClothingAnalysisConfidence
    let aiAnalysis: AIAnalysisMetadata
}

struct ClothingAnalysisConfidence {
    let overall: Double
    let category: Double
    let colors: Double
    let patterns: Double
    let formality: Double
    
    var isReliable: Bool {
        return overall >= 0.7
    }
    
    var qualityScore: AnalysisQuality {
        switch overall {
        case 0.9...1.0:
            return .excellent
        case 0.8..<0.9:
            return .good
        case 0.6..<0.8:
            return .moderate
        default:
            return .poor
        }
    }
}

enum AnalysisQuality: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case moderate = "moderate"
    case poor = "poor"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

struct AIAnalysisMetadata {
    let model: String
    let timestamp: Date
    let processingTime: TimeInterval
    let rawResponse: String?
}

// MARK: - Extensions

extension Data {
    var sha256: String {
        let hash = withUnsafeBytes { bytes in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

import CommonCrypto