//
//  GalleryView.swift
//

import SwiftUI
import CoreData
import UIKit

struct GalleryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var items: [NSManagedObject] = []
    @State private var errorText: String?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Gallery")
        }
        .task { await fetch() }
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        if let errorText {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                Text(errorText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                NavigationLink("Open Camera Plus") { CameraPlusView() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        } else if items.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("No saved photos yet.")
                    .font(.headline)
                NavigationLink("Open Camera Plus") { CameraPlusView() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items, id: \.objectID) { obj in
                        let data = obj.value(forKey: "imageData") as? Data
                        if let data, let uiImage = UIImage(data: data) {
                            NavigationLink {
                                PhotoDetailView(object: obj)
                            } label: {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    delete(obj)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Actions
    private func delete(_ obj: NSManagedObject) {
        withAnimation {
            viewContext.delete(obj)
            do { try viewContext.save() }
            catch { print("Failed to delete photo: \(error)") }
            items.removeAll { $0.objectID == obj.objectID }
        }
    }

    // MARK: - Fetch
    @MainActor
    private func fetch() async {
        // Verify the entity exists in the loaded model
        let available = viewContext.persistentStoreCoordinator?
            .managedObjectModel.entitiesByName
        guard available?["EditedPhoto"] != nil else {
            let names = available?.keys.sorted() ?? []
            errorText =
            """
            The loaded Core Data model does not contain an entity named “EditedPhoto”.
            Available entities: \(names)
            Check:
            • .xcdatamodeld file name matches Persistence (‘CameraPlusModel’)
            • Entity name is exactly EditedPhoto
            • Target membership and Copy Bundle Resources include the model
            """
            return
        }

        let req = NSFetchRequest<NSManagedObject>(entityName: "EditedPhoto")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            items = try viewContext.fetch(req)
        } catch {
            errorText = "Fetch failed: \(error.localizedDescription)"
        }
    }
}
