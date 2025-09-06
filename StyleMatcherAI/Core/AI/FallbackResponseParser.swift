import Foundation
import UIKit

final class FallbackResponseParser {
    
    // MARK: - Keywords for Pattern Matching
    
    private let categoryKeywords: [String: ClothingCategory] = [
        "shirt": .tops,
        "blouse": .tops,
        "t-shirt": .tops,
        "tshirt": .tops,
        "sweater": .tops,
        "hoodie": .tops,
        "tank": .tops,
        "cardigan": .tops,
        "blazer": .tops,
        "vest": .tops,
        "top": .tops,
        
        "jeans": .bottoms,
        "pants": .bottoms,
        "trousers": .bottoms,
        "shorts": .bottoms,
        "skirt": .bottoms,
        "leggings": .bottoms,
        "chinos": .bottoms,
        "bottom": .bottoms,
        
        "dress": .dresses,
        "gown": .dresses,
        "frock": .dresses,
        
        "jacket": .outerwear,
        "coat": .outerwear,
        "puffer": .outerwear,
        "windbreaker": .outerwear,
        "parka": .outerwear,
        "trench": .outerwear,
        
        "shoes": .shoes,
        "sneakers": .shoes,
        "boots": .shoes,
        "heels": .shoes,
        "flats": .shoes,
        "sandals": .shoes,
        "loafers": .shoes,
        "oxfords": .shoes,
        
        "hat": .accessories,
        "scarf": .accessories,
        "belt": .accessories,
        "bag": .accessories,
        "jewelry": .accessories,
        "sunglasses": .accessories,
        "watch": .accessories,
        "gloves": .accessories,
        
        "bra": .underwear,
        "panties": .underwear,
        "boxers": .underwear,
        "briefs": .underwear,
        "undershirt": .underwear,
        
        "athletic": .activewear,
        "sports": .activewear,
        "yoga": .activewear,
        "workout": .activewear,
        "gym": .activewear,
        
        "pajamas": .sleepwear,
        "nightgown": .sleepwear,
        "robe": .sleepwear,
        
        "bikini": .swimwear,
        "swimsuit": .swimwear,
        "trunks": .swimwear
    ]
    
    private let colorKeywords: [String: String] = [
        "red": "#FF0000",
        "blue": "#0000FF",
        "green": "#008000",
        "yellow": "#FFFF00",
        "orange": "#FFA500",
        "purple": "#800080",
        "pink": "#FFC0CB",
        "brown": "#A52A2A",
        "black": "#000000",
        "white": "#FFFFFF",
        "gray": "#808080",
        "grey": "#808080",
        "navy": "#000080",
        "beige": "#F5F5DC",
        "cream": "#FFFDD0",
        "khaki": "#F0E68C",
        "maroon": "#800000",
        "olive": "#808000",
        "teal": "#008080",
        "silver": "#C0C0C0",
        "gold": "#FFD700"
    ]
    
    private let patternKeywords: [String: ClothingPattern] = [
        "solid": .solid,
        "plain": .solid,
        "stripes": .stripes,
        "striped": .stripes,
        "polka": .polkaDots,
        "dots": .polkaDots,
        "dotted": .polkaDots,
        "floral": .floral,
        "flowers": .floral,
        "plaid": .plaid,
        "checkered": .checkered,
        "checked": .checkered,
        "geometric": .geometric,
        "abstract": .abstract,
        "animal": .animal,
        "leopard": .animal,
        "zebra": .animal,
        "paisley": .paisley,
        "houndstooth": .houndstooth,
        "argyle": .argyle,
        "camouflage": .camouflage,
        "camo": .camouflage
    ]
    
    private let formalityKeywords: [String: FormalityLevel] = [
        "casual": .casual,
        "informal": .casual,
        "relaxed": .casual,
        "everyday": .casual,
        
        "smart casual": .smartCasual,
        "smart-casual": .smartCasual,
        "dressy casual": .smartCasual,
        
        "business": .business,
        "professional": .business,
        "office": .business,
        "work": .business,
        
        "formal": .formal,
        "dressy": .formal,
        "elegant": .formal,
        "sophisticated": .formal
    ]
    
    private let materialKeywords: [String] = [
        "cotton", "wool", "silk", "polyester", "denim", "leather",
        "linen", "cashmere", "velvet", "satin", "chiffon", "lace",
        "jersey", "corduroy", "flannel", "tweed", "canvas", "suede",
        "nylon", "spandex", "elastane", "rayon", "modal", "bamboo"
    ]
    
