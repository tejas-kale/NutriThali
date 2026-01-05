import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct TodayView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("gemini_api_key") private var apiKey: String = ""
    
    @State private var todaysMeals: [MealEntry] = []
    @State private var showScanningSheet = false
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var selectedImage: PlatformImage?
    @State private var showPermissionAlert = false
    @State private var selectedMeal: MealEntry?
    @State private var showError = false
    @State private var errorMessage = ""

    // Date Formatter
    private var dateHeaderString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Today, \(formatter.string(from: Date()))"
    }

    // Calculated Macros
    private var totalCalories: Double { todaysMeals.reduce(0.0) { $0 + $1.calories } }
    private var totalProtein: Double { todaysMeals.reduce(0.0) { $0 + $1.proteinGrams } }
    private var totalCarbs: Double { todaysMeals.reduce(0.0) { $0 + $1.carbsGrams } }
    private var totalFats: Double { todaysMeals.reduce(0.0) { $0 + $1.fatsGrams } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if case .analysing = viewModel.appState {
                    analysingView
                } else if case .identified(let result) = viewModel.appState {
                    // Step 1: Identification Pop-up
                    IdentificationView(
                        result: result,
                        onConfirm: {
                            viewModel.confirmIdentification(result: result)
                        },
                        onCancel: {
                            viewModel.reset()
                        },
                        viewModel: viewModel
                    )
                    .transition(.move(edge: .bottom))
                } else if case .result(let result) = viewModel.appState {
                    // Step 2: Final Result
                    ResultView(result: result, onReset: {
                        viewModel.reset()
                        fetchTodaysMeals()
                    }, viewModel: viewModel)
                    .transition(.opacity)
                } else {
                    // Main Dashboard
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            HStack {
                                Text(dateHeaderString)
                                    .font(Theme.Typography.roundedFont(.largeTitle, weight: .bold))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // Summary Card
                            summaryCard
                                .padding(.horizontal)
                            
                            // Meal Timeline
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Timeline")
                                    .font(Theme.Typography.roundedFont(.title3, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal)
                                
                                if todaysMeals.isEmpty {
                                    emptyStateView
                                } else {
                                    LazyVStack(spacing: 16) {
                                        ForEach(todaysMeals, id: \.id) { meal in
                                            MealRowView(meal: meal)
                                                .onTapGesture {
                                                    selectedMeal = meal
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            Spacer(minLength: 100) // Space for FAB and TabBar
                        }
                    }
                    
                    // FAB
                    VStack {
                        Spacer()
                        Button {
                            showScanningSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                Text("Scan Meal")
                            }
                            .font(Theme.Typography.roundedFont(.headline, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Theme.primary)
                            .clipShape(Capsule())
                            .shadow(color: Theme.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.bottom, 90) // Above Tab Bar
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.setPersistenceContext(viewContext)
                fetchTodaysMeals()
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let image = newValue {
                    viewModel.analyseImage(image: image)
                }
            }
            .confirmationDialog("Add Meal", isPresented: $showScanningSheet) {
                Button("Take Photo") { showCamera = true }
                Button("Choose from Library") { showImagePicker = true }
                Button("Cancel", role: .cancel) { }
            }
            #if os(iOS)
            .sheet(isPresented: $showCamera) {
                ImagePicker(selectedImage: $selectedImage, isPresented: $showCamera, sourceType: .camera, onPermissionDenied: { showPermissionAlert = true })
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, isPresented: $showImagePicker, sourceType: .photoLibrary)
            }
            #endif
            .sheet(item: $selectedMeal) { meal in
                MealDetailView(
                    meal: meal,
                    onDelete: {
                        deleteMeal(meal)
                    },
                    onUpdateCategory: { newCategory in
                        updateMealCategory(meal, newCategory: newCategory)
                    }
                )
            }
            .alert("Camera Permission Required", isPresented: $showPermissionAlert) {
                Button("Open Settings", role: .none) {
                    #if os(iOS)
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    #endif
                }
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: viewModel.appState) { oldValue, newValue in
                if case .error(let message) = newValue {
                    errorMessage = message
                    showError = true
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    viewModel.reset()
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    var summaryCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Calories Remaining")
                        .font(Theme.Typography.roundedFont(.subheadline, weight: .medium))
                        .foregroundStyle(.gray)
                    
                    // Assuming 2000 target for now, can be a setting later
                    let target = 2000.0
                    let remaining = max(0, target - totalCalories)
                    
                    Text("\(Int(remaining))")
                        .font(Theme.Typography.roundedFont(size: 40, weight: .bold))
                        .foregroundStyle(Theme.primary)
                }
                Spacer()
                // Simple Progress Ring for Calories could go here, or just text
            }
            
            HStack(spacing: 30) {
                macroRing(title: "Protein", value: totalProtein, colour: .green)
                macroRing(title: "Carbs", value: totalCarbs, colour: .blue)
                macroRing(title: "Fat", value: totalFats, colour: .orange)
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Shapes.cardCornerRadius))
    }
    
    func macroRing(title: String, value: Double, colour: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(colour.opacity(0.2), lineWidth: 6)
                    .frame(width: 50, height: 50)
                
                // Indeterminate max for now, scaling visual roughly
                Circle()
                    .trim(from: 0, to: min(value / 100.0, 1.0)) // Assuming 100g max for visual
                    .stroke(colour, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(value))g")
                    .font(Theme.Typography.roundedFont(.caption, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Text(title)
                .font(Theme.Typography.roundedFont(.caption2))
                .foregroundStyle(.gray)
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.gray.opacity(0.5))
            
            Text("No meals logged yet.")
                .font(Theme.Typography.roundedFont(.body))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    var analysingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.primary)
            
            Text(viewModel.analysisProgress)
                .font(Theme.Typography.roundedFont(.title3, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.opacity(0.9))
    }
    
    // MARK: - Helpers
    
    private func fetchTodaysMeals() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let fetchRequest: NSFetchRequest<MealEntry> = MealEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            todaysMeals = try viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch today's meals: \(error)")
        }
    }
    
    private func deleteMeal(_ meal: MealEntry) {
        viewContext.delete(meal)
        do {
            try viewContext.save()
            fetchTodaysMeals()
            selectedMeal = nil
        } catch {
            print("Delete error: \(error)")
        }
    }
    
    private func updateMealCategory(_ meal: MealEntry, newCategory: MealCategory) {
        meal.category = newCategory.rawValue
        do {
            try viewContext.save()
            fetchTodaysMeals()
        } catch {
            print("Update error: \(error)")
        }
    }
}

// Custom Row for Today View
struct MealRowView: View {
    let meal: MealEntry
    
    var body: some View {
        HStack(spacing: 16) {
            if let data = meal.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.dishName ?? "Unknown")
                    .font(Theme.Typography.roundedFont(.headline, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text("\(Int(meal.calories)) kcal")
                    .font(Theme.Typography.roundedFont(.subheadline))
                    .foregroundStyle(Theme.secondary)
            }
            
            Spacer()
            
            if let cat = meal.category, let category = MealCategory(rawValue: cat) {
                Image(systemName: category.icon)
                    .foregroundStyle(.gray)
            }
        }
        .padding(12)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Shapes.cardCornerRadius))
    }
}
