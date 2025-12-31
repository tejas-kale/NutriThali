import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

class ImageCompressionService {
    private let targetSizeKB: Double
    private let minCompression: CGFloat = 0.1
    private let compressionStep: CGFloat = 0.1

    init(targetSizeKB: Double = 150.0) {
        self.targetSizeKB = targetSizeKB
    }

    func compressImageForStorage(_ image: PlatformImage) -> Data? {
        var compression: CGFloat = 0.8

        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return nil
        }

        // Iterative compression to hit target size (~100-200KB)
        while Double(imageData.count) / 1024.0 > targetSizeKB && compression > minCompression {
            compression -= compressionStep
            if let newData = image.jpegData(compressionQuality: compression) {
                imageData = newData
            } else {
                break
            }
        }

        return imageData
    }

    func imageSizeInKB(_ data: Data) -> Double {
        return Double(data.count) / 1024.0
    }
}
