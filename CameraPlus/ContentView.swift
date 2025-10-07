import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                NavigationLink {
                    CameraPlusView()
                } label: {
                    Text("Camera Plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                NavigationLink {
                    GalleryView()
                } label: {
                    Text("Saved Photos")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Camera Plus")
        }
    }
}

#Preview {
    ContentView()
}
