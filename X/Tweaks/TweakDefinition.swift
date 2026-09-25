import Foundation

struct TweakDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let key: String
    let enabledByDefault: Bool

    init(_ id: String, _ title: String, _ key: String, enabledByDefault: Bool = false) {
        self.id = id
        self.title = title
        self.key = key
        self.enabledByDefault = enabledByDefault
    }
}

enum SpringBoardTweaks {
    static let targetDirectory = "/var/Managed Preferences/mobile"

    static let all: [TweakDefinition] = [
        TweakDefinition("lowBattery", "Disable Low Battery Alerts", "SBHideLowPowerAlerts"),
        TweakDefinition("acPower", "Hide AC Power on Lock Screen", "SBHideACPower"),
        TweakDefinition("respringLock", "Disable Lock After Respring", "SBDontLockAfterCrash"),
        TweakDefinition("chargingDim", "Disable Screen Dimming While Charging", "SBDontDimOrLockOnAC"),
        TweakDefinition("dynamicIslandSnapshots", "Dynamic Island in Screenshots", "SBAlwaysShowSystemApertureInSnapshots"),
        TweakDefinition("authenticationLine", "Authentication Line", "SBShowAuthenticationEngineeringUI"),
        TweakDefinition("breadcrumb", "Disable Breadcrumbs", "SBNeverBreadcrumb"),
        TweakDefinition("supervision", "Show Supervision Text", "SBShowSupervisionTextOnLockScreen")
    ]
}
