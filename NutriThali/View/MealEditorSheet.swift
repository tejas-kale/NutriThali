import SwiftUI

struct MealEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var mealDescription: String
    let onUpdate: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Describe the food", text: $mealDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...8)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                Text("Edit the meal description to get updated nutritional information.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                Spacer()
            }
            .navigationTitle("Adjust Meal")
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
                        onUpdate(mealDescription)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .disabled(mealDescription.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
