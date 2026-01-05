import SwiftUI

struct SettingsView: View {
    @AppStorage("gemini_api_key") private var apiKey: String = ""
    @State private var isExpanded = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        Text("Settings")
                            .font(Theme.Typography.roundedFont(.largeTitle, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        // API Key Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Gemini API Key", systemImage: "key.fill")
                                .font(Theme.Typography.roundedFont(.headline))
                                .foregroundStyle(Theme.primary)
                            
                            HStack {
                                SecureField("Paste API Key here", text: $apiKey)
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(.white)
                                    .overlay(
                                        HStack {
                                            Spacer()
                                            if apiKey.isEmpty {
                                                Button {
                                                    #if os(iOS)
                                                    apiKey = UIPasteboard.general.string ?? ""
                                                    #endif
                                                } label: {
                                                    Text("Paste")
                                                        .font(Theme.Typography.roundedFont(.caption, weight: .bold))
                                                        .foregroundStyle(Theme.primary)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(Theme.primary.opacity(0.1))
                                                        .clipShape(Capsule())
                                                }
                                                .padding(.trailing, 8)
                                            }
                                        }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                
                                if !apiKey.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            
                            Text("Your key is stored securely on device.")
                                .font(Theme.Typography.roundedFont(.caption))
                                .foregroundStyle(.gray)
                        }
                        .padding(20)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Shapes.cardCornerRadius))
                        .padding(.horizontal)
                        
                        // Info Section
                        VStack(alignment: .leading, spacing: 0) {
                            Button {
                                withAnimation { isExpanded.toggle() }
                            } label: {
                                HStack {
                                    Label("How it Works", systemImage: "info.circle.fill")
                                        .font(Theme.Typography.roundedFont(.headline))
                                        .foregroundStyle(Theme.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                        .foregroundStyle(.gray)
                                }
                                .padding(20)
                            }
                            
                            if isExpanded {
                                Divider().background(Color.gray.opacity(0.2))
                                Text("NutriThali uses Google's Gemini AI to analyze food images. Simply take a photo of your meal, and the AI will estimate calories, macros, and provide health insights.")
                                    .font(Theme.Typography.roundedFont(.subheadline))
                                    .foregroundStyle(.gray)
                                    .padding(20)
                                    .transition(.opacity)
                            }
                        }
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Shapes.cardCornerRadius))
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text("NutriThali v1.0")
                                .font(Theme.Typography.roundedFont(.caption))
                                .foregroundStyle(.gray)
                            Text("Designed with 💚")
                                .font(Theme.Typography.roundedFont(.caption2))
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}