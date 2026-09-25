import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("System") {
                    NavigationLink("SpringBoard") {
                        SpringBoardView()
                    }
                }
            }
            .navigationTitle("X")
        }
    }
}

#Preview {
    ContentView()
}
