import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: HistoryViewModel
    @State private var selectedMeal: MealEntry?

    init() {
        // Initialize with a temporary context, will be set properly in onAppear
        let tempContext = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: HistoryViewModel(
            persistenceService: PersistenceService(context: tempContext)
        ))
    }

    var groupedMeals: [MealCategory: [MealEntry]] {
        Dictionary(grouping: viewModel.mealsForSelectedDay) { meal in
            MealCategory(rawValue: meal.category ?? "") ?? .snacks
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Calendar
                    CalendarView(
                        selectedDate: $viewModel.selectedDate,
                        displayedMonth: $viewModel.displayedMonth,
                        daysWithMeals: viewModel.daysWithMeals,
                        onPreviousMonth: viewModel.previousMonth,
                        onNextMonth: viewModel.nextMonth
                    )
                    .padding(.horizontal, 16)
                    .onChange(of: viewModel.selectedDate) { _, _ in
                        viewModel.fetchMealsForSelectedDay()
                    }

                    // Daily Summary (only if there are meals)
                    if !viewModel.mealsForSelectedDay.isEmpty {
                        DailySummaryView(
                            totalCalories: viewModel.totalCalories,
                            totalProtein: viewModel.totalProtein,
                            totalCarbs: viewModel.totalCarbs,
                            totalFats: viewModel.totalFats,
                            mealCount: viewModel.mealsForSelectedDay.count
                        )
                        .padding(.horizontal, 16)
                    }

                    // Meal List
                    if viewModel.mealsForSelectedDay.isEmpty {
                        emptyStateView
                            .padding(.top, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Meals")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)

                            // Group meals by category
                            ForEach(MealCategory.allCases, id: \.self) { category in
                                if let meals = groupedMeals[category], !meals.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 8) {
                                            Image(systemName: category.icon)
                                                .font(.subheadline)
                                                .foregroundStyle(category.color)

                                            Text(category.rawValue)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.horizontal, 16)

                                        ForEach(meals, id: \.id) { meal in
                                            MealCardView(meal: meal)
                                                .padding(.horizontal, 16)
                                                .onTapGesture {
                                                    selectedMeal = meal
                                                }
                                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                    Button(role: .destructive) {
                                                        deleteMeal(meal)
                                                    } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedMeal) { meal in
                MealDetailView(
                    meal: meal,
                    onDelete: {
                        deleteMeal(meal)
                    },
                    onUpdateCategory: { newCategory in
                        updateCategory(meal, newCategory: newCategory)
                    }
                )
            }
            .onAppear {
                // Update viewModel with proper context
                viewModel.loadData()
            }
            .onChange(of: viewModel.displayedMonth) { _, _ in
                viewModel.fetchMealsForMonth(viewModel.displayedMonth)
            }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("No meals logged")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Meals you analyze and save will appear here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No meals logged. Meals you analyze and save will appear here")
    }

    func deleteMeal(_ meal: MealEntry) {
        withAnimation {
            viewModel.deleteMeal(meal)
        }

        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    func updateCategory(_ meal: MealEntry, newCategory: MealCategory) {
        withAnimation {
            viewModel.updateMealCategory(meal, newCategory: newCategory)
        }

        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
