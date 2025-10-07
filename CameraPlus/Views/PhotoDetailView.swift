//
//  PhotoDetailView.swift
//

import SwiftUI
import CoreData
import UIKit

/// Detail view that works with NSManagedObject (no subclass mapping required).
struct PhotoDetailView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let object: NSManagedObject

    var body: some View {
        VStack(spacing: 20) {
            if let data = object.value(forKey: "imageData") as? Data,
               let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .shadow(radius: 4)
                    .padding()
            }

            VStack(alignment: .leading, spacing: 8) {
                let filter = object.value(forKey: "filter") as? String ?? "Unknown"
                let intensity = object.value(forKey: "intensity") as? Double ?? 0
                let date = object.value(forKey: "createdAt") as? Date

                Text("Filter: \(filter)")
                Text(String(format: "Intensity: %.2f", intensity))
                if let date {
                    Text("Saved: \(date.formatted(date: .abbreviated, time: .shortened))")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)

            Spacer()

            Button(role: .destructive) {
                ctx.delete(object)
                try? ctx.save()
                dismiss()
            } label: {
                Label("Delete Photo", systemImage: "trash")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.bottom)
        }
        .navigationTitle("Photo Details")
    }
}
