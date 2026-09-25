import SwiftUI

struct ContentView: View {
    @StateObject private var pairing = PairingController.shared
    @StateObject private var engine = SpringBoardEngine.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Device")
                                .font(.headline)
                            Text(pairing.status)
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }

                        Spacer()

                        if pairing.running {
                            ProgressView()
                        } else {
                            Button(pairing.pairingPath == nil ? "Pair" : "Re-pair") {
                                pairing.start()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    if let pin = pairing.pin {
                        Text("PIN: (pin)")
                            .font(.system(.title2, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }

                Section("SpringBoard") {
                    ForEach(SpringBoardTweaks.all) { tweak in
                        Toggle(isOn: Binding(
                            get: { engine.isEnabled(tweak) },
                            set: { engine.set(tweak, enabled: $0) }
                        )) {
                            Text(tweak.title)
                        }
                        .disabled(pairing.pairingPath == nil || engine.applying)
                    }
                }

                Section {
                    Button {
                        Task { await engine.applyAll() }
                    } label: {
                        Label("Apply Changes", systemImage: "checkmark.circle.fill")
                    }
                    .disabled(pairing.pairingPath == nil || engine.applying)

                    Button {
                        Task { await engine.respring() }
                    } label: {
                        Label("Respring", systemImage: "arrow.clockwise")
                    }
                    .disabled(pairing.pairingPath == nil || engine.applying)
                }

                if !engine.message.isEmpty {
                    Section {
                        Text(engine.message)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("X")
            .task {
                pairing.refresh()
            }
        }
    }
}

#Preview {
    ContentView()
}
