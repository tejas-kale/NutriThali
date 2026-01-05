import Foundation
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

enum GeminiError: Error, LocalizedError {
    case invalidURL
    case noAPIKey
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL. Please check your API Key."
        case .noAPIKey:
            return "API Key is missing. Please add it in Settings."
        case .invalidResponse:
            return "Received invalid response from the server."
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

class GeminiService {
    private let session = URLSession.shared

    private func buildURL(for model: GeminiModel) -> String {
        return "https://generativelanguage.googleapis.com/v1beta/models/\(model.rawValue):generateContent"
    }

    private func cleanAndDecodeJSON<T: Decodable>(_ text: String, type: T.Type) throws -> T {
        var jsonString = text
        
        // Robust markdown stripping
        if let range = jsonString.range(of: "```json", options: .caseInsensitive),
           let endRange = jsonString.range(of: "```", options: .backwards),
           endRange.lowerBound > range.upperBound {
            jsonString = String(jsonString[range.upperBound..<endRange.lowerBound])
        } else if let range = jsonString.range(of: "```", options: .literal),
                  let endRange = jsonString.range(of: "```", options: .backwards),
                  endRange.lowerBound > range.upperBound {
             // Fallback for just ``` or ```JSON
             jsonString = String(jsonString[range.upperBound..<endRange.lowerBound])
        }
        
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove any leading non-JSON characters if they exist (rare edge case)
        if let firstBrace = jsonString.firstIndex(of: "{"), firstBrace != jsonString.startIndex {
            jsonString = String(jsonString[firstBrace...])
        }
        if let lastBrace = jsonString.lastIndex(of: "}"), lastBrace != jsonString.index(before: jsonString.endIndex) {
            jsonString = String(jsonString[...lastBrace])
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            print("❌ Failed to convert cleaned string to data: \(jsonString)")
            throw GeminiError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            print("❌ JSON Decoding Failed!")
            print("Error: \(error)")
            print("Raw String was: \(text)")
            print("Cleaned JSON String was: \(jsonString)")
            throw GeminiError.invalidResponse
        }
    }

