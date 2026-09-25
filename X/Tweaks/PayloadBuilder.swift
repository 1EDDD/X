import Foundation

enum SpringBoardPayloadBuilder {
    static func make(values: [TweakDefinition: Bool]) throws -> Data {
        var plist: [String: Bool] = [:]

        for (tweak, enabled) in values {
            plist[tweak.key] = enabled
        }

        return try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .binary,
            options: 0
        )
    }

    static func makeCurrent(using engine: SpringBoardEngine) throws -> Data {
        var plist: [String: Bool] = [:]

        for tweak in SpringBoardTweaks.all {
            plist[tweak.key] = engine.isEnabled(tweak)
        }

        return try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .binary,
            options: 0
        )
    }
}
