import Foundation

@MainActor
final class SpringBoardEngine: ObservableObject {
    static let shared = SpringBoardEngine()

    @Published private(set) var values: [String: Bool] = [:]
    @Published private(set) var applying = false
    @Published var message = ""

    private let defaultsKey = "XSpringBoardTweaks"

    init() {
        values = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Bool] ?? [:]
    }

    func set(_ tweak: TweakDefinition, enabled: Bool) {
        values[tweak.id] = enabled
        UserDefaults.standard.set(values, forKey: defaultsKey)
    }

    func isEnabled(_ tweak: TweakDefinition) -> Bool {
        values[tweak.id] ?? false
    }

    func payload() throws -> Data {
        var plist: [String: Bool] = [:]

        for tweak in SpringBoardTweaks.all {
            plist[tweak.key] = isEnabled(tweak)
        }

        return try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .binary,
            options: 0
        )
    }

    func applyPreparedChanges() async {
        guard !applying else { return }
        applying = true
        defer { applying = false }

        do {
            let data = try payload()

            try await AirLiftBridge.shared.write(
                data: data,
                fileName: "com.apple.springboard.plist",
                destination: AppConfig.springBoardPreferences
            )

            message = "Payload prepared successfully. The privileged write backend is not included in this build."
        } catch {
            message = error.localizedDescription
        }
    }

    func respring() async {
        guard !applying else { return }
        applying = true
        defer { applying = false }

        do {
            try await AirLiftBridge.shared.respring()
            message = "Respring requested."
        } catch {
            message = error.localizedDescription
        }
    }
}
