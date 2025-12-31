import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @AppStorage("gemini_api_key") private var apiKey: String = ""
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding: Bool = false
    @State private var showSettings = false
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var selectedImage: PlatformImage?
    @State private var showFileImporter = false
    @State private var showPermissionAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.appState {
                case .idle:
                    idleView
                case .analyzing:
                    analyzingView
                case .result(let result):
                    ResultView(result: result, onReset: viewModel.reset)
                case .error(let msg):
                    errorView(msg: msg)
                }
            }
            .navigationTitle("NutriThali")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Open app settings and configure API key")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
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
        }
    }
    
    var idleView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero Section
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green.gradient)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("AI Food Analysis")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("Get instant nutrition insights for any meal")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 32)

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

                        Text("To get started, add your Google Gemini API key in Settings. This enables AI-powered food analysis with detailed nutritional information and diabetic-friendly guidance.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)

                        Button {
                            showSettings = true
                        } label: {
                            Text("Open Settings")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        .controlSize(.regular)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }

                // Action Buttons
                VStack(spacing: 16) {
                    #if os(iOS)
                    Button {
                        showCamera = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Take Photo")
                                    .font(.headline)

                                Text("Capture your meal with the camera")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                        HStack(spacing: 12) {
                            Image(systemName: "photo.fill")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Choose from Library")
                                    .font(.headline)

                                Text("Select an existing photo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Choose photo from library")
                    .accessibilityHint("Opens photo library to select a meal image for analysis")
                    .disabled(apiKey.isEmpty)
                    #else
                    Button {
                        showFileImporter = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.fill")
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Select Food Image")
                                    .font(.headline)

                                Text("Choose an image to analyze")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(apiKey.isEmpty)
                    #endif
                }
                .padding(.horizontal, 16)

                // Features List
                VStack(alignment: .leading, spacing: 16) {
                    Text("What You'll Get")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    FeatureRow(icon: "chart.pie.fill", title: "Nutritional Breakdown", description: "Calories, protein, carbs, and fats")
                    FeatureRow(icon: "heart.text.square.fill", title: "Health Verdict", description: "Overall meal healthiness assessment")
                    FeatureRow(icon: "waveform.path.ecg", title: "Diabetes Care", description: "Glycemic index and diabetic advice")
                    FeatureRow(icon: "scalemass.fill", title: "Portion Guidance", description: "Recommended serving sizes")
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

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
}

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

