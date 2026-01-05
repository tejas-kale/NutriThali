import Foundation

enum GeminiModel: String, Codable {
    case flash = "gemini-3-flash-preview"
    case pro = "gemini-3-pro-preview"

    var displayName: String {
        switch self {
        case .flash:
            return "Flash (Fast)"
        case .pro:
            return "Pro (Detailed)"
        }
    }
}
