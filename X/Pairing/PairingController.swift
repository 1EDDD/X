import Foundation
import Network
import AVFAudio
import AirliftFFI

@MainActor
final class PairingController: ObservableObject {
    static let shared = PairingController()

    @Published private(set) var running = false
    @Published private(set) var status = "Not paired"
    @Published private(set) var pin: String?
    @Published private(set) var pairingPath: String?

    private let hostName = "X"
    private let hostModel = "Mac17,7"
    private let bindAddress = "0.0.0.0"

    private var service: NetService?
    private var continuation: CheckedContinuation<String, Error>?
    private var keepAlive = PairingKeepAlive()

    private static let altIRKKey = "XPairingHostAltIRK"

    static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var canonicalPairingURL: URL {
        documents.appendingPathComponent("airlift_pairing.plist")
    }

    static func pairingURL() -> URL? {
        let candidates = [
            documents.appendingPathComponent("airlift_pairing.plist"),
            documents.appendingPathComponent("aircard_pairing.plist")
        ]

        for url in candidates {
            if let size = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int, size > 0 {
                return url
            }
        }

        guard let files = try? FileManager.default.contentsOfDirectory(at: documents, includingPropertiesForKeys: [.fileSizeKey]) else {
            return nil
        }

        return files.first {
            guard ["plist", "mobiledevicepairing", "mobilepair"].contains($0.pathExtension.lowercased()) else { return false }
            let size = (try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return size > 0
        }
    }

    func refresh() {
        pairingPath = Self.pairingURL()?.path
        status = pairingPath == nil ? "Not paired" : "Paired"
    }

    func start() {
        Task {
            do {
                _ = try await startAndWait()
            } catch {
                status = error.localizedDescription
            }
        }
    }

    func startAndWait() async throws -> String {
        if running {
            throw PairingError.busy
        }

        if let existing = Self.pairingURL() {
            pairingPath = existing.path
        }

        running = true
        pin = nil
        status = "Starting pairing service…"
        keepAlive.start()

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            runHost()
        }
    }

    func cancel() {
        service?.stop()
        service = nil
        keepAlive.stop()
        running = false
        pin = nil
        continuation?.resume(throwing: CancellationError())
        continuation = nil
        status = "Cancelled"
    }

    private func runHost() {
        let output = Self.documents.appendingPathComponent("airlift_pairing.plist").path
        let savedIRK = UserDefaults.standard.string(forKey: Self.altIRKKey) ?? ""

        let context = Unmanaged.passRetained(self).toOpaque()

        DispatchQueue.global(qos: .userInitiated).async {
            var result = ALPairResult()

            let rc = self.bindAddress.withCString { bind in
                self.hostName.withCString { name in
                    self.hostModel.withCString { model in
                        output.withCString { out in
                            savedIRK.withCString { irk in
                                al_pairing_run_host(
                                    bind,
                                    0,
                                    name,
                                    model,
                                    out,
                                    irk,
                                    xPairReady,
                                    xPairPIN,
                                    context,
                                    &result
                                )
                            }
                        }
                    }
                }
            }

            let error = xCString(result.error)
            let path = xCString(result.pairing_file_path)
            let device = xCString(result.device_name)
            let irk = xCString(result.host_alt_irk_hex)

            if !irk.isEmpty {
                UserDefaults.standard.set(irk, forKey: Self.altIRKKey)
            }

            al_pairing_result_free(&result)

            DispatchQueue.main.async {
                Unmanaged<PairingController>.fromOpaque(context).release()
                if rc == 0 {
                    let url = URL(fileURLWithPath: path.isEmpty ? output : path)
                    let canonical = Self.canonicalPairingURL

                    if url.path != canonical.path, let data = try? Data(contentsOf: url) {
                        try? data.write(to: canonical, options: .atomic)
                    }

                    self.service?.stop()
                    self.service = nil
                    self.keepAlive.stop()
                    self.running = false
                    self.pin = nil
                    self.pairingPath = canonical.path
                    self.status = "Paired(device.isEmpty ? "" : ": \(device)")"
                    self.continuation?.resume(returning: canonical.path)
                    self.continuation = nil
                } else {
                    self.service?.stop()
                    self.service = nil
                    self.keepAlive.stop()
                    self.running = false
                    self.pin = nil
                    let message = error.isEmpty ? "Pairing failed (\(rc))" : error
                    self.status = message
                    self.continuation?.resume(throwing: PairingError.failed(message))
                    self.continuation = nil
                }
            }
        }
    }

    fileprivate func advertise(serviceID: String, port: Int32, txt: [String: Data]) {
        service?.stop()

        let service = NetService(
            domain: "",
            type: "_remotepairing-pairable-host._tcp.",
            name: serviceID,
            port: port
        )
        service.setTXTRecord(NetService.data(fromTXTRecord: txt))
        service.publish()

        self.service = service
        status = "Open Settings → Privacy & Security → Developer Mode"
    }

    fileprivate func showPIN(_ value: String) {
        pin = value
        status = "Enter PIN in Developer Mode"
    }

    enum PairingError: LocalizedError {
        case busy
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .busy:
                return "Pairing is already running."
            case .failed(let message):
                return message
            }
        }
    }
}

private let xPairReady: ALPairReadyCb = { context, serviceID, port, keys, values, count in
    guard let context, let serviceID else { return }

    var txt: [String: Data] = [:]
    if let keys, let values {
        for index in 0..<Int(count) {
            if let key = keys[index], let value = values[index] {
                txt[String(cString: key)] = Data(String(cString: value).utf8)
            }
        }
    }

    let id = String(cString: serviceID)
    let controller = Unmanaged<PairingController>.fromOpaque(context).takeUnretainedValue()

    DispatchQueue.main.async {
        controller.advertise(serviceID: id, port: Int32(port), txt: txt)
    }
}

private let xPairPIN: ALPairPinCb = { pin, context in
    guard let pin, let context else { return }

    let value = String(cString: pin)
    let controller = Unmanaged<PairingController>.fromOpaque(context).takeUnretainedValue()

    DispatchQueue.main.async {
        controller.showPIN(value)
    }
}

private func xCString(_ pointer: UnsafeMutablePointer<CChar>?) -> String {
    guard let pointer else { return "" }
    return String(cString: pointer)
}

@MainActor
private final class PairingKeepAlive {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var active = false

    func start() {
        guard !active else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            if player.engine == nil {
                engine.attach(player)
            }

            let format = engine.outputNode.inputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                active = true
                return
            }

            engine.connect(player, to: engine.mainMixerNode, format: format)

            let frames = max(1024, AVAudioFrameCount(format.sampleRate))
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else {
                active = true
                return
            }

            buffer.frameLength = frames
            if let data = buffer.floatChannelData {
                for channel in 0..<Int(format.channelCount) {
                    memset(data[channel], 0, Int(frames) * MemoryLayout<Float>.size)
                }
            }

            if !engine.isRunning {
                try engine.start()
            }

            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
            active = true
        } catch {
            active = false
        }
    }

    func stop() {
        guard active else { return }
        active = false
        player.stop()
        engine.stop()
        if player.engine != nil {
            engine.detach(player)
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
