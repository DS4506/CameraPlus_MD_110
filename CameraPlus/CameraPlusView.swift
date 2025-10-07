//
//  CameraPlusView.swift
//

import SwiftUI
import UIKit          // <- fixes 'UIImage' not found
import AVFoundation
import CoreData       // <- needed for viewContext

struct CameraPlusView: View {

    // Core Data context for saving
    @Environment(\.managedObjectContext) private var viewContext   // <- fixes 'viewContext' not found

    // State
    @State private var showingPicker = false
    @State private var selectedSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var originalImage: UIImage?
    @State private var processedImage: UIImage?

    @State private var selectedFilter: FilterOption = .noir
    @State private var intensity: Double = 0.7

    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    @State private var showError = false
    @State private var errorMessage = ""

    @State private var isComparing = false
    @State private var showSavedToast = false

    // Services
    private let processor = ImageProcessor()
    private let saver = PhotoSaver()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // Source selector
                Picker("Source", selection: $selectedSource) {
                    Text("Library").tag(UIImagePickerController.SourceType.photoLibrary)
                    Text("Camera").tag(UIImagePickerController.SourceType.camera)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Preview
                Group {
                    if originalImage != nil || processedImage != nil {
                        GeometryReader { geo in
                            ZStack {
                                if let orig = originalImage {
                                    Image(uiImage: orig)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                                        .opacity(isComparing ? 1 : 0)
                                }
                                if let edited = processedImage ?? originalImage {
                                    Image(uiImage: edited)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                                        .opacity(isComparing ? 0 : 1)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                        .contentShape(Rectangle())
                        .onLongPressGesture(minimumDuration: 0.01, maximumDistance: .infinity, pressing: { down in
                            isComparing = down
                        }, perform: {})
                        .overlay(
                            Group {
                                if processedImage != nil {
                                    Text(isComparing ? "Original" : selectedFilter.rawValue)
                                        .font(.caption2)
                                        .padding(6)
                                        .background(.ultraThinMaterial, in: Capsule())
                                        .padding(6)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                }
                            }
                        )
                        .frame(height: 280)
                        .padding(.horizontal)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.secondary.opacity(0.05))
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("No image selected")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 280)
                        .padding(.horizontal)
                    }
                }

                // Controls
                VStack(spacing: 12) {

                    HStack {
                        Button(action: pickImage) {
                            Label(selectedSource == .camera ? "Take Photo" : "Choose Photo",
                                  systemImage: selectedSource == .camera ? "camera" : "photo")
                        }
                        .buttonStyle(.borderedProminent)

                        Spacer()

                        Button(action: saveImage) {
                            Label("Save", systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        .disabled(originalImage == nil && processedImage == nil)
                    }

                    // Filter + intensity
                    HStack {
                        Text("Filter")
                        Spacer()
                        Menu {
                            Picker("Filter", selection: $selectedFilter) {
                                ForEach(FilterOption.allCases) { f in
                                    Text(f.rawValue).tag(f)
                                }
                            }
                        } label: {
                            Label(selectedFilter.rawValue, systemImage: "slider.horizontal.3")
                        }
                    }

                    if selectedFilter.supportsIntensity {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Intensity")
                                Spacer()
                                Text(String(format: "%.2f", intensity))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $intensity, in: 0...1) { _ in
                                applyFilter()
                            }
                        }
                    }

                    HStack {
                        Button(role: .destructive) {
                            originalImage = nil
                            processedImage = nil
                        } label: {
                            Label("Clear", systemImage: "xmark.circle")
                        }
                        .disabled(originalImage == nil && processedImage == nil)

                        Spacer()

                        Button {
                            processedImage = originalImage
                        } label: {
                            Label("Show Original", systemImage: "eye")
                        }
                        .disabled(originalImage == nil)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal)

                Spacer(minLength: 12)
            }
            .navigationTitle("Camera Plus")
        }
        .overlay(
            Group {
                if showSavedToast {
                    Text("Saved ✅")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.secondary.opacity(0.25), lineWidth: 1))
                        .padding(.bottom, 24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .transition(.opacity)
                }
            }
        )
        .sheet(isPresented: $showingPicker) {
            ImagePicker(isPresented: $showingPicker,
                        image: $originalImage,
                        sourceType: selectedSource,
                        allowsEditing: true)
                .onDisappear { applyFilter() }
        }
        .alert("Saved", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: { Text(saveMessage) }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: { Text(errorMessage) }
    }

    // MARK: - Actions

    private func pickImage() {
        if selectedSource == .camera && !UIImagePickerController.isSourceTypeAvailable(.camera) {
            errorMessage = "Camera is not available on this device. Switch to Photo Library."
            showError = true
            return
        }
        if selectedSource == .camera {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .denied, .restricted:
                errorMessage = "Camera permission denied. Enable it in Settings > Privacy > Camera."
                showError = true
                return
            case .notDetermined, .authorized:
                break
            @unknown default: break
            }
        }
        showingPicker = true
    }

    private func applyFilter() {
        guard let base = originalImage else {
            processedImage = nil
            return
        }
        processedImage = processor.apply(filter: selectedFilter, intensity: intensity, to: base)
    }

    private func saveImage() {
        guard let imageToSave = (processedImage ?? originalImage) else { return }

        saver.writeToPhotoAlbum(image: imageToSave) { error in
            if let error = error {
                saveMessage = "Failed to save: \(error.localizedDescription)"
            } else {
                saveMessage = "Image saved to Photos."
                // Save to Core Data using a robust path that avoids subclass mapping issues
                saveToCoreData(image: imageToSave, filter: selectedFilter.rawValue, intensity: intensity)

                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)
                withAnimation { showSavedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    withAnimation { showSavedToast = false }
                }
            }
            showSaveAlert = true
        }
    }

    // MARK: - Core Data (robust insert without subclass)
    private func saveToCoreData(image: UIImage, filter: String, intensity: Double) {
        guard let entity = NSEntityDescription.entity(forEntityName: "EditedPhoto", in: viewContext) else {
            print("❌ Entity 'EditedPhoto' not found in loaded model.")
            return
        }
        let obj = NSManagedObject(entity: entity, insertInto: viewContext)
        obj.setValue(UUID(), forKey: "id")
        obj.setValue(Date(), forKey: "createdAt")
        obj.setValue(filter, forKey: "filter")
        obj.setValue(intensity, forKey: "intensity")
        obj.setValue(image.jpegData(compressionQuality: 0.9), forKey: "imageData")
        do { try viewContext.save() } catch { print("❌ Core Data save error: \(error)") }
    }
}
