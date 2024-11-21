import UIKit

class ImageDatabase {
    static let shared = ImageDatabase()
    private var images: [UIImage] = []

    private init() {}

    func loadImages() {
        images = (1...12).compactMap { UIImage(named: "image\($0)") }
    }

    func getImages() -> [UIImage] {
        return images
    }
}
