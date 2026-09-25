import Foundation

@MainActor
final class SpringBoardEngine: ObservableObject {
    static let shared = SpringBoardEngine()

    @Published private(set) var values: [String: Bool] = [:]
    @Published private(set) var applying = false
    @Published var message = ""

    private let definitions = SpringBoardTweaks.all
    private let defaultsKey = "XSpringBoardTweaks"

    init() {
        load()
    }

    func set(_ definition: TweakDefinition, enabled: Bool) {
        values[definition.id] = enabled
        persist()
    }

    func isEnabled(_ definition: TweakDefinition) -> Bool {
        values[definition.id] ?? definition.enabledByDefault
    }

    func applyAll() async {
        guard !applying else { return }
        applying = true
        defer { applying = false }

        var files: [String: Data] = [:]

        for definition in definitions {
            if let data = makePlist(for: definition.key, enabled: isEnabled(definition)) {
                files["com.apple.springboard.plist"] = data
                break
            }
        }

        guard !files.isEmpty else {
            message = "Nothing to apply."
            return
        }

        do {
            try await AirLiftBridge.shared.apply(files: files, to: SpringBoardTweaks.targetDirectory)
            message = "Applied. Respring to finish."
        } catch {
            message = error.localizedDescription
        }
    }

    func apply(_ definition: TweakDefinition) async {
        applying = true
        defer { applying = false }

        do {
            let current = isEnabled(definition)
            let data = try makeMergedPlist(key: definition.key, enabled: current)
            try await AirLiftBridge.shared.apply(
                files: ["com.apple.springboard.plist": data],
                to: SpringBoardTweaks.targetDirectory
            )
            message = "(definition.title) applied."
        } catch {
            message = error.localizedDescription
        }
    }

    func respring() async {
        applying = true
        defer { applying = false }

        do {
            try await AirLiftBridge.shared.respring()
            message = "Respring requested."
        } catch {
            message = error.localizedDescription
        }
    }

    private func makePlist(for key: String, enabled: Bool) -> Data? {
        let value: Any = enabled ? true : false
        return try? PropertyListSerialization.data(fromPropertyList: [key: value], format: .binary, options: 0)
    }

    private func makeMergedPlist(key: String, enabled: Bool) throws -> Data {
        let value: Any = enabled ? true : false
        return try PropertyListSerialization.data(
            fromPropertyList: [key: value],
            format: .binary,
            options: 0
        )
    }

    private func load() {
        let stored = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Bool] ?? [:]
        values = stored
    }

    private func persist() {
        UserDefaults.standard.set(values, forKey: defaultsKey)
    }
}
