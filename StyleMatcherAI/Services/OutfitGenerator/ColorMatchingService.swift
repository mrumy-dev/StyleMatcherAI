import Foundation
import SwiftUI

struct ColorMatchingService {
    
    static func calculateColorHarmony(colors: [ClothingColor]) -> Double {
        guard colors.count >= 2 else { return 1.0 }
        
        var totalScore = 0.0
        var pairCount = 0
        
        for i in 0..<colors.count {
            for j in (i+1)..<colors.count {
                let pairScore = calculateColorPairHarmony(colors[i], colors[j])
                totalScore += pairScore
                pairCount += 1
            }
        }
        
        return pairCount > 0 ? totalScore / Double(pairCount) : 1.0
    }
    
    private static func calculateColorPairHarmony(_ color1: ClothingColor, _ color2: ClothingColor) -> Double {
        if isNeutralColor(color1) || isNeutralColor(color2) {
            return 0.9
        }
        
        guard let hex1 = color1.hexCode, let hex2 = color2.hexCode,
              let hsl1 = hexToHSL(hex1), let hsl2 = hexToHSL(hex2) else {
            return 0.5
        }
        
        let hueDifference = abs(hsl1.hue - hsl2.hue)
        let adjustedHueDifference = min(hueDifference, 360 - hueDifference)
        
        if isComplementary(adjustedHueDifference) {
            return 1.0
        } else if isAnalogous(adjustedHueDifference) {
            return 0.95
        } else if isTriadic(adjustedHueDifference) {
            return 0.85
        } else if isSplitComplementary(adjustedHueDifference) {
            return 0.8
        } else if isTetradic(adjustedHueDifference) {
            return 0.75
        } else {
            return max(0.2, 1.0 - (adjustedHueDifference / 180.0))
        }
    }
    
    static func canMixPatterns(_ pattern1: ClothingPattern, _ pattern2: ClothingPattern) -> Bool {
        if pattern1 == .solid || pattern2 == .solid {
            return true
        }
        
        let compatiblePairs: [(ClothingPattern, ClothingPattern)] = [
            (.stripes, .polkaDots),
            (.stripes, .floral),
            (.geometric, .abstract),
            (.plaid, .solid),
            (.checkered, .solid),
            (.paisley, .solid),
            (.animal, .solid),
            (.houndstooth, .solid),
            (.argyle, .solid)
        ]
        
        return compatiblePairs.contains { pair in
            (pair.0 == pattern1 && pair.1 == pattern2) ||
            (pair.0 == pattern2 && pair.1 == pattern1)
        }
    }
    
    static func calculatePatternCompatibility(patterns: [ClothingPattern]) -> Double {
        let uniquePatterns = Array(Set(patterns))
        
        if uniquePatterns.count <= 1 {
            return 1.0
        }
        
        if uniquePatterns.count > 3 {
            return 0.1
        }
        
        var totalScore = 0.0
        var pairCount = 0
        
        for i in 0..<uniquePatterns.count {
            for j in (i+1)..<uniquePatterns.count {
                if canMixPatterns(uniquePatterns[i], uniquePatterns[j]) {
                    totalScore += 1.0
                } else {
                    totalScore += 0.2
                }
                pairCount += 1
            }
        }
        
        return pairCount > 0 ? totalScore / Double(pairCount) : 1.0
    }
    
    private static func isNeutralColor(_ color: ClothingColor) -> Bool {
        let neutrals = ["black", "white", "gray", "grey", "navy", "beige", "cream", "khaki", "brown", "tan"]
        return neutrals.contains(color.name.lowercased())
    }
    
    private static func isComplementary(_ hueDifference: Double) -> Bool {
        return abs(hueDifference - 180) <= 15
    }
    
    private static func isAnalogous(_ hueDifference: Double) -> Bool {
        return hueDifference <= 30
    }
    
    private static func isTriadic(_ hueDifference: Double) -> Bool {
        return abs(hueDifference - 120) <= 15
    }
    
    private static func isSplitComplementary(_ hueDifference: Double) -> Bool {
        return abs(hueDifference - 150) <= 15 || abs(hueDifference - 210) <= 15
    }
    
    private static func isTetradic(_ hueDifference: Double) -> Bool {
        return abs(hueDifference - 90) <= 10 || abs(hueDifference - 270) <= 10
    }
    
    private static func hexToHSL(_ hex: String) -> (hue: Double, saturation: Double, lightness: Double)? {
        guard let rgb = hexToRGB(hex) else { return nil }
        return rgbToHSL(rgb.red, rgb.green, rgb.blue)
    }
    
