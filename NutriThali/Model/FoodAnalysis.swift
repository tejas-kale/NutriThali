import Foundation

struct MacroNutrients: Codable, Equatable {
    let protein: Double
    let carbs: Double
    let fats: Double
}

struct FoodItem: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    var quantity: String

    enum CodingKeys: String, CodingKey {
        case name, quantity, item, amount
    }

    init(name: String, quantity: String) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
    }

    init(from decoder: Decoder) throws {
        // Try decoding as a simple string first
        if let container = try? decoder.singleValueContainer(),
           let stringVal = try? container.decode(String.self) {
            self.id = UUID()
            self.name = stringVal
            self.quantity = "Standard serving"
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        
        // Robust decoding for 'name'
        if let nameVal = try? container.decode(String.self, forKey: .name) {
            self.name = nameVal
        } else if let itemVal = try? container.decode(String.self, forKey: .item) {
            self.name = itemVal
        } else {
            // Fallback or throw
            throw DecodingError.keyNotFound(CodingKeys.name, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Expected 'name' or 'item' key"))
        }
        
        // Robust decoding for 'quantity'
        if let qtyVal = try? container.decode(String.self, forKey: .quantity) {
            self.quantity = qtyVal
        } else if let amountVal = try? container.decode(String.self, forKey: .amount) {
            self.quantity = amountVal
        } else {
             // Fallback default
             self.quantity = "Unknown"
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(quantity, forKey: .quantity)
    }
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
    let usedModel: GeminiModel
    let foodItems: [FoodItem]?

    var verdict: String {
        return verdictEmoji == "✅" ? "Healthy" : "Caution"
    }

    var canBeImproved: Bool {
        return usedModel == .flash
    }
}

struct FoodAnalysisResultDTO: Codable {
    let estimatedPortionSize: String
    let dishName: String
    let calories: Double
    let macros: MacroNutrients
    let verdictEmoji: String
    let briefExplanation: String
    let diabeticFriendliness: String
    let diabeticAdvice: String
    let portionSizeSuggestion: String
    let foodItems: [FoodItem]?

    func toFoodAnalysisResult(usedModel: GeminiModel) -> FoodAnalysisResult {
        return FoodAnalysisResult(
            estimatedPortionSize: estimatedPortionSize,
            dishName: dishName,
            calories: calories,
            macros: macros,
            verdictEmoji: verdictEmoji,
            briefExplanation: briefExplanation,
            diabeticFriendliness: diabeticFriendliness,
            diabeticAdvice: diabeticAdvice,
            portionSizeSuggestion: portionSizeSuggestion,
            usedModel: usedModel,
            foodItems: foodItems
        )
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
