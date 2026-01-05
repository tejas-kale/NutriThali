import SwiftUI

struct PortionEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var foodItems: [FoodItem]
    let onUpdate: ([FoodItem]) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach($foodItems) { $item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        TextField("Quantity", text: $item.quantity)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                            .accessibilityLabel("Edit portion for \(item.name)")
                            .accessibilityValue("Current quantity: \(item.quantity)")
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Adjust Portions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onUpdate(foodItems)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .disabled(foodItems.isEmpty || foodItems.contains { $0.quantity.trimmingCharacters(in: .whitespaces).isEmpty })
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
