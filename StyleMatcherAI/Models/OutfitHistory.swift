import Foundation

struct OutfitHistory: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let outfitId: UUID
    let wornDate: Date
    let occasion: String?
    let location: String?
    let weather: WeatherCondition?
    let mood: MoodRating?
    let confidence: ConfidenceLevel?
    let feedback: OutfitFeedback?
    let photos: [String]
    let notes: String?
    let rating: Int?
    let tags: [String]
    let duration: TimeInterval?
    let companions: [String]
    let activities: [String]
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case outfitId = "outfit_id"
        case wornDate = "worn_date"
        case occasion
        case location
        case weather
        case mood
        case confidence
        case feedback
        case photos
        case notes
        case rating
        case tags
        case duration
        case companions
        case activities
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        outfitId: UUID,
        wornDate: Date = Date(),
        occasion: String? = nil,
        location: String? = nil,
        weather: WeatherCondition? = nil,
        mood: MoodRating? = nil,
        confidence: ConfidenceLevel? = nil,
        feedback: OutfitFeedback? = nil,
        photos: [String] = [],
        notes: String? = nil,
        rating: Int? = nil,
        tags: [String] = [],
        duration: TimeInterval? = nil,
        companions: [String] = [],
        activities: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.outfitId = outfitId
        self.wornDate = wornDate
        self.occasion = occasion
        self.location = location
        self.weather = weather
        self.mood = mood
        self.confidence = confidence
        self.feedback = feedback
        self.photos = photos
        self.notes = notes
        self.rating = rating
        self.tags = tags
        self.duration = duration
        self.companions = companions
        self.activities = activities
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum MoodRating: String, Codable, CaseIterable {
    case terrible = "terrible"
    case bad = "bad"
    case neutral = "neutral"
    case good = "good"
    case excellent = "excellent"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var emoji: String {
        switch self {
        case .terrible:
            return "😞"
        case .bad:
            return "😕"
        case .neutral:
            return "😐"
        case .good:
            return "🙂"
        case .excellent:
            return "😄"
        }
    }
    
    var numericValue: Int {
        switch self {
        case .terrible:
            return 1
        case .bad:
            return 2
        case .neutral:
            return 3
        case .good:
            return 4
        case .excellent:
            return 5
        }
    }
    
    static func from(numericValue: Int) -> MoodRating? {
        switch numericValue {
        case 1:
            return .terrible
        case 2:
            return .bad
        case 3:
            return .neutral
        case 4:
            return .good
        case 5:
            return .excellent
        default:
            return nil
        }
    }
}

enum ConfidenceLevel: String, Codable, CaseIterable {
    case veryLow = "very_low"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "very_high"
    
    var displayName: String {
        switch self {
        case .veryLow:
            return "Very Low"
        case .low:
            return "Low"
        case .moderate:
            return "Moderate"
        case .high:
            return "High"
        case .veryHigh:
            return "Very High"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryLow:
            return "😰"
        case .low:
            return "😟"
        case .moderate:
            return "😊"
        case .high:
            return "😎"
        case .veryHigh:
            return "🔥"
        }
    }
    
    var numericValue: Int {
        switch self {
        case .veryLow:
            return 1
        case .low:
            return 2
        case .moderate:
            return 3
        case .high:
            return 4
        case .veryHigh:
            return 5
        }
    }
    
    var color: String {
        switch self {
        case .veryLow:
            return "#FF0000"
        case .low:
            return "#FF8000"
        case .moderate:
            return "#FFFF00"
        case .high:
            return "#80FF00"
        case .veryHigh:
            return "#00FF00"
        }
    }
}

struct OutfitFeedback: Codable, Equatable {
    let overall: Int
    let comfort: Int?
    let style: Int?
    let appropriateness: Int?
    let compliments: Int
    let positiveComments: [String]
    let negativeComments: [String]
    let suggestions: [String]
    let wouldWearAgain: Bool
    let recommendToFriend: Bool?
    
    enum CodingKeys: String, CodingKey {
        case overall
        case comfort
        case style
        case appropriateness
        case compliments
        case positiveComments = "positive_comments"
        case negativeComments = "negative_comments"
        case suggestions
        case wouldWearAgain = "would_wear_again"
        case recommendToFriend = "recommend_to_friend"
    }
    
    init(
        overall: Int,
        comfort: Int? = nil,
        style: Int? = nil,
        appropriateness: Int? = nil,
        compliments: Int = 0,
        positiveComments: [String] = [],
        negativeComments: [String] = [],
        suggestions: [String] = [],
        wouldWearAgain: Bool = true,
        recommendToFriend: Bool? = nil
    ) {
        self.overall = overall
        self.comfort = comfort
        self.style = style
        self.appropriateness = appropriateness
        self.compliments = compliments
        self.positiveComments = positiveComments
        self.negativeComments = negativeComments
        self.suggestions = suggestions
        self.wouldWearAgain = wouldWearAgain
        self.recommendToFriend = recommendToFriend
    }
}

