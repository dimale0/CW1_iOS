import UIKit

class ImageProcessor {
    func applyRandomFilter(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let filterNames = ["CISepiaTone", "CIPhotoEffectNoir", "CIColorInvert", "CIGaussianBlur"]
        let randomFilterName = filterNames.randomElement() ?? "CISepiaTone"
        let filter = CIFilter(name: randomFilterName)
        filter?.setValue(ciImage, forKey: kCIInputImageKey)

        if randomFilterName == "CIGaussianBlur" {
            filter?.setValue(5.0, forKey: kCIInputRadiusKey)
        }

        guard let outputImage = filter?.outputImage else { return nil }
        let context = CIContext()
        if let cgImage = context.createCGImage(outputImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }

        return nil
    }
}
