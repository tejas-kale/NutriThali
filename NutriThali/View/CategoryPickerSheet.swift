import SwiftUI

struct CategoryPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (MealCategory) -> Void

    var body: some View {
        NavigationStack {
            List(MealCategory.allCases, id: \.self) { category in
                Button {
                    onSelect(category)
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: category.icon)
                            .font(.title2)
                            .foregroundStyle(category.colour)
                            .frame(width: 44)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.rawValue)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(category.timeBasedHint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(category.rawValue). \(category.timeBasedHint)")
                .accessibilityHint("Select this category for your meal")
            }
            .listStyle(.plain)
            .navigationTitle("Save as...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel meal categorization")
                    .accessibilityHint("Returns to results without saving")
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    CategoryPickerSheet { category in
        print("Selected: \(category.rawValue)")
    }
}
