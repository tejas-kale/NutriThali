import Foundation
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum AppState: Equatable {
    case idle
    case analyzing
    case result(FoodAnalysisResult)
    case error(String)

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.analyzing, .analyzing):
            return true
        case (.result(let lhsResult), .result(let rhsResult)):
            return lhsResult.dishName == rhsResult.dishName
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

@MainActor
class ScannerViewModel: ObservableObject {
    @Published var appState: AppState = .idle
    @Published var isLoading: Bool = false
    @Published var analysisProgress: String = ""

    private let service = GeminiService()
    private var currentTask: Task<Void, Never>?

    func analyzeImage(image: PlatformImage) {
        // Cancel any ongoing analysis
        currentTask?.cancel()

        appState = .analyzing
        isLoading = true
        analysisProgress = "Preparing image..."

        currentTask = Task {
            do {
                analysisProgress = "Sending to Gemini AI..."

                let result = try await service.analyzeImage(image: image)

                guard !Task.isCancelled else {
                    appState = .idle
                    isLoading = false
                    return
                }

                analysisProgress = "Processing results..."

                // Provide haptic feedback on success
                #if os(iOS)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                #endif

                // Small delay for smooth transition
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

                appState = .result(result)
                isLoading = false
            } catch GeminiError.noAPIKey {
                handleError("API Key Required", message: "Please add your Gemini API key in Settings to analyze food images.")
            } catch GeminiError.invalidURL {
                handleError("Configuration Error", message: "Invalid API configuration. Please check your API key in Settings.")
            } catch GeminiError.invalidResponse {
                handleError("Analysis Failed", message: "The AI couldn't analyze this image. Try a clearer photo with better lighting.")
            } catch GeminiError.apiError(let details) {
                handleError("API Error", message: "Gemini API returned an error: \(details)")
            } catch {
                handleError("Unexpected Error", message: error.localizedDescription)
            }
        }
    }

    func reset() {
        currentTask?.cancel()
        appState = .idle
        isLoading = false
        analysisProgress = ""
    }

    private func handleError(_ title: String, message: String) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif

        appState = .error(message)
        isLoading = false
        analysisProgress = ""
    }

    deinit {
        currentTask?.cancel()
    }
}
