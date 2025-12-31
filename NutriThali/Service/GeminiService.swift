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
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-preview:generateContent"
    
    func analyzeImage(image: PlatformImage) async throws -> FoodAnalysisResult {
        guard let apiKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !apiKey.isEmpty else {
            throw GeminiError.noAPIKey
        }
        
        // Use URLComponents to safely construct the URL
        guard var components = URLComponents(string: baseURL) else {
             throw GeminiError.invalidURL
        }
        
        // Trim whitespace and newlines from the API key
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        components.queryItems = [
            URLQueryItem(name: "key", value: cleanKey)
        ]
        
        guard let url = components.url else {
            throw GeminiError.invalidURL
        }
        
        // Get JPEG Data
        guard let imageData = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            throw GeminiError.invalidResponse // Encoding error
        }
        
        let promptText = """
        Analyze this food image in TWO STEPS:

        STEP 1 - PORTION ESTIMATION:
        Examine the image carefully and estimate the ACTUAL portion size visible in the photo. Be specific (e.g., "250g", "1.5 cups", "2 medium rotis + 150g dal + 200g rice"). Consider plate size, food density, and visible quantity.

        STEP 2 - NUTRITIONAL ANALYSIS:
        Based on the portion size you estimated in STEP 1, calculate:
        - Total calories for THIS SPECIFIC PORTION
        - Macronutrients (protein, carbs, fats in grams) for THIS SPECIFIC PORTION
        - Account for hidden calories (Ghee, Oil, Butter, Cream, Sugar)

        The dish is likely Indian (e.g., 'Thali' with Roti, Dal, Rice) but could also be international. For combo meals, list distinct components.

        Provide diabetic assessment (Type 2) considering Glycemic Index and carb load.

        Return JSON:
        {
          "estimatedPortionSize": "Your STEP 1 estimate",
          "dishName": "Name of dish",
          "calories": 0,
          "macros": { "protein": 0, "carbs": 0, "fats": 0 },
          "verdictEmoji": "✅" or "⚠️",
          "briefExplanation": "One sentence explaining the verdict.",
          "diabeticFriendliness": "High", "Moderate", or "Low",
          "diabeticAdvice": "Specific advice for diabetics",
          "portionSizeSuggestion": "Recommended portion size for health"
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
        guard let text = geminiResponse.candidates?.first?.content.parts.first?.text,
              let data = text.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }
        
        return try JSONDecoder().decode(FoodAnalysisResult.self, from: data)
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