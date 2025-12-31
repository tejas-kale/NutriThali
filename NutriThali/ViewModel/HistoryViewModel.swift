import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var mealsForSelectedDay: [MealEntry] = []
    @Published var daysWithMeals: Set<DateComponents> = []
    @Published var displayedMonth: Date = Date()

    private let persistenceService: PersistenceService
    private let calendar = Calendar.current

    init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
    }

    func loadData() {
        fetchMealsForMonth(displayedMonth)
        fetchMealsForSelectedDay()
    }

    func fetchMealsForMonth(_ month: Date) {
        let monthComponent = calendar.component(.month, from: month)
        let yearComponent = calendar.component(.year, from: month)

        let days = persistenceService.fetchDaysWithMeals(month: monthComponent, year: yearComponent)
        daysWithMeals = Set(days.map {
            calendar.dateComponents([.year, .month, .day], from: $0)
        })
    }

    func fetchMealsForSelectedDay() {
        mealsForSelectedDay = persistenceService.fetchMealsForDay(selectedDate)
            .sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
    }

    func deleteMeal(_ meal: MealEntry) {
        do {
            try persistenceService.deleteMeal(meal)
            fetchMealsForSelectedDay()
            fetchMealsForMonth(displayedMonth)
        } catch {
            print("Failed to delete meal: \(error.localizedDescription)")
        }
    }

    func updateMealCategory(_ meal: MealEntry, newCategory: MealCategory) {
        do {
            try persistenceService.updateMealCategory(meal, newCategory: newCategory)
            fetchMealsForSelectedDay()
        } catch {
            print("Failed to update category: \(error.localizedDescription)")
        }
    }

    func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
            fetchMealsForMonth(newMonth)
        }
    }

    func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
            fetchMealsForMonth(newMonth)
        }
    }

    var totalCalories: Double {
        mealsForSelectedDay.reduce(0) { $0 + $1.calories }
    }

    var totalProtein: Double {
        mealsForSelectedDay.reduce(0) { $0 + $1.proteinGrams }
    }

    var totalCarbs: Double {
        mealsForSelectedDay.reduce(0) { $0 + $1.carbsGrams }
    }

    var totalFats: Double {
        mealsForSelectedDay.reduce(0) { $0 + $1.fatsGrams }
    }
}
