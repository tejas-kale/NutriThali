import Foundation

struct MacroNutrients: Codable, Equatable {
    let protein: Double
    let carbs: Double
    let fats: Double
}

struct FoodAnalysisResult: Codable, Equatable {
    let estimatedPortionSize: String
    let dishName: String
    let calories: Double
    let macros: MacroNutrients
    let verdictEmoji: String
    let briefExplanation: String
    let diabeticFriendliness: String
    let diabeticAdvice: String
    let portionSizeSuggestion: String

    var verdict: String {
        return verdictEmoji == "✅" ? "Healthy" : "Caution"
    }
}

// Helper for decoding
struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]?
}
