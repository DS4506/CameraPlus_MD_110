//
//  ImageProcessor.swift
//  CameraPlus
//
//  UIImage → CIImage → CIFilter → CIContext → CGImage → UIImage
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

final class ImageProcessor {

    // Reuse one CIContext (creating many is expensive)
    private let context = CIContext(options: nil)

    /// Apply a Core Image filter with a single 0...1 intensity control.
    /// Falls back to the original image if anything fails.
    func apply(filter: FilterOption, intensity: Double, to image: UIImage) -> UIImage {
        // Clamp slider to [0, 1]
        let t = max(0.0, min(1.0, intensity))

        // No-op filter
        if filter == .original { return image }

        // UIImage → CIImage
        guard let ciInput = CIImage(image: image) else { return image }

        // Configure the requested filter
        let outputCI: CIImage?
        switch filter {
        case .noir:
            let f = CIFilter.photoEffectNoir()
            f.inputImage = ciInput
            outputCI = f.outputImage

        case .sepia:
            let f = CIFilter.sepiaTone()
            f.inputImage = ciInput
            f.intensity = Float(t)                    // 0...1
            outputCI = f.outputImage

        case .bloom:
            let f = CIFilter.bloom()
            f.inputImage = ciInput
            f.intensity = Float(t)                    // 0...1
            f.radius    = Float(t * 20.0)            // 0...20
            outputCI = f.outputImage

        case .vignette:
            let f = CIFilter.vignette()
            f.inputImage = ciInput
            f.intensity = Float(t * 2.0)             // 0...2 (gives range)
            f.radius    = Float(max(1.0, t * 4.0))   // ≥1.0 to avoid no-op
            outputCI = f.outputImage

        case .colorControls:
            let f = CIFilter.colorControls()
            f.inputImage = ciInput
            // Map t (0...1) to useful ranges:
            f.saturation = Float(0.5 + 1.0 * t)      // 0.5 → 1.5
            f.contrast   = Float(0.9 + 0.4 * t)      // 0.9 → 1.3
            f.brightness = Float(-0.1 + 0.2 * t)     // -0.1 → 0.1
            outputCI = f.outputImage

        case .original:
            outputCI = ciInput
        }

        // CIImage → CGImage
        guard let final = outputCI,
              let cg = context.createCGImage(final, from: final.extent) else {
            return image
        }

        // Preserve original scale and orientation
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
}
