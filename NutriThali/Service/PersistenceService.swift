import Foundation
import CoreData

enum PersistenceError: Error, LocalizedError {
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    case imageCompressionFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Failed to save meal: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch meals: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete meal: \(message)"
        case .imageCompressionFailed:
            return "Failed to compress image for storage"
        }
    }
}

class PersistenceService {
    private let context: NSManagedObjectContext
    private let imageCompressionService: ImageCompressionService

    init(context: NSManagedObjectContext, imageCompressionService: ImageCompressionService = ImageCompressionService()) {
        self.context = context
        self.imageCompressionService = imageCompressionService
    }

    @MainActor
    func saveMeal(
        image: PlatformImage,
        result: FoodAnalysisResult,
        category: MealCategory
    ) async throws {
        guard let compressedImageData = imageCompressionService.compressImageForStorage(image) else {
            throw PersistenceError.imageCompressionFailed
        }

        let meal = MealEntry(context: context)
        meal.id = UUID()
        meal.timestamp = Date()
        meal.category = category.rawValue
        meal.imageData = compressedImageData

        meal.dishName = result.dishName
        meal.calories = result.calories
        meal.proteinGrams = result.macros.protein
        meal.carbsGrams = result.macros.carbs
        meal.fatsGrams = result.macros.fats
        meal.verdictEmoji = result.verdictEmoji
        meal.briefExplanation = result.briefExplanation
        meal.diabeticFriendliness = result.diabeticFriendliness
        meal.diabeticAdvice = result.diabeticAdvice
        meal.portionSizeSuggestion = result.portionSizeSuggestion
        meal.estimatedPortionSize = result.estimatedPortionSize

        do {
            try context.save()
        } catch {
            throw PersistenceError.saveFailed(error.localizedDescription)
        }
    }

    func fetchMealsForDay(_ date: Date) -> [MealEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let request: NSFetchRequest<MealEntry> = MealEntry.fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealEntry.timestamp, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch meals for day: \(error.localizedDescription)")
            return []
        }
    }

    func fetchMealsForDateRange(start: Date, end: Date) -> [MealEntry] {
        let request: NSFetchRequest<MealEntry> = MealEntry.fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            start as NSDate,
            end as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealEntry.timestamp, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch meals for date range: \(error.localizedDescription)")
            return []
        }
    }

    func fetchDaysWithMeals(month: Int, year: Int) -> [Date] {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let startOfMonth = Calendar.current.date(from: components),
              let endOfMonth = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }

        let request: NSFetchRequest<MealEntry> = MealEntry.fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            startOfMonth as NSDate,
            endOfMonth as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealEntry.timestamp, ascending: true)]

        do {
            let meals = try context.fetch(request)
            let calendar = Calendar.current
            let uniqueDays = Set(meals.compactMap { meal -> Date? in
                guard let timestamp = meal.timestamp else { return nil }
                return calendar.startOfDay(for: timestamp)
            })
            return Array(uniqueDays).sorted()
        } catch {
            print("Failed to fetch days with meals: \(error.localizedDescription)")
            return []
        }
    }

    @MainActor
    func deleteMeal(_ meal: MealEntry) throws {
        context.delete(meal)

        do {
            try context.save()
        } catch {
            throw PersistenceError.deleteFailed(error.localizedDescription)
        }
    }

    @MainActor
    func updateMealCategory(_ meal: MealEntry, newCategory: MealCategory) throws {
        meal.category = newCategory.rawValue

        do {
            try context.save()
        } catch {
            throw PersistenceError.saveFailed(error.localizedDescription)
        }
    }
}
