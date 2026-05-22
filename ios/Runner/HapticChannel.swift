import CoreHaptics
import Flutter

@available(iOS 13.0, *)
class HapticChannel {
  private var engine: CHHapticEngine?
  private var continuousPlayer: CHHapticAdvancedPatternPlayer?

  init(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.taxiexam/haptic",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "startContinuous":
        self?.startContinuous()
        result(nil)
      case "stopContinuous":
        self?.stopContinuous()
        result(nil)
      case "tick":
        self?.tick()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    prepareEngine()
  }

  private func prepareEngine() {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
    do {
      engine = try CHHapticEngine()
      engine?.isAutoShutdownEnabled = false
      engine?.stoppedHandler = { [weak self] _ in
        try? self?.engine?.start()
      }
      engine?.resetHandler = { [weak self] in
        try? self?.engine?.start()
      }
      try engine?.start()
    } catch {}
  }

  // Rapid discrete ticks — best for "ridged" scroll feel
  private func tick() {
    guard let engine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
    let event = CHHapticEvent(
      eventType: .hapticTransient,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
      ],
      relativeTime: 0
    )
    do {
      let pattern = try CHHapticPattern(events: [event], parameters: [])
      let player = try engine.makePlayer(with: pattern)
      try player.start(atTime: CHHapticTimeImmediate)
    } catch {}
  }

  // Continuous low-intensity buzz while dragging
  private func startContinuous() {
    guard let engine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
    stopContinuous()
    let event = CHHapticEvent(
      eventType: .hapticContinuous,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05),
      ],
      relativeTime: 0,
      duration: 60
    )
    do {
      let pattern = try CHHapticPattern(events: [event], parameters: [])
      continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
      try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
    } catch {}
  }

  private func stopContinuous() {
    try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
    continuousPlayer = nil
  }
}