    private static func hexToRGB(_ hex: String) -> (red: Double, green: Double, blue: Double)? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        return (red, green, blue)
    }
    
    private static func rgbToHSL(_ r: Double, _ g: Double, _ b: Double) -> (hue: Double, saturation: Double, lightness: Double) {
        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        let delta = max - min
        
        let lightness = (max + min) / 2.0
        
        guard delta != 0 else {
            return (0, 0, lightness)
        }
        
        let saturation = lightness > 0.5 ? delta / (2.0 - max - min) : delta / (max + min)
        
        var hue: Double
        if max == r {
            hue = ((g - b) / delta) + (g < b ? 6 : 0)
        } else if max == g {
            hue = (b - r) / delta + 2
        } else {
            hue = (r - g) / delta + 4
        }
        hue *= 60
        
        return (hue, saturation, lightness)
    }
}

extension ColorMatchingService {
    static func getSuggestedColors(for baseColor: ClothingColor) -> [ClothingColor] {
        guard let baseHex = baseColor.hexCode,
              let baseHSL = hexToHSL(baseHex) else {
            return getBasicNeutrals()
        }
        
        var suggestions: [ClothingColor] = []
        
        suggestions.append(contentsOf: getComplementaryColors(baseHSL: baseHSL))
        suggestions.append(contentsOf: getAnalogousColors(baseHSL: baseHSL))
        suggestions.append(contentsOf: getTriadicColors(baseHSL: baseHSL))
        suggestions.append(contentsOf: getBasicNeutrals())
        
        return Array(Set(suggestions)).prefix(8).map { $0 }
    }
    
    private static func getComplementaryColors(baseHSL: (hue: Double, saturation: Double, lightness: Double)) -> [ClothingColor] {
        let complementaryHue = (baseHSL.hue + 180).truncatingRemainder(dividingBy: 360)
        let complementaryColor = hslToClothingColor(
            hue: complementaryHue,
            saturation: baseHSL.saturation,
            lightness: baseHSL.lightness
        )
        return [complementaryColor]
    }
    
    private static func getAnalogousColors(baseHSL: (hue: Double, saturation: Double, lightness: Double)) -> [ClothingColor] {
        let analogous1 = hslToClothingColor(
            hue: (baseHSL.hue + 30).truncatingRemainder(dividingBy: 360),
            saturation: baseHSL.saturation,
            lightness: baseHSL.lightness
        )
        let analogous2 = hslToClothingColor(
            hue: (baseHSL.hue - 30 + 360).truncatingRemainder(dividingBy: 360),
            saturation: baseHSL.saturation,
            lightness: baseHSL.lightness
        )
        return [analogous1, analogous2]
    }
    
    private static func getTriadicColors(baseHSL: (hue: Double, saturation: Double, lightness: Double)) -> [ClothingColor] {
        let triadic1 = hslToClothingColor(
            hue: (baseHSL.hue + 120).truncatingRemainder(dividingBy: 360),
            saturation: baseHSL.saturation,
            lightness: baseHSL.lightness
        )
        let triadic2 = hslToClothingColor(
            hue: (baseHSL.hue + 240).truncatingRemainder(dividingBy: 360),
            saturation: baseHSL.saturation,
            lightness: baseHSL.lightness
        )
        return [triadic1, triadic2]
    }
    
    private static func getBasicNeutrals() -> [ClothingColor] {
        return [
            ClothingColor(name: "Black", hexCode: "#000000"),
            ClothingColor(name: "White", hexCode: "#FFFFFF"),
            ClothingColor(name: "Gray", hexCode: "#808080"),
            ClothingColor(name: "Navy", hexCode: "#000080")
        ]
    }
    
    private static func hslToClothingColor(hue: Double, saturation: Double, lightness: Double) -> ClothingColor {
        let hex = hslToHex(hue: hue, saturation: saturation, lightness: lightness)
        let name = getColorName(from: hue)
        return ClothingColor(name: name, hexCode: hex)
    }
    
    private static func hslToHex(hue: Double, saturation: Double, lightness: Double) -> String {
        let c = (1 - abs(2 * lightness - 1)) * saturation
        let x = c * (1 - abs((hue / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = lightness - c / 2
        
        var r, g, b: Double
        
        switch Int(hue / 60) {
        case 0: (r, g, b) = (c, x, 0)
        case 1: (r, g, b) = (x, c, 0)
        case 2: (r, g, b) = (0, c, x)
        case 3: (r, g, b) = (0, x, c)
        case 4: (r, g, b) = (x, 0, c)
        default: (r, g, b) = (c, 0, x)
        }
        
        r += m; g += m; b += m
        
        let red = Int((r * 255).rounded())
        let green = Int((g * 255).rounded())
        let blue = Int((b * 255).rounded())
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    private static func getColorName(from hue: Double) -> String {
        switch hue {
        case 0..<15, 345..<360: return "Red"
        case 15..<45: return "Orange"
        case 45..<75: return "Yellow"
        case 75..<150: return "Green"
        case 150..<210: return "Cyan"
        case 210..<270: return "Blue"
        case 270..<300: return "Purple"
        case 300..<345: return "Pink"
        default: return "Unknown"
        }
    }
}