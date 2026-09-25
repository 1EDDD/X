import Foundation

final class AirLiftBridge {
    static let shared = AirLiftBridge()

    private init() {}

    var isPaired: Bool {
        PairingController.shared.pairingPath != nil
    }

    enum BridgeError: LocalizedError {
        case notPaired
        case privilegedWriteUnavailable
        case respringUnavailable

        var errorDescription: String? {
            switch self {
            case .notPaired:
                return "Pair the device first."
            case .privilegedWriteUnavailable:
                return "The privileged device-write backend is not available in this build."
            case .respringUnavailable:
                return "Respring is not available in this build."
            }
        }
    }

    func write(data: Data, fileName: String, destination: String) async throws {
        guard isPaired else { throw BridgeError.notPaired }

        let fm = FileManager.default
        let directory = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("X-Payloads", isDirectory: true)

        try fm.createDirectory(at: directory, withIntermediateDirectories: true)

        let payloadURL = directory.appendingPathComponent(fileName)
        try data.write(to: payloadURL, options: .atomic)

        let manifest: [String: String] = [
            "file": fileName,
            "destination": destination,
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ]

        let manifestData = try JSONSerialization.data(
            withJSONObject: manifest,
            options: [.prettyPrinted, .sortedKeys]
        )
        try manifestData.write(
            to: directory.appendingPathComponent("manifest.json"),
            options: .atomic
        )
    }

    func respring() async throws {
        throw BridgeError.respringUnavailable
    }
}
