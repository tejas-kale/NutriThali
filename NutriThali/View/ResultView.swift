import SwiftUI
import Charts

struct ResultView: View {
    let result: FoodAnalysisResult
    let onReset: () -> Void
    let viewModel: ScannerViewModel

    @State private var isDiabeticSectionExpanded = false
    @State private var showCategoryPicker = false
    @State private var isSaving = false
    @State private var isRecalculating = false
    @State private var showPortionEditor = false
    @State private var editedPortions: [FoodItem] = []
    @State private var showMealEditor = false
    @State private var editedDescription: String = ""

    struct MacroData: Identifiable {
        let name: String
        let value: Double
        let colour: Color

        var id: String { name }
    }

    var macroData: [MacroData] {
        [
            MacroData(name: "Protein", value: result.macros.protein, colour: .green),
            MacroData(name: "Carbs", value: result.macros.carbs, colour: .blue),
            MacroData(name: "Fats", value: result.macros.fats, colour: .orange)
        ]
    }

    var diabeticColour: Color {
        switch result.diabeticFriendliness {
        case "High": return .green
        case "Moderate": return .orange
        case "Low": return .red
        default: return .gray
        }
    }

    var isHealthy: Bool {
        result.verdictEmoji == "✅"
    }
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: onReset) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Discard")
                    
                    Spacer()
                    
                    Spacer()
                    
                    Button {
                        showCategoryPicker = true
                    } label: {
                        if isSaving {
                            ProgressView().tint(Theme.primary)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Theme.primary)
                                .clipShape(Circle())
                        }
                    }
                    .disabled(isSaving)
                    .accessibilityLabel("Save")
                }
                .padding(.horizontal)
                .padding(.top, 50)
                .padding(.bottom, 10)
                .background(Theme.background)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 16) {
                            Text(result.dishName)
                                .font(Theme.Typography.roundedFont(.largeTitle, weight: .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                                .padding(.top, 8)
                        }

                        if isRecalculating {
                            ProgressView()
                                .controlSize(.regular)
                                .tint(Theme.primary)
                            Text("Recalculating...")
                                .font(Theme.Typography.roundedFont(.subheadline))
                                .foregroundStyle(.gray)
                                .padding(.top, 8)
                        } else {
                            HStack(spacing: 8) {
                                Text(result.verdictEmoji)
                                    .font(.title2)
                                    .accessibilityHidden(true)

                                Text(isHealthy ? "Healthy Choice" : "Eat in Moderation")
                                    .font(Theme.Typography.roundedFont(.subheadline, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isHealthy ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                    .foregroundStyle(isHealthy ? .green : .orange)
                                    .clipShape(Capsule())
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(isHealthy ? "Healthy choice" : "Eat in moderation")
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)

                    // Calories Card
                    VStack(spacing: 12) {
                        Label("Total Calories", systemImage: "flame.fill")
                            .font(Theme.Typography.roundedFont(.headline))
                            .foregroundStyle(.gray)
                            .accessibilityAddTraits(.isHeader)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(result.calories))")
                                .font(Theme.Typography.roundedFont(size: 64, weight: .bold))
                                .foregroundStyle(Theme.primary)

                            Text("kcal")
                                .font(Theme.Typography.roundedFont(.title3, weight: .medium))
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Shapes.cardCornerRadius))
                    .padding(.horizontal, 16)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Total calories: \(Int(result.calories)) kilocalories")

                    // Estimated Portion Size
                    HStack(spacing: 12) {
                        Image(systemName: "scalemass")
                            .font(.title3)
                            .foregroundStyle(Theme.primary)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Estimated Portion")
                                .font(Theme.Typography.roundedFont(.caption, weight: .semibold))
                                .foregroundStyle(.gray)
                                .textCase(.uppercase)

                            Text(result.estimatedPortionSize)
                                .font(Theme.Typography.roundedFont(.subheadline, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Shapes.cardCornerRadius))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Nutrition Facts Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Nutrition Facts", systemImage: "chart.pie.fill")
                            .font(Theme.Typography.roundedFont(.headline))
                            .foregroundStyle(.white)
                            .accessibilityAddTraits(.isHeader)

                        // Macros Chart
                        HStack(spacing: 24) {
                            Chart(macroData) { item in
                                SectorMark(
                                    angle: .value("Value", item.value),
                                    innerRadius: .ratio(0.65),
                                    angularInset: 2.0
                                )
                                .foregroundStyle(item.colour.gradient)
                            }
                            .frame(width: 130, height: 130)
                            .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(macroData) { item in
                                    MacroRow(macro: item)
                                }
                            }
                        }
                        .padding(.vertical, 8)

                        Divider().background(Color.gray.opacity(0.3))

                        Text(result.briefExplanation)
                            .font(Theme.Typography.roundedFont(.subheadline))
                            .foregroundStyle(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Shapes.cardCornerRadius))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Diabetes Care Section
                    VStack(alignment: .leading, spacing: 0) {
                        Button {
                            withAnimation { isDiabeticSectionExpanded.toggle() }
                        } label: {
                            HStack {
                                Label("Diabetes Care", systemImage: "waveform.path.ecg")
                                    .font(Theme.Typography.roundedFont(.headline))
                                    .foregroundStyle(.white)

                                Spacer()

                                Text(result.diabeticFriendliness)
                                    .font(Theme.Typography.roundedFont(.caption, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(diabeticColour.opacity(0.2))
                                    .foregroundStyle(diabeticColour)
                                    .clipShape(Capsule())
                                
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(isDiabeticSectionExpanded ? 90 : 0))
                                    .foregroundStyle(.gray)
                            }
                            .padding(20)
                        }

                        if isDiabeticSectionExpanded {
                            VStack(alignment: .leading, spacing: 16) {
                                Divider().background(Color.gray.opacity(0.3))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Advice")
                                        .font(Theme.Typography.roundedFont(.caption, weight: .semibold))
                                        .foregroundStyle(.gray)
                                        .textCase(.uppercase)

                                    Text(result.diabeticAdvice)
                                        .font(Theme.Typography.roundedFont(.subheadline))
                                        .foregroundStyle(.white)
                                }

                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "scalemass.fill")
                                        .font(.title3)
                                        .foregroundStyle(Theme.primary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Recommended Portion")
                                            .font(Theme.Typography.roundedFont(.caption, weight: .semibold))
                                            .foregroundStyle(.gray)
                                            .textCase(.uppercase)

                                        Text(result.portionSizeSuggestion)
                                            .font(Theme.Typography.roundedFont(.subheadline, weight: .medium))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .transition(.opacity)
                        }
                    }
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Shapes.cardCornerRadius))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    Spacer(minLength: 120)
                }
            }
        }

        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet { category in
                Task {
                    isSaving = true
                    await viewModel.saveMeal(category: category)
                    isSaving = false
                }
            }
        }
    }
}

struct MacroRow: View {
    let macro: ResultView.MacroData

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(macro.colour.gradient)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 0) {
                Text(macro.name)
                    .font(Theme.Typography.roundedFont(.caption))
                    .foregroundStyle(.gray)

                Text("\(Int(macro.value))g")
                    .font(Theme.Typography.roundedFont(.subheadline, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}