    func identifyFood(image: PlatformImage, model: GeminiModel = .flash) async throws -> FoodAnalysisResult {
        guard let apiKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !apiKey.isEmpty else {
            throw GeminiError.noAPIKey
        }

        let baseURL = buildURL(for: model)

        guard var components = URLComponents(string: baseURL) else {
             throw GeminiError.invalidURL
        }
        
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        components.queryItems = [URLQueryItem(name: "key", value: cleanKey)]
        
        guard let url = components.url else {
            throw GeminiError.invalidURL
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            throw GeminiError.invalidResponse
        }
        
        let promptText = """
        Analyse this food image to identify the dish and estimate the portion size.

        Return JSON in this exact format:
        {
          "estimatedPortionSize": "Estimated portion (e.g., 250g, 1.5 cups)",
          "dishName": "Name of the dish",
          "calories": 0,
          "macros": { "protein": 0, "carbs": 0, "fats": 0 },
          "verdictEmoji": "✅",
          "briefExplanation": "Initial identification.",
          "diabeticFriendliness": "Moderate",
          "diabeticAdvice": "Pending analysis...",
          "portionSizeSuggestion": "Pending analysis...",
          "foodItems": [
            { "name": "Item name", "quantity": "amount" }
          ]
        }
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": promptText],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": imageData
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json"
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw GeminiError.apiError(errorMsg)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates?.first?.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }
        
        let dto = try cleanAndDecodeJSON(text, type: FoodAnalysisResultDTO.self)
        return dto.toFoodAnalysisResult(usedModel: model)
    }

    func analyseNutrition(name: String, quantity: String, model: GeminiModel = .flash) async throws -> FoodAnalysisResult {
        guard let apiKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !apiKey.isEmpty else {
            throw GeminiError.noAPIKey
        }

        let baseURL = buildURL(for: model)
        guard var components = URLComponents(string: baseURL) else { throw GeminiError.invalidURL }
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        components.queryItems = [URLQueryItem(name: "key", value: cleanKey)]
        guard let url = components.url else { throw GeminiError.invalidURL }

        let promptText = """
        Compute detailed nutritional information for:
        Dish: "\(name)"
        Quantity: "\(quantity)"

        Use Google Search to retrieve and verify accurate data. Rely on well-respected and credible sources such as:
        - USDA FoodData Central (fdc.nal.usda.gov)
        - Healthline (healthline.com)
        - Mayo Clinic (mayoclinic.org)
        - WebMD (webmd.com)
        - American Diabetes Association (diabetes.org)
        - CDC (cdc.gov)
        - MyFoodData (myfooddata.com)

        1. Calculate precise CALORIES and MACROS (Protein, Carbs, Fats) for this specific quantity.
        2. Provide DIABETES CARE information (Glycemic Index, Glycemic Load, and specific advice) based on the reputable sources listed above.
        
        Return JSON in this exact format:
        {
          "estimatedPortionSize": "\(quantity)",
          "dishName": "\(name)",
          "calories": 0,
          "macros": { "protein": 0, "carbs": 0, "fats": 0 },
          "verdictEmoji": "✅" or "⚠️",
          "briefExplanation": "Health verdict.",
          "diabeticFriendliness": "High", "Moderate", or "Low",
          "diabeticAdvice": "Specific advice based on respected sources.",
          "portionSizeSuggestion": "Recommended portion size.",
          "foodItems": []
        }
        """
        
        let requestBody: [String: Any] = [
            "contents": [["parts": [["text": promptText]]]],
            "generationConfig": ["response_mime_type": "application/json"]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw GeminiError.apiError(errorMsg)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates?.first?.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }
        
        let dto = try cleanAndDecodeJSON(text, type: FoodAnalysisResultDTO.self)
        return dto.toFoodAnalysisResult(usedModel: model)
    }

    func analyseImage(image: PlatformImage, model: GeminiModel = .flash) async throws -> FoodAnalysisResult {
        // Fallback or deprecated if flow changes, but keeping for compatibility if needed.
        // For the new flow, we use identifyFood -> analyseNutrition.
        return try await identifyFood(image: image, model: model)
    }


    func analyseFromDescription(description: String, model: GeminiModel = .flash) async throws -> FoodAnalysisResult {
        guard let apiKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !apiKey.isEmpty else {
            throw GeminiError.noAPIKey
        }

        let baseURL = buildURL(for: model)

        guard var components = URLComponents(string: baseURL) else {
             throw GeminiError.invalidURL
        }

        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        components.queryItems = [
            URLQueryItem(name: "key", value: cleanKey)
        ]

        guard let url = components.url else {
            throw GeminiError.invalidURL
        }

        let promptText = """
        Based on this food description: "\(description)"

        Provide detailed nutritional analysis:

        1. PORTION ESTIMATION: Estimate the portion size based on the description (e.g., "250g", "1.5 cups", "2 medium rotis + 150g dal + 200g rice")

        2. NUTRITIONAL ANALYSIS: Calculate for the described portion:
        - Total calories
        - Macronutrients (protein, carbs, fats in grams)
        - Account for hidden calories (Ghee, Oil, Butter, Cream, Sugar)

        3. HEALTH ASSESSMENT: Provide overall health verdict and diabetic assessment (Type 2) considering Glycemic Index and carb load.

        Return JSON:
        {
          "estimatedPortionSize": "Estimated portion from description",
          "dishName": "Name of dish/meal",
          "calories": 0,
          "macros": { "protein": 0, "carbs": 0, "fats": 0 },
          "verdictEmoji": "✅" or "⚠️",
          "briefExplanation": "One sentence explaining the verdict.",
          "diabeticFriendliness": "High", "Moderate", or "Low",
          "diabeticAdvice": "Specific advice for diabetics",
          "portionSizeSuggestion": "Recommended portion size for health",
          "foodItems": [
            { "name": "Item name", "quantity": "amount" }
          ]
        }
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": promptText]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json"
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw GeminiError.apiError(errorMsg)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates?.first?.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }
        
        let dto = try cleanAndDecodeJSON(text, type: FoodAnalysisResultDTO.self)
        return dto.toFoodAnalysisResult(usedModel: model)
    }

