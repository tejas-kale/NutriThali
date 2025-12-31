import SwiftUI

struct SettingsView: View {
    @AppStorage("gemini_api_key") private var apiKey: String = ""
    @Environment(\.dismiss) var dismiss
    @State private var showValidation = false
    @State private var isKeyValid = false
    @FocusState private var isKeyFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Google Gemini API Key", systemImage: "key.fill")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)

                        Text("Enter your API key to enable AI-powered food analysis")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        SecureField("API Key", text: $apiKey, prompt: Text("Required"))
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isKeyFieldFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                validateKey()
                            }
                            .padding(.vertical, 8)
                            #if os(iOS)
                            .font(.body)
                            #endif
                            .accessibilityLabel("Gemini API Key")
                            .accessibilityHint("Enter your Google Gemini API key")

                        if showValidation {
                            HStack(spacing: 8) {
                                Image(systemName: isKeyValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundStyle(isKeyValid ? .green : .orange)
                                    .accessibilityHidden(true)

                                Text(isKeyValid ? "API key saved" : "Please enter a valid API key")
                                    .font(.caption)
                                    .foregroundStyle(isKeyValid ? .green : .orange)
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    Link(destination: URL(string: "https://makersuite.google.com/app/apikey")!) {
                        HStack {
                            Label("Get API Key from Google", systemImage: "arrow.up.forward.square")
                                .font(.subheadline)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .accessibilityLabel("Get API key from Google AI Studio")
                    .accessibilityHint("Opens Google AI Studio website in Safari")
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Your API key is stored locally on this device and never shared. Visit Google AI Studio to create a free API key.")
                        .font(.caption)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)

                            Text("How It Works")
                                .font(.headline)
                        }

                        Text("NutriThali uses Google's Gemini AI to analyze food images and provide detailed nutritional information, including calories, macronutrients, health verdicts, and diabetic-friendly guidance.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    HStack {
                        Text("Version")
                            .font(.subheadline)

                        Spacer()

                        Text("1.0.0")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Build")
                            .font(.subheadline)

                        Spacer()

                        Text("2025.1")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        validateKey()
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        #endif
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel("Done")
                    .accessibilityHint("Saves settings and returns to previous screen")
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Discards changes and returns to previous screen")
                }
            }
            .onChange(of: apiKey) { oldValue, newValue in
                showValidation = false
            }
        }
    }

    private func validateKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        isKeyValid = !trimmedKey.isEmpty && trimmedKey.count > 20
        showValidation = true

        if !apiKey.isEmpty {
            apiKey = trimmedKey
        }
    }
}
