import SwiftUI

struct SpringBoardView: View {
    @StateObject private var engine = SpringBoardEngine.shared

    var body: some View {
        List {
            Section("SpringBoard") {
                ForEach(SpringBoardTweaks.all) { tweak in
                    Toggle(
                        tweak.title,
                        isOn: Binding(
                            get: { engine.isEnabled(tweak) },
                            set: { engine.set(tweak, enabled: $0) }
                        )
                    )
                }
            }

            Section {
                Button {
                    Task { await engine.applyPreparedChanges() }
                } label: {
                    HStack {
                        Text("Prepare Changes")
                        Spacer()
                        if engine.applying {
                            ProgressView()
                        }
                    }
                }
                .disabled(engine.applying)

                Button("Respring") {
                    Task { await engine.respring() }
                }
                .disabled(engine.applying)
            }

            if !engine.message.isEmpty {
                Section("Status") {
                    Text(engine.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("SpringBoard")
    }
}
