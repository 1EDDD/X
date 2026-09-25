import SwiftUI

struct ContentView: View {
    @StateObject private var pairing = PairingController.shared
    @StateObject private var engine = SpringBoardEngine.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("X")
                                .font(.headline)

                            Text(pairing.status)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
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
                        VStack(spacing: 5) {
                            Text("PIN")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(pin)
                                .font(.system(.title2, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }

                Section("SpringBoard") {
                    ForEach(SpringBoardTweaks.all) { tweak in
                        Toggle(
                            tweak.title,
                            isOn: Binding(
                                get: { engine.isEnabled(tweak) },
                                set: { engine.set(tweak, enabled: $0) }
                            )
                        )
                        .disabled(pairing.pairingPath == nil)
                    }
                }

                Section {
                    Button {
                        for tweak in SpringBoardTweaks.all where engine.isEnabled(tweak) {
                            engine.apply(tweak)
                        }
                    } label: {
                        Label("Prepare Changes", systemImage: "slider.horizontal.3")
                    }
                    .disabled(pairing.pairingPath == nil || engine.applying)

                    if pairing.running {
                        Button("Cancel Pairing", role: .destructive) {
                            pairing.cancel()
                        }
                    }
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
