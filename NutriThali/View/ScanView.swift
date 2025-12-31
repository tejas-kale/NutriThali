import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct ScanView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("gemini_api_key") private var apiKey: String = ""
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var selectedImage: PlatformImage?
    @State private var showFileImporter = false
    @State private var showPermissionAlert = false
    @State private var todaysMeals: [MealEntry] = []
    @State private var selectedMeal: MealEntry?
    @State private var showMealDetail = false

    private var persistenceService: PersistenceService {
        PersistenceService(context: viewContext)
    }

    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.appState {
                case .idle:
                    idleView
                case .analyzing:
                    analyzingView
                case .result(let result):
                    ResultView(result: result, onReset: viewModel.reset, viewModel: viewModel)
                case .error(let msg):
                    errorView(msg: msg)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.setPersistenceContext(viewContext)
                fetchTodaysMeals()
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let image = newValue {
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    #endif
                    viewModel.analyzeImage(image: image)
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showCamera) {
                ImagePicker(
                    selectedImage: $selectedImage,
                    isPresented: $showCamera,
                    sourceType: .camera,
                    onPermissionDenied: {
                        showPermissionAlert = true
                    }
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(
                    selectedImage: $selectedImage,
                    isPresented: $showImagePicker,
                    sourceType: .photoLibrary
                )
            }
            #endif
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image]) { result in
                switch result {
                case .success(let url):
                    #if os(macOS)
                    if let image = NSImage(contentsOf: url) {
                        selectedImage = image
                    }
                    #endif
                case .failure(let error):
                    viewModel.appState = .error("Failed to import image: \(error.localizedDescription)")
                }
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
            } message: {
                Text("NutriThali needs access to your camera to analyze food images. Please enable camera access in Settings.")
            }
            .sheet(isPresented: $showMealDetail) {
                if let meal = selectedMeal {
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
            }
        }
    }
    
    var idleView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Date
                VStack(spacing: 4) {
                    Text(currentDateString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Onboarding/Help Section (only if API key not set)
                if apiKey.isEmpty {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)

                            Text("Setup Required")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Spacer()
                        }

                        Text("To get started, add your Google Gemini API key in Settings tab. This enables AI-powered food analysis with detailed nutritional information and diabetic-friendly guidance.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }

                // Action Buttons - Side by Side
                #if os(iOS)
                HStack(spacing: 12) {
                    Button {
                        showCamera = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.title2)

                            Text("Take Photo")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Take photo of food")
                    .accessibilityHint("Opens camera to capture a meal for analysis")
                    .disabled(apiKey.isEmpty)

                    Button {
                        showImagePicker = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.fill")
                                .font(.title2)

                            Text("Choose from Library")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Choose photo from library")
                    .accessibilityHint("Opens photo library to select a meal image for analysis")
                    .disabled(apiKey.isEmpty)
                }
                .padding(.horizontal, 16)
                #else
                Button {
                    showFileImporter = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.fill")
                            .font(.title3)

                        Text("Select Food Image")
                            .font(.headline)

                        Spacer()
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(apiKey.isEmpty)
                .padding(.horizontal, 16)
                #endif

                // Today's Meals Section
                if !todaysMeals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Meals")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)

                        ForEach(todaysMeals, id: \.id) { meal in
                            Button {
                                selectedMeal = meal
                                showMealDetail = true
                            } label: {
                                TodayMealRow(meal: meal)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 8)
                }

                Spacer(minLength: 32)
            }
            .padding(.bottom, 16)
        }
    }
    
    var analyzingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)
                .tint(.accentColor)

            VStack(spacing: 8) {
                Text("Analyzing Your Meal")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("Using AI to identify nutrients and health insights")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Analyzing meal, please wait")
    }

    func errorView(msg: String) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Analysis Failed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(msg)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    #if os(iOS)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    #endif
                    viewModel.reset()
                } label: {
                    Text("Try Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 32)
                .accessibilityLabel("Try analyzing another meal")
            }
            .padding()
        }
    }

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
            todaysMeals = []
        }
    }

    private func deleteMeal(_ meal: MealEntry) {
        do {
            try persistenceService.deleteMeal(meal)
            fetchTodaysMeals()
            showMealDetail = false
            selectedMeal = nil
        } catch {
            print("Failed to delete meal: \(error)")
        }
    }

    private func updateMealCategory(_ meal: MealEntry, newCategory: MealCategory) {
        do {
            try persistenceService.updateMealCategory(meal, newCategory: newCategory)
            fetchTodaysMeals()
        } catch {
            print("Failed to update meal category: \(error)")
        }
    }
}

// MARK: - Helper Views

struct TodayMealRow: View {
    let meal: MealEntry

    var timeString: String {
        guard let timestamp = meal.timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageData = meal.imageData {
                #if os(iOS)
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                #endif
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.dishName ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(meal.calories))")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemBackground))
        #elseif os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

