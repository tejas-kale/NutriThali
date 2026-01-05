import SwiftUI

struct DailySummaryView: View {
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFats: Double
    let mealCount: Int

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.top, 8)

                        HStack(spacing: 24) {
                            MacroSummary(name: "Protein", value: totalProtein, colour: .green)
                            MacroSummary(name: "Carbs", value: totalCarbs, colour: .blue)
                            MacroSummary(name: "Fats", value: totalFats, colour: .orange)
                        }
                    }
                    .padding(.bottom, 12)
                },
                label: {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(mealCount) meal\(mealCount == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(totalCalories))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)

                                Text("kcal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chart.bar.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                            .accessibilityHidden(true)
                    }
                }
            )
            .padding(16)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mealCount) meals, \(Int(totalCalories)) kilocalories total. \(isExpanded ? "Expanded" : "Collapsed")")
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") macronutrient details")
    }
}

struct MacroSummary: View {
    let name: String
    let value: Double
    let colour: Color

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(colour.gradient)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)

            VStack(spacing: 2) {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(Int(value))g")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(Int(value)) grams")
    }
}

#Preview {
    DailySummaryView(
        totalCalories: 1850,
        totalProtein: 95,
        totalCarbs: 210,
        totalFats: 65,
        mealCount: 3
    )
    .padding()
}
