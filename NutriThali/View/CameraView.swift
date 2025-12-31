import SwiftUI

#if os(iOS)
import UIKit
import AVFoundation

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    var sourceType: UIImagePickerController.SourceType = .camera
    var onPermissionDenied: (() -> Void)?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        // Check camera permission if using camera
        if sourceType == .camera {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .denied || status == .restricted {
                DispatchQueue.main.async {
                    self.onPermissionDenied?()
                    self.isPresented = false
                }
            }
        }

        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen

        // Accessibility
        picker.view.accessibilityLabel = sourceType == .camera ? "Camera view" : "Photo library"

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image

                // Provide haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Provide haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            parent.isPresented = false
        }
    }
}
#endif
