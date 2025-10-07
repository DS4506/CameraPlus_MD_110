//
//  ProcessorPreview.swift
//  CameraPlus
//
//  Working preview for testing ImageProcessor.swift
//

import SwiftUI

struct ProcessorPreview: View {
    @State private var t: Double = 0.6
    @State private var filter: FilterOption = .sepia

    private let processor = ImageProcessor()
    private let sample: UIImage = SampleImage.make()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Processed image preview
                Image(uiImage: processed())
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.secondary.opacity(0.25))
                    )

                // Filter picker
                HStack {
                    Text("Filter")
                    Spacer()
                    Menu {
                        Picker("Filter", selection: $filter) {
                            ForEach(FilterOption.allCases) { f in
                                Text(f.rawValue).tag(f)
                            }
                        }
                    } label: {
                        Label(filter.rawValue, systemImage: "slider.horizontal.3")
                    }
                }
                .padding(.horizontal)

                // Intensity slider (only when filter supports it)
                if filter.supportsIntensity {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Intensity")
                            Spacer()
                            Text(String(format: "%.2f", t))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $t, in: 0...1)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Filter Preview")
        }
    }

    private func processed() -> UIImage {
        processor.apply(filter: filter, intensity: t, to: sample)
    }
}

// MARK: - Sample image generator
private enum SampleImage {
    static func make(size: CGSize = .init(width: 800, height: 600)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Gradient background
            let colors = [UIColor.systemTeal.cgColor, UIColor.systemIndigo.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors as CFArray,
                                      locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient,
                                             start: .zero,
                                             end: CGPoint(x: size.width, y: size.height),
                                             options: [])

            // Shapes
            UIColor.white.withAlphaComponent(0.2).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 60, y: 80, width: 280, height: 220))
            UIColor.systemYellow.withAlphaComponent(0.8).setFill()
            ctx.cgContext.fill(CGRect(x: 420, y: 260, width: 260, height: 160))

            // Text overlay
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 42, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            NSString(string: "CameraPlus Preview").draw(at: CGPoint(x: 60, y: 40), withAttributes: attrs)
        }
    }
}

// MARK: - Preview
#Preview {
    ProcessorPreview()
        .preferredColorScheme(.dark)
}