    private let conditionKeywords: [String: ItemCondition] = [
        "excellent": .excellent,
        "perfect": .excellent,
        "mint": .excellent,
        "new": .new,
        "brand new": .new,
        "unworn": .new,
        "good": .good,
        "fine": .good,
        "decent": .good,
        "fair": .fair,
        "worn": .fair,
        "used": .fair,
        "poor": .poor,
        "damaged": .poor,
        "torn": .poor,
        "stained": .poor
    ]
    
    // MARK: - Main Parsing Method
    
    func parseResponse(_ content: String) throws -> ClothingAnalysis {
        let normalizedContent = content.lowercased()
        
        let category = extractCategory(from: normalizedContent)
        let colors = extractColors(from: normalizedContent)
        let patterns = extractPatterns(from: normalizedContent)
        let formality = extractFormality(from: normalizedContent)
        let materials = extractMaterials(from: normalizedContent)
        let condition = extractCondition(from: normalizedContent)
        let seasons = inferSeasons(from: category, materials: materials)
        let occasions = inferOccasions(from: formality, category: category)
        
        return ClothingAnalysis(
            category: category,
            subcategory: extractSubcategory(from: normalizedContent, category: category),
            colors: colors,
            patterns: patterns,
            formality: formality,
            materials: materials,
            seasons: seasons,
            occasions: occasions,
            condition: condition,
            confidence: ClothingAnalysisConfidence(
                overall: 0.4, // Low confidence for keyword-based parsing
                category: 0.5,
                colors: 0.6,
                patterns: 0.4,
                formality: 0.5
            ),
            aiAnalysis: AIAnalysisMetadata(
                model: "fallback_parser_v1.0",
                timestamp: Date(),
                processingTime: 0.1,
                rawResponse: content
            )
        )
    }
    
    // MARK: - Extraction Methods
    
    private func extractCategory(from content: String) -> ClothingCategory {
        for (keyword, category) in categoryKeywords {
            if content.contains(keyword) {
                return category
            }
        }
        return .tops // Default fallback
    }
    
    private func extractSubcategory(from content: String, category: ClothingCategory) -> String? {
        let subcategories = category.subcategories
        
        for subcategory in subcategories {
            if content.contains(subcategory.lowercased()) {
                return subcategory
            }
        }
        
        return subcategories.first // Return first subcategory as fallback
    }
    
    private func extractColors(from content: String) -> [ClothingColor] {
        var foundColors: [ClothingColor] = []
        
        for (colorName, hexCode) in colorKeywords {
            if content.contains(colorName) {
                let isPrimary = foundColors.isEmpty
                foundColors.append(ClothingColor(
                    name: colorName.capitalized,
                    hexCode: hexCode,
                    isPrimary: isPrimary
                ))
                
                if foundColors.count >= 3 { break } // Limit to 3 colors
            }
        }
        
        // If no colors found, default to gray
        if foundColors.isEmpty {
            foundColors.append(ClothingColor(
                name: "Gray",
                hexCode: "#808080",
                isPrimary: true
            ))
        }
        
        return foundColors
    }
    
    private func extractPatterns(from content: String) -> [ClothingPattern] {
        for (keyword, pattern) in patternKeywords {
            if content.contains(keyword) {
                return [pattern]
            }
        }
        return [.solid] // Default pattern
    }
    
    private func extractFormality(from content: String) -> FormalityLevel {
        // Check for multi-word phrases first
        for (phrase, formality) in formalityKeywords {
            if content.contains(phrase) {
                return formality
            }
        }
        
        return .casual // Default formality
    }
    
    private func extractMaterials(from content: String) -> [String] {
        var foundMaterials: [String] = []
        
        for material in materialKeywords {
            if content.contains(material) {
                foundMaterials.append(material)
                
                if foundMaterials.count >= 2 { break } // Limit to 2 materials
            }
        }
        
        // If no materials found, default to cotton
        if foundMaterials.isEmpty {
            foundMaterials.append("cotton")
        }
        
        return foundMaterials
    }
    
    private func extractCondition(from content: String) -> ItemCondition {
        // Check for multi-word phrases first
        let sortedKeywords = conditionKeywords.keys.sorted { $0.count > $1.count }
        
        for keyword in sortedKeywords {
            if content.contains(keyword) {
                return conditionKeywords[keyword] ?? .excellent
            }
        }
        
        return .excellent // Default condition
    }
    
    // MARK: - Inference Methods
    
