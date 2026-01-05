import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: HistoryViewModel
    @State private var selectedMeal: MealEntry?

    init() {
        let tempContext = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: HistoryViewModel(
            persistenceService: PersistenceService(context: tempContext)
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Calendar Card
                        VStack {
                            CalendarView(
                                selectedDate: $viewModel.selectedDate,
                                displayedMonth: $viewModel.displayedMonth,
                                daysWithMeals: viewModel.daysWithMeals,
                                onPreviousMonth: viewModel.previousMonth,
                                onNextMonth: viewModel.nextMonth
                            )
                        }
                        .padding(16)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Shapes.cardCornerRadius))
                        .padding(.horizontal)
                        
                        // History List
                        if viewModel.mealsForSelectedDay.isEmpty {
                            Text("No history for this day")
                                .font(Theme.Typography.roundedFont(.body))
                                .foregroundStyle(.gray)
                                .padding(.top, 20)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.mealsForSelectedDay, id: \.id) { meal in
                                    MealRowView(meal: meal) // Reusing the row from TodayView
                                        .onTapGesture {
                                            selectedMeal = meal
                                        }
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $selectedMeal) { meal in
                MealDetailView(
                    meal: meal,
                    onDelete: {
                        withAnimation { viewModel.deleteMeal(meal) }
                    },
                    onUpdateCategory: { newCategory in
                        withAnimation { viewModel.updateMealCategory(meal, newCategory: newCategory) }
                    }
                )
            }
            .onAppear {
                viewModel.loadData()
            }
            .onChange(of: viewModel.selectedDate) { _, _ in
                viewModel.fetchMealsForSelectedDay()
            }
            .onChange(of: viewModel.displayedMonth) { _, _ in
                viewModel.fetchMealsForMonth(viewModel.displayedMonth)
            }
        }
    }
}