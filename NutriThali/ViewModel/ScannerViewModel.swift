import Foundation
import SwiftUI
import Combine
import CoreData

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum AppState: Equatable {
    case idle
    case analysing
    case identified(FoodAnalysisResult) // Step 1 result
    case result(FoodAnalysisResult) // Step 2 result
    case error(String)

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.analysing, .analysing): return true
        case (.identified(let lhsR), .identified(let rhsR)): return lhsR.dishName == rhsR.dishName
        case (.result(let lhsResult), .result(let rhsResult)):
            return lhsResult.dishName == rhsResult.dishName
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default: return false
        }
    }
}

@MainActor
class ScannerViewModel: ObservableObject {
    @Published var appState: AppState = .idle
    @Published var isLoading: Bool = false
    @Published var analysisProgress: String = ""
    @Published var currentImage: PlatformImage?
    @Published var hasUsedImprove: Bool = false

    private let service = GeminiService()
    private var currentTask: Task<Void, Never>?
    private var persistenceService: PersistenceService?

    func setPersistenceContext(_ context: NSManagedObjectContext) {
        self.persistenceService = PersistenceService(context: context)
    }

    func analyseImage(image: PlatformImage) {
        currentImage = image
        currentTask?.cancel()

        appState = .analysing
        isLoading = true
        analysisProgress = "Identifying meal"

        currentTask = Task {
            do {
                // Step 1: Identification
                let result = try await service.identifyFood(image: image)

                guard !Task.isCancelled else {
                    appState = .idle
                    isLoading = false
                    return
                }

                #if os(iOS)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                #endif

                // Transition to Identified State (Pop-up)
                appState = .identified(result)
                isLoading = false
            } catch {
                handleError("Identification Failed", message: error.localizedDescription)
            }
        }
    }
    
    func confirmIdentification(result: FoodAnalysisResult) {
        currentTask?.cancel()
        
        appState = .analysing
        isLoading = true
        analysisProgress = "Analysing meal"
        
        currentTask = Task {
            do {
                // Step 2: Nutrition Analysis
                let finalResult = try await service.analyseNutrition(
                    name: result.dishName,
                    quantity: result.estimatedPortionSize
                )
                
                guard !Task.isCancelled else {
                    appState = .idle
                    isLoading = false
                    return
                }
                
                #if os(iOS)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                #endif
                
                appState = .result(finalResult)
                isLoading = false
            } catch {
                handleError("Analysis Failed", message: error.localizedDescription)
            }
        }
    }

    func updateDishName(_ name: String) {
        if case .identified(var result) = appState {
            // Create a new result with updated name
            let newResult = FoodAnalysisResult(
                estimatedPortionSize: result.estimatedPortionSize,
                dishName: name,
                calories: result.calories,
                macros: result.macros,
                verdictEmoji: result.verdictEmoji,
                briefExplanation: result.briefExplanation,
                diabeticFriendliness: result.diabeticFriendliness,
                diabeticAdvice: result.diabeticAdvice,
                portionSizeSuggestion: result.portionSizeSuggestion,
                usedModel: result.usedModel,
                foodItems: result.foodItems
            )
            appState = .identified(newResult)
        }
    }

    func updatePortions(_ items: [FoodItem]) {
        if case .identified(var result) = appState {
            // Reconstruct description string from items
            let description = items.map { "\($0.quantity) \($0.name)" }.joined(separator: ", ")
            
            let newResult = FoodAnalysisResult(
                estimatedPortionSize: description, // Update the display string
                dishName: result.dishName,
                calories: result.calories,
                macros: result.macros,
                verdictEmoji: result.verdictEmoji,
                briefExplanation: result.briefExplanation,
                diabeticFriendliness: result.diabeticFriendliness,
                diabeticAdvice: result.diabeticAdvice,
                portionSizeSuggestion: result.portionSizeSuggestion,
                usedModel: result.usedModel,
                foodItems: items // Store the structured items
            )
            appState = .identified(newResult)
        }
    }

    func recalculateFromDescription(_ description: String) async {
        // Keeps existing logic for Step 2 or explicit recalculation if needed
        currentTask?.cancel()
        appState = .analysing
        isLoading = true
        analysisProgress = "Recalculating..."
        
        currentTask = Task {
            do {
                let result = try await service.analyseFromDescription(description: description)
                appState = .result(result)
                isLoading = false
            } catch {
                handleError("Error", message: error.localizedDescription)
            }
        }
    }

    // ... rest of methods (saveMeal, improveResult, reset, handleError) ...
    
    func saveMeal(category: MealCategory) async {
        guard let image = currentImage,
              case .result(let result) = appState,
              let persistenceService = persistenceService else {
            return
        }

        do {
            try await persistenceService.saveMeal(image: image, result: result, category: category)
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
            await MainActor.run { self.reset() }
        } catch {
            handleError("Save Failed", message: "Could not save meal: \(error.localizedDescription)")
        }
    }

    func improveResult() async {
        // Logic depends on state. If in .identified, we improve identification.
        // If in .result, we improve nutrition.
        // The prompt says "buttons should be what it is now" in Step 1 popup.
        // Current improveResult uses .pro model on existing image.
        
        guard let image = currentImage else { return }
        
        // Determine context
        var currentRes: FoodAnalysisResult?
        if case .identified(let res) = appState { currentRes = res }
        else if case .result(let res) = appState { currentRes = res }
        
        guard let flashResult = currentRes else { return }

        currentTask?.cancel()
        appState = .analysing
        isLoading = true
        analysisProgress = "Enhancing analysis..."

        currentTask = Task {
            do {
                // We use the same improveWithPro service but outcome depends on usage.
                // Since `improveWithPro` returns a full result, we can likely map it to the current state type.
                // However, the prompt implies Step 1 improvement should just be identification?
                // "Show results in popup... Improve... ensure everything stays in popup".
                // So if we are in Step 1, result stays in Step 1 (.identified).
                
                let proResult = try await service.improveWithPro(image: image, flashResult: flashResult)
                
                // Decide state based on previous state
                if case .identified = self.appState {
                     self.appState = .identified(proResult)
                } else {
                     self.appState = .result(proResult)
                }
                
                hasUsedImprove = true
                isLoading = false
            } catch {
                handleError("Improvement Failed", message: error.localizedDescription)
            }
        }
    }

    func recalculateFromPortions(_ foodItems: [FoodItem]) async {
        // Similar logic: if in Step 1, update Step 1 result.
        currentTask?.cancel()
        appState = .analysing
        isLoading = true
        analysisProgress = "Recalculating portions..."
        
        currentTask = Task {
            do {
                let result = try await service.analyseFromPortions(foodItems: foodItems, originalImage: currentImage)
                 if case .identified = self.appState {
                     self.appState = .identified(result)
                } else {
                     self.appState = .result(result)
                }
                isLoading = false
            } catch {
                handleError("Error", message: error.localizedDescription)
            }
        }
    }

    func reset() {
        currentTask?.cancel()
        currentImage = nil
        appState = .idle
        isLoading = false
        analysisProgress = ""
        hasUsedImprove = false
    }

    private func handleError(_ title: String, message: String) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
        appState = .error(message)
        isLoading = false
    }

    deinit {
        currentTask?.cancel()
    }
}
