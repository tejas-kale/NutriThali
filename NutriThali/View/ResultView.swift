import SwiftUI
import Charts

struct ResultView: View {
    let result: FoodAnalysisResult
    let onReset: () -> Void
    let viewModel: ScannerViewModel

    @State private var isDiabeticSectionExpanded = false
    @State private var showCategoryPicker = false
    @State private var isSaving = false

    struct MacroData: Identifiable {
        let name: String
        let value: Double
        let color: Color

        var id: String { name }
    }

    var macroData: [MacroData] {
        [
            MacroData(name: "Protein", value: result.macros.protein, color: .green),
            MacroData(name: "Carbs", value: result.macros.carbs, color: .blue),
            MacroData(name: "Fats", value: result.macros.fats, color: .orange)
        ]
    }

    var diabeticColor: Color {
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
        ScrollView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 16) {
                    Text(result.dishName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    HStack(spacing: 8) {
                        Text(result.verdictEmoji)
                            .font(.title2)
                            .accessibilityHidden(true)

                        Text(isHealthy ? "Healthy Choice" : "Eat in Moderation")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isHealthy ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                            .foregroundStyle(isHealthy ? .green : .orange)
                            .clipShape(Capsule())
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(isHealthy ? "Healthy choice" : "Eat in moderation")
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 16)

                // Calories Card
                VStack(spacing: 12) {
                    Label("Total Calories", systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isHeader)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(result.calories))")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("kcal")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.accentColor.opacity(0.1))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total calories: \(Int(result.calories)) kilocalories")

                // Estimated Portion Size
                HStack(spacing: 12) {
                    Image(systemName: "scalemass")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated Portion")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(result.estimatedPortionSize)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground))
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Estimated portion: \(result.estimatedPortionSize)")

                // Nutrition Facts Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Nutrition Facts", systemImage: "chart.pie.fill")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)

                        // Macros Chart
                        HStack(spacing: 20) {
                            Chart(macroData) { item in
                                SectorMark(
                                    angle: .value("Value", item.value),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2.0
                                )
                                .foregroundStyle(item.color.gradient)
                            }
                            .frame(width: 120, height: 120)
                            .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(macroData) { item in
                                    MacroRow(macro: item)
                                }
                            }
                        }
                        .accessibilityElement(children: .contain)

                        Divider()

                        // Summary
                        Text(result.briefExplanation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                // Diabetes Care Section (Expandable)
                GroupBox {
                    DisclosureGroup(
                        isExpanded: $isDiabeticSectionExpanded,
                        content: {
                            VStack(alignment: .leading, spacing: 12) {
                                Divider()
                                    .padding(.top, 4)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Advice")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)

                                    Text(result.diabeticAdvice)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Divider()

                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "scalemass.fill")
                                        .font(.title3)
                                        .foregroundStyle(.green)
                                        .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Recommended Portion")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                            .textCase(.uppercase)

                                        Text(result.portionSizeSuggestion)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Recommended portion: \(result.portionSizeSuggestion)")
                            }
                            .padding(.top, 8)
                        },
                        label: {
                            HStack {
                                Label("Diabetes Care", systemImage: "waveform.path.ecg")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text(result.diabeticFriendliness)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(diabeticColor.opacity(0.15))
                                    .foregroundStyle(diabeticColor)
                                    .clipShape(Capsule())
                            }
                        }
                    )
                    .accessibilityLabel("Diabetes care section, \(isDiabeticSectionExpanded ? "expanded" : "collapsed"). Diabetic friendliness: \(result.diabeticFriendliness)")
                    .accessibilityHint("Double tap to \(isDiabeticSectionExpanded ? "collapse" : "expand") diabetic advice")
                    .padding(4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Action Buttons
                VStack(spacing: 12) {
                    // Save to Journal Button
                    Button {
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        #endif
                        showCategoryPicker = true
                    } label: {
                        HStack {
                            Image(systemName: isSaving ? "hourglass" : "square.and.arrow.down.fill")
                                .font(.headline)
                            Text(isSaving ? "Saving..." : "Save to Journal")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)
                    .disabled(isSaving)
                    .accessibilityLabel(isSaving ? "Saving meal" : "Save meal to journal")
                    .accessibilityHint("Opens category selection to save this meal to your history")

                    // Analyze Another Button
                    Button {
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        #endif
                        onReset()
                    } label: {
                        Label("Analyze Another Meal", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityLabel("Analyze another meal")
                    .accessibilityHint("Returns to home screen to capture or select a new food image")
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)
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

// MARK: - Helper Views

struct MacroRow: View {
    let macro: ResultView.MacroData

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(macro.color.gradient)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(macro.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(Int(macro.value))g")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(macro.name): \(Int(macro.value)) grams")
    }
}