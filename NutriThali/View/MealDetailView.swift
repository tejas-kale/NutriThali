import SwiftUI
import Charts

struct MealDetailView: View {
    @Environment(\.dismiss) var dismiss
    let meal: MealEntry
    let onDelete: () -> Void
    let onUpdateCategory: (MealCategory) -> Void

    @State private var isDiabeticSectionExpanded = false
    @State private var showCategoryPicker = false
    @State private var showDeleteConfirmation = false

    var macroData: [ResultView.MacroData] {
        [
            ResultView.MacroData(name: "Protein", value: meal.proteinGrams, color: .green),
            ResultView.MacroData(name: "Carbs", value: meal.carbsGrams, color: .blue),
            ResultView.MacroData(name: "Fats", value: meal.fatsGrams, color: .orange)
        ]
    }

    var diabeticColor: Color {
        switch meal.diabeticFriendliness {
        case "High": return .green
        case "Moderate": return .orange
        case "Low": return .red
        default: return .gray
        }
    }

    var isHealthy: Bool {
        meal.verdictEmoji == "✅"
    }

    var timestampString: String {
        guard let timestamp = meal.timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var categoryColor: Color {
        guard let categoryString = meal.category,
              let category = MealCategory(rawValue: categoryString) else {
            return .gray
        }
        return category.color
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Food Image
                    if let imageData = meal.imageData {
                        #if os(iOS)
                        if let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                                .clipped()
                                .accessibilityLabel("Food image for \(meal.dishName ?? "meal")")
                        }
                        #elseif os(macOS)
                        if let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 250)
                                .clipped()
                                .accessibilityLabel("Food image for \(meal.dishName ?? "meal")")
                        }
                        #endif
                    }

                    // Header Section
                    VStack(spacing: 16) {
                        Text(meal.dishName ?? "Unknown Dish")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)

                        HStack(spacing: 8) {
                            Text(meal.verdictEmoji ?? "")
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

                        // Timestamp and Category
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                Text(timestampString)
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)

                            Button {
                                showCategoryPicker = true
                            } label: {
                                HStack(spacing: 8) {
                                    if let categoryString = meal.category,
                                       let category = MealCategory(rawValue: categoryString) {
                                        Image(systemName: category.icon)
                                            .font(.caption)
                                        Text(categoryString)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Image(systemName: "pencil")
                                            .font(.caption2)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(categoryColor.opacity(0.15))
                                .foregroundStyle(categoryColor)
                                .clipShape(Capsule())
                            }
                            .accessibilityLabel("Category: \(meal.category ?? "Unknown")")
                            .accessibilityHint("Double tap to change category")
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)

                    // Calories Card
                    VStack(spacing: 12) {
                        Label("Total Calories", systemImage: "flame.fill")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(Int(meal.calories))")
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

                    // Estimated Portion Size
                    if let portionSize = meal.estimatedPortionSize, !portionSize.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "scalemass")
                                .font(.title3)
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Estimated Portion")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)

                                Text(portionSize)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                            }

                            Spacer()
                        }
                        .padding(16)
                        #if os(iOS)
                        .background(Color(uiColor: .secondarySystemBackground))
                        #elseif os(macOS)
                        .background(Color(nsColor: .controlBackgroundColor))
                        #endif
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }

                    // Nutrition Facts Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Nutrition Facts", systemImage: "chart.pie.fill")
                                .font(.headline)
                                .foregroundStyle(.primary)

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

                            Divider()

                            Text(meal.briefExplanation ?? "")
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

                                        Text(meal.diabeticAdvice ?? "")
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Divider()

                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "scalemass.fill")
                                            .font(.title3)
                                            .foregroundStyle(.green)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Recommended Portion")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.secondary)
                                                .textCase(.uppercase)

                                            Text(meal.portionSizeSuggestion ?? "")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            },
                            label: {
                                HStack {
                                    Label("Diabetes Care", systemImage: "waveform.path.ecg")
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Text(meal.diabeticFriendliness ?? "")
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
                        .padding(4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Meal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete meal")
                    .accessibilityHint("Permanently remove this meal from history")
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet { category in
                    onUpdateCategory(category)
                }
            }
            .alert("Delete Meal?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("This meal will be permanently removed from your history.")
            }
        }
    }
}
