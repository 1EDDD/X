import SwiftUI

struct SpringBoardView: View {
    @State private var lowBatteryAlerts = false
    @State private var hideACPower = false
    @State private var authenticationLine = false
    @State private var screenRecordingDetection = false
    @State private var dynamicIslandScreenshots = false
    @State private var screenDimmingWhileCharging = false
    @State private var lockAfterRespring = false

    var body: some View {
        List {
            Toggle("Disable Low Battery Alerts", isOn: $lowBatteryAlerts)
            Toggle("Hide AC Power on Lock Screen", isOn: $hideACPower)
            Toggle("Authentication Line", isOn: $authenticationLine)
            Toggle("Screen Recording Detection", isOn: $screenRecordingDetection)
            Toggle("Dynamic Island in Screenshots", isOn: $dynamicIslandScreenshots)
            Toggle("Disable Screen Dimming While Charging", isOn: $screenDimmingWhileCharging)
            Toggle("Disable Lock After Respring", isOn: $lockAfterRespring)
        }
        .navigationTitle("SpringBoard")
    }
}
