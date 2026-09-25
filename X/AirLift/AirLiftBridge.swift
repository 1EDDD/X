import Foundation
import AirliftFFI

final class AirLiftBridge {
    static let shared = AirLiftBridge()

    private init() {}

    var pairingPath: String? {
        PairingController.pairingURL()?.path
    }

    func apply(files: [String: Data], to targetDirectory: String) async throws {
        guard let pairingPath else {
            throw AirLiftError.notPaired
        }

        let staging = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: staging)
        }

        for (name, data) in files {
            let url = staging.appendingPathComponent(name)
            try data.write(to: url, options: .atomic)
        }

        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var errorPointer: UnsafeMutablePointer<CChar>?

                let rc = pairingPath.withCString { pairing in
                    staging.path.withCString { source in
                        targetDirectory.withCString { target in
                            al_exploit_write_dir(
                                pairing,
                                source,
                                target,
                                nil,
                                nil,
                                &errorPointer
                            )
                        }
                    }
                }

                let message = xString(errorPointer)
                if let errorPointer {
                    al_string_free(errorPointer)
                }

                if rc == 0 {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AirLiftError.operationFailed(message.isEmpty ? "AirLift write failed." : message))
                }
            }
        }
    }

    func respring() async throws {
        guard let pairingPath else {
            throw AirLiftError.notPaired
        }

        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var errorPointer: UnsafeMutablePointer<CChar>?

                let rc = pairingPath.withCString { pairing in
                    al_device_respring(pairing, nil, nil, &errorPointer)
                }

                let message = xString(errorPointer)
                if let errorPointer {
                    al_string_free(errorPointer)
                }

                if rc == 0 {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AirLiftError.operationFailed(message.isEmpty ? "Respring failed." : message))
                }
            }
        }
    }

    enum AirLiftError: LocalizedError {
        case notPaired
        case operationFailed(String)

        var errorDescription: String? {
            switch self {
            case .notPaired:
                return "Pair the device first."
            case .operationFailed(let message):
                return message
            }
        }
    }
}

private func xString(_ pointer: UnsafeMutablePointer<CChar>?) -> String {
    guard let pointer else { return "" }
    return String(cString: pointer)
}