    private func inferSeasons(from category: ClothingCategory, materials: [String]) -> [Season] {
        switch category {
        case .swimwear:
            return [.summer]
        case .outerwear:
            if materials.contains("wool") || materials.contains("down") {
                return [.fall, .winter]
            } else {
                return [.spring, .fall]
            }
        case .activewear:
            return [.spring, .summer, .fall, .winter]
        case .sleepwear:
            return [.spring, .summer, .fall, .winter]
        default:
            if materials.contains("wool") || materials.contains("cashmere") {
                return [.fall, .winter]
            } else if materials.contains("linen") {
                return [.spring, .summer]
            } else {
                return [.spring, .summer, .fall]
            }
        }
    }
    
    private func inferOccasions(from formality: FormalityLevel, category: ClothingCategory) -> [String] {
        switch formality {
        case .formal:
            return ["formal", "business", "wedding", "gala"]
        case .business:
            return ["work", "business", "professional", "meeting"]
        case .smartCasual:
            return ["casual", "work", "date", "dinner"]
        case .casual:
            if category == .activewear {
                return ["athletic", "gym", "sports", "workout"]
            } else if category == .sleepwear {
                return ["sleep", "lounge", "home"]
            } else {
                return ["casual", "everyday", "weekend", "shopping"]
            }
        case .mixed:
            return ["versatile", "casual", "work", "social"]
        }
    }
}

// MARK: - Confidence Scoring

extension FallbackResponseParser {
    
    func calculateConfidenceScore(for content: String) -> Double {
        let normalizedContent = content.lowercased()
        var score: Double = 0.0
        var factors: Int = 0
        
        // Category confidence
        if categoryKeywords.keys.contains(where: { normalizedContent.contains($0) }) {
            score += 0.2
        }
        factors += 1
        
        // Color confidence
        let colorMatches = colorKeywords.keys.filter { normalizedContent.contains($0) }.count
        score += min(Double(colorMatches) * 0.1, 0.2)
        factors += 1
        
        // Pattern confidence
        if patternKeywords.keys.contains(where: { normalizedContent.contains($0) }) {
            score += 0.15
        }
        factors += 1
        
        // Formality confidence
        if formalityKeywords.keys.contains(where: { normalizedContent.contains($0) }) {
            score += 0.15
        }
        factors += 1
        
        // Material confidence
        let materialMatches = materialKeywords.filter { normalizedContent.contains($0) }.count
        score += min(Double(materialMatches) * 0.05, 0.15)
        factors += 1
        
        // Length bonus (longer descriptions tend to be more detailed)
        if content.count > 100 {
            score += 0.1
        }
        
        // Structure bonus (if content looks like JSON or has clear structure)
        if content.contains("{") && content.contains("}") {
            score += 0.15
        }
        
        return min(score, 1.0) // Cap at 1.0
    }
    
    func extractConfidenceFromContent(_ content: String) -> Double? {
        // Look for explicit confidence scores in the content
        let confidencePattern = #"confidence[\"']?\s*:\s*([0-9.]+)"#
        let regex = try? NSRegularExpression(pattern: confidencePattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: content.utf16.count)
        
        if let match = regex?.firstMatch(in: content, options: [], range: range),
           let confidenceRange = Range(match.range(at: 1), in: content) {
            let confidenceString = String(content[confidenceRange])
            return Double(confidenceString)
        }
        
        return nil
    }
}

// MARK: - Response Quality Assessment

extension FallbackResponseParser {
    
    enum ResponseQuality {
        case high
        case medium
        case low
        case poor
        
        var confidenceMultiplier: Double {
            switch self {
            case .high: return 1.0
            case .medium: return 0.8
            case .low: return 0.6
            case .poor: return 0.4
            }
        }
    }
    
    func assessResponseQuality(_ content: String) -> ResponseQuality {
        let normalizedContent = content.lowercased()
        var qualityScore = 0
        
        // Check for structured data
        if content.contains("{") && content.contains("}") {
            qualityScore += 2
        }
        
        // Check for multiple data points
        if colorKeywords.keys.filter({ normalizedContent.contains($0) }).count > 1 {
            qualityScore += 1
        }
        
        if materialKeywords.filter({ normalizedContent.contains($0) }).count > 0 {
            qualityScore += 1
        }
        
        if patternKeywords.keys.contains(where: { normalizedContent.contains($0) }) {
            qualityScore += 1
        }
        
        // Check for descriptive language
        if content.count > 200 {
            qualityScore += 1
        }
        
        // Check for specific details
        let detailKeywords = ["fabric", "texture", "style", "fit", "color", "pattern", "material"]
        let detailMatches = detailKeywords.filter { normalizedContent.contains($0) }.count
        qualityScore += min(detailMatches / 2, 2)
        
        switch qualityScore {
        case 6...:
            return .high
        case 4...5:
            return .medium
        case 2...3:
            return .low
        default:
            return .poor
        }
    }
}