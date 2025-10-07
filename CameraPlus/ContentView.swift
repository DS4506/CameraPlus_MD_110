import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Camera") {
                    NavigationLink("Camera Plus") {
                        CameraPlusView()
                    }
                }

                Section("Utilities") {
                    // Preview is a dev tool, but you can navigate to it on-device too.
                    NavigationLink("Processor Preview (on-device)") {
                        ProcessorPreview()
                    }
                }
            }
            .navigationTitle("CameraPlus")
            .listStyle(.insetGrouped)
        }
    }
}

// If you want a canvas preview of the menu itself:
#Preview {
    ContentView()
}
