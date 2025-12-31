import SwiftUI
import Charts

struct ResultView: View {
    let result: FoodAnalysisResult
    let onReset: () -> Void

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

                // Diabetes Care Section
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Diabetes Care", systemImage: "waveform.path.ecg")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Diabetic Friendliness")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

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
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Diabetic friendliness: \(result.diabeticFriendliness)")

                            Divider()

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
                    }
                    .padding(4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Action Button
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
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)
                .accessibilityLabel("Analyze another meal")
                .accessibilityHint("Returns to home screen to capture or select a new food image")
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