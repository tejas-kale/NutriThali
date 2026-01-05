import SwiftUI

struct IdentificationView: View {
    let result: FoodAnalysisResult
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let viewModel: ScannerViewModel
    
    @State private var showPortionEditor = false
    @State private var editedPortions: [FoodItem] = []
    @State private var showMealEditor = false
    @State private var editedDescription: String = ""
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Cancel")
                    
                    Spacer()
                    
                    Text("Identify Meal")
                        .font(Theme.Typography.roundedFont(.headline))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button(action: onConfirm) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Theme.primary)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Confirm")
                }
                .padding(.horizontal)
                .padding(.top, 50) // Adjust for safe area approx or use SafeAreaInsets if available, usually padding(.top) works with safe area ignore if pushed down
                .padding(.bottom, 10)
                .background(Theme.background) // Ensure header has background if content scrolls under
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image (if available)
                        if let image = viewModel.currentImage {
                            #if os(iOS)
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            #elseif os(macOS)
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            #endif
                        } else {
                            Rectangle()
                                .fill(Theme.cardBackground)
                                .frame(height: 250)
                                .overlay(Text("No Image").foregroundStyle(.gray))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        VStack(spacing: 8) {
                            Text(result.dishName)
                                .font(Theme.Typography.roundedFont(.largeTitle, weight: .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .foregroundStyle(Theme.primary)
                                Text(result.estimatedPortionSize)
                                    .font(Theme.Typography.roundedFont(.title3))
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Improve
                            if !viewModel.hasUsedImprove {
                                actionButton(title: "Improve Identification", icon: "sparkles", colour: .purple) {
                                    Task { await viewModel.improveResult() }
                                }
                            }
                            
                            // Adjust Meal
                            actionButton(title: "Adjust Meal Name", icon: "pencil", colour: Theme.primary) {
                                editedDescription = result.dishName
                                showMealEditor = true
                            }
                            
                            // Adjust Portion
                            actionButton(title: "Adjust Portion", icon: "slider.horizontal.3", colour: Theme.primary) {
                                if let items = result.foodItems, !items.isEmpty {
                                    editedPortions = items
                                } else {
                                    editedPortions = parsePortionSize(result.estimatedPortionSize)
                                }
                                showPortionEditor = true
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 120) // Increased to avoid Tab Bar overlap
                    }
                    .padding(.top, 10)
                }
            }
        }
        .sheet(isPresented: $showPortionEditor) {
            PortionEditorSheet(foodItems: $editedPortions, onUpdate: { updatedItems in
                viewModel.updatePortions(updatedItems)
            })
        }
        .sheet(isPresented: $showMealEditor) {
            MealEditorSheet(mealDescription: $editedDescription, onUpdate: { updatedDescription in
                viewModel.updateDishName(updatedDescription)
            })
        }
    }
    
    func actionButton(title: String, icon: String, colour: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .frame(width: 24)
                Text(title)
                    .font(Theme.Typography.roundedFont(.body, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray.opacity(0.5))
            }
            .foregroundStyle(.white)
            .padding()
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colour.opacity(0.5), lineWidth: 1)
            )
        }
    }
    
    private func parsePortionSize(_ portionString: String) -> [FoodItem] {
        let components = portionString.components(separatedBy: CharacterSet(charactersIn: "+,"))
        return components.enumerated().map { index, component in
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return nil }
            let parts = trimmed.components(separatedBy: " ")
            if parts.count >= 2 {
                let quantity = parts[0]
                let name = parts.dropFirst().joined(separator: " ")
                return FoodItem(name: name.capitalized, quantity: quantity)
            } else {
                return FoodItem(name: "Item \(index + 1)", quantity: trimmed)
            }
        }.compactMap { $0 }
    }
}