extension OutfitHistory {
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: wornDate)
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: wornDate)
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(wornDate)
    }
    
    var isThisWeek: Bool {
        return Calendar.current.isDate(wornDate, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    var isThisMonth: Bool {
        return Calendar.current.isDate(wornDate, equalTo: Date(), toGranularity: .month)
    }
    
    var daysAgo: Int {
        return Calendar.current.dateComponents([.day], from: wornDate, to: Date()).day ?? 0
    }
    
    var wasSuccessful: Bool {
        guard let feedback = feedback else { return true }
        return feedback.overall >= 4 && feedback.wouldWearAgain
    }
    
    var hasPhotos: Bool {
        return !photos.isEmpty
    }
    
    var hasDetailedFeedback: Bool {
        guard let feedback = feedback else { return false }
        return !feedback.positiveComments.isEmpty || !feedback.negativeComments.isEmpty || !feedback.suggestions.isEmpty
    }
    
    var displayDuration: String? {
        guard let duration = duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    var weatherDescription: String? {
        guard let weather = weather else { return nil }
        return "\(weather.condition.emoji) \(weather.temperature.displayRange)"
    }
    
    var moodAndConfidence: String? {
        let moodString = mood?.emoji
        let confidenceString = confidence?.emoji
        
        switch (moodString, confidenceString) {
        case let (mood?, confidence?):
            return "\(mood) \(confidence)"
        case let (mood?, nil):
            return mood
        case let (nil, confidence?):
            return confidence
        case (nil, nil):
            return nil
        }
    }
    
    func isInSamePeriod(as other: OutfitHistory, granularity: Calendar.Component) -> Bool {
        return Calendar.current.isDate(wornDate, equalTo: other.wornDate, toGranularity: granularity)
    }
    
    func matchesFilter(
        occasion: String? = nil,
        rating: Int? = nil,
        season: Season? = nil,
        mood: MoodRating? = nil,
        confidence: ConfidenceLevel? = nil
    ) -> Bool {
        if let occasionFilter = occasion,
           let outfitOccasion = self.occasion,
           !outfitOccasion.localizedCaseInsensitiveContains(occasionFilter) {
            return false
        }
        
        if let ratingFilter = rating,
           let outfitRating = self.rating,
           outfitRating < ratingFilter {
            return false
        }
        
        if let seasonFilter = season {
            let currentSeason = Season.current
            let wornSeason = Calendar.current.component(.month, from: wornDate)
            let seasonMatch: Bool
            
            switch wornSeason {
            case 3...5:
                seasonMatch = seasonFilter == .spring
            case 6...8:
                seasonMatch = seasonFilter == .summer
            case 9...11:
                seasonMatch = seasonFilter == .fall
            default:
                seasonMatch = seasonFilter == .winter
            }
            
            if !seasonMatch {
                return false
            }
        }
        
        if let moodFilter = mood,
           self.mood != moodFilter {
            return false
        }
        
        if let confidenceFilter = confidence,
           self.confidence != confidenceFilter {
            return false
        }
        
        return true
    }
}

extension Array where Element == OutfitHistory {
    var groupedByDate: [String: [OutfitHistory]] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return Dictionary(grouping: self) { history in
            formatter.string(from: history.wornDate)
        }
    }
    
    var groupedByWeek: [String: [OutfitHistory]] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        
        return Dictionary(grouping: self) { history in
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: history.wornDate)?.start ?? history.wornDate
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? history.wornDate
            return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
        }
    }
    
    var groupedByMonth: [String: [OutfitHistory]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        return Dictionary(grouping: self) { history in
            formatter.string(from: history.wornDate)
        }
    }
    
    var averageRating: Double? {
        let ratingsOnly = compactMap { $0.rating }
        guard !ratingsOnly.isEmpty else { return nil }
        
        let sum = ratingsOnly.reduce(0, +)
        return Double(sum) / Double(ratingsOnly.count)
    }
    
    var mostWornDay: String? {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        let dayGroups = Dictionary(grouping: self) { history in
            dayFormatter.string(from: history.wornDate)
        }
        
        return dayGroups.max(by: { $0.value.count < $1.value.count })?.key
    }
    
    var favoriteOccasion: String? {
        let occasions = compactMap { $0.occasion }
        guard !occasions.isEmpty else { return nil }
        
        let occasionCounts = Dictionary(grouping: occasions, by: { $0 })
            .mapValues { $0.count }
        
        return occasionCounts.max(by: { $0.value < $1.value })?.key
    }
    
    var totalWearTime: TimeInterval {
        return compactMap { $0.duration }.reduce(0, +)
    }
    
    func mostWornInPeriod(_ component: Calendar.Component) -> [String: Int] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        switch component {
        case .weekOfYear:
            formatter.dateFormat = "w yyyy"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .year:
            formatter.dateFormat = "yyyy"
        default:
            formatter.dateStyle = .medium
        }
        
        let periodGroups = Dictionary(grouping: self) { history in
            formatter.string(from: history.wornDate)
        }
        
        return periodGroups.mapValues { $0.count }
    }
}