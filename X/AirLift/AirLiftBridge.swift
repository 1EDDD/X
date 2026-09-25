import Foundation
import AirliftFFI

final class AirLiftBridge {
    static let shared = AirLiftBridge()

    private init() {}

    var isPaired: Bool {
        PairingController.shared.pairingPath != nil
    }

    enum BridgeError: LocalizedError {
        case notPaired

        var errorDescription: String? {
            switch self {
            case .notPaired:
                return "Pair the device first."
            }
        }
    }
}
