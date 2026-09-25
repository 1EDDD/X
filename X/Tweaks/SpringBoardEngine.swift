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

    func makePlist(for tweak: TweakDefinition) -> Data? {
        try? PropertyListSerialization.data(
            fromPropertyList: [tweak.key: isEnabled(tweak)],
            format: .binary,
            options: 0
        )
    }

    func apply(_ tweak: TweakDefinition) {
        guard !applying else { return }
        applying = true
        defer { applying = false }
        message = "Prepared (tweak.title)."
    }
}
