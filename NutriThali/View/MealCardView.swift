import SwiftUI

struct MealCardView: View {
    let meal: MealEntry

    var categoryColor: Color {
        guard let categoryString = meal.category,
              let category = MealCategory(rawValue: categoryString) else {
            return .gray
        }
        return category.color
    }

    var categoryIcon: String {
        guard let categoryString = meal.category,
              let category = MealCategory(rawValue: categoryString) else {
            return "questionmark.circle"
        }
        return category.icon
    }

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
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityHidden(true)
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityHidden(true)
                }
                #endif
            }

            // Meal Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(meal.dishName ?? "Unknown Dish")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    // Category Badge
                    HStack(spacing: 4) {
                        Image(systemName: categoryIcon)
                            .font(.caption2)

                        Text(meal.category ?? "")
                            .font(.caption)
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.15))
                    .foregroundStyle(categoryColor)
                    .clipShape(Capsule())
                }

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    Text("\(Int(meal.calories)) kcal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(Int(meal.calories)) kilocalories")

                Text(timeString)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(12)
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meal.dishName ?? "Unknown dish"), \(meal.category ?? ""), \(Int(meal.calories)) kilocalories, \(timeString)")
        .accessibilityHint("Double tap to view meal details")
    }
}
