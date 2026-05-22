import CoreHaptics
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var hapticEngine: CHHapticEngine?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // super must run first so window/rootViewController are ready
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    setupHapticChannel()
    return result
  }

  private func setupHapticChannel() {
    guard #available(iOS 13.0, *),
          CHHapticEngine.capabilitiesForHardware().supportsHaptics,
          let controller = window?.rootViewController as? FlutterViewController
    else { return }

    prepareHapticEngine()

    let channel = FlutterMethodChannel(
      name: "com.taxiexam/haptic",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "tick" {
        self?.fireHapticTick()
      }
      result(nil)
    }
  }

  @available(iOS 13.0, *)
  private func prepareHapticEngine() {
    do {
      hapticEngine = try CHHapticEngine()
      hapticEngine?.isAutoShutdownEnabled = false
      hapticEngine?.stoppedHandler = { [weak self] _ in try? self?.hapticEngine?.start() }
      hapticEngine?.resetHandler = { [weak self] in try? self?.hapticEngine?.start() }
      try hapticEngine?.start()
    } catch {}
  }

  @available(iOS 13.0, *)
  private func fireHapticTick() {
    guard let engine = hapticEngine else { return }
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

  // Required for Google Sign-In to redirect back to the app after OAuth.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
}