    func improveWithPro(image: PlatformImage, flashResult: FoodAnalysisResult) async throws -> FoodAnalysisResult {
        guard let apiKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !apiKey.isEmpty else {
            throw GeminiError.noAPIKey
        }

        let baseURL = buildURL(for: .pro)

        guard var components = URLComponents(string: baseURL) else {
            throw GeminiError.invalidURL
        }

        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        components.queryItems = [URLQueryItem(name: "key", value: cleanKey)]

        guard let url = components.url else {
            throw GeminiError.invalidURL
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            throw GeminiError.invalidResponse
        }

        let promptText = """
        CONTEXT: A previous analysis using Gemini Flash provided this assessment:
        - Dish Name: \(flashResult.dishName)
        - Estimated Portion: \(flashResult.estimatedPortionSize)
        - Calories: \(Int(flashResult.calories)) kcal
        - Protein: \(Int(flashResult.macros.protein))g, Carbs: \(Int(flashResult.macros.carbs))g, Fats: \(Int(flashResult.macros.fats))g
        - Diabetic Friendliness: \(flashResult.diabeticFriendliness)

        YOUR TASK: Using the image provided, give a MORE ACCURATE and DETAILED analysis.

        1. VERIFY the Flash assessment - correct any obvious errors in dish identification or portion estimation
        2. Provide MORE PRECISE portion estimation (use exact measurements like grams or specific units)
        3. Calculate MORE ACCURATE nutritional values (account for cooking methods, hidden ingredients like oil/ghee/butter)
        4. Give ENHANCED diabetic guidance (consider glycemic load, insulin response, and meal timing recommendations)

        Be thorough and leverage your advanced reasoning to improve upon the initial analysis.

        Return JSON in this exact format:
        {
          "estimatedPortionSize": "Precise portion estimate",
          "dishName": "Refined dish name",
          "calories": 0,
          "macros": { "protein": 0, "carbs": 0, "fats": 0 },
          "verdictEmoji": "✅" or "⚠️",
          "briefExplanation": "Enhanced explanation",
          "diabeticFriendliness": "High", "Moderate", or "Low",
          "diabeticAdvice": "Detailed diabetic advice with specific recommendations",
          "portionSizeSuggestion": "Recommended portion for diabetic patients",
          "foodItems": [
            { "name": "Item name", "quantity": "precise amount" }
          ]
        }
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": promptText],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": imageData
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "response_mime_type": "application/json"
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw GeminiError.apiError(errorMsg)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates?.first?.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }
        
        let dto = try cleanAndDecodeJSON(text, type: FoodAnalysisResultDTO.self)
        return dto.toFoodAnalysisResult(usedModel: .pro)
    }

    func analyseFromPortions(foodItems: [FoodItem], originalImage: PlatformImage?) async throws -> FoodAnalysisResult {
        guard let apiKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !apiKey.isEmpty else {
            throw GeminiError.noAPIKey
        }

        let baseURL = buildURL(for: .flash)

        guard var components = URLComponents(string: baseURL) else {
            throw GeminiError.invalidURL
        }

        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        components.queryItems = [URLQueryItem(name: "key", value: cleanKey)]

        guard let url = components.url else {
            throw GeminiError.invalidURL
        }

        let portionsDescription = foodItems.map { "\($0.quantity) \($0.name)" }.joined(separator: ", ")

        let foodItemsJSON = foodItems.map { item in
            "{ \"name\": \"\(item.name)\", \"quantity\": \"\(item.quantity)\" }"
        }.joined(separator: ",\n  ")

        let promptText = """
        Calculate nutritional information for this meal with these SPECIFIC portions:
        \(portionsDescription)

        Provide detailed nutritional analysis:
        1. Total calories for these EXACT portions (account for typical cooking methods and hidden calories)
        2. Macronutrients (protein, carbs, fats in grams) for these EXACT portions
        3. Overall health verdict based on nutritional balance
        4. Diabetic assessment considering total carb load and glycemic index

        Return JSON in this exact format:
        {
          "estimatedPortionSize": "\(portionsDescription)",
          "dishName": "Name of the meal/combination",
          "calories": 0,
          "macros": { "protein": 0, "carbs": 0, "fats": 0 },
          "verdictEmoji": "✅" or "⚠️",
          "briefExplanation": "One sentence health assessment",
          "diabeticFriendliness": "High", "Moderate", or "Low",
          "diabeticAdvice": "Specific advice for diabetic patients",
          "portionSizeSuggestion": "Recommended portion adjustment if needed",
          "foodItems": [
            \(foodItemsJSON)
          ]
        }
        """

        var parts: [[String: Any]] = [["text": promptText]]

        if let image = originalImage,
           let imageData = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() {
            parts.append([
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": imageData
                ]
            ])
        }

        let requestBody: [String: Any] = [
            "contents": [
                ["parts": parts]
            ],
            "generationConfig": [
                "response_mime_type": "application/json"
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw GeminiError.apiError(errorMsg)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates?.first?.content.parts.first?.text else {
            throw GeminiError.invalidResponse
        }
        
        let dto = try cleanAndDecodeJSON(text, type: FoodAnalysisResultDTO.self)
        return dto.toFoodAnalysisResult(usedModel: .flash)
    }
}

#if canImport(AppKit)
extension PlatformImage {
    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}
#endif