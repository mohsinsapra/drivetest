import CoreHaptics
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var hapticEngine: CHHapticEngine?
  private var hapticChannelRegistered = false
  private var hapticPlaying = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // applicationDidBecomeActive is called after the window/scene is fully ready,
  // which is the earliest safe point to access rootViewController on iOS 13+.
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    guard !hapticChannelRegistered else { return }
    setupHapticChannel()
  }

  private func setupHapticChannel() {
    guard #available(iOS 13.0, *),
          CHHapticEngine.capabilitiesForHardware().supportsHaptics
    else { return }

    // Find the key window on both scene-based (iOS 13+) and legacy setups
    let keyWindow = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: { $0.isKeyWindow }) ?? window

    guard let controller = keyWindow?.rootViewController as? FlutterViewController
    else { return }

    hapticChannelRegistered = true
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
    guard let engine = hapticEngine, !hapticPlaying else { return }
    let event = CHHapticEvent(
      eventType: .hapticTransient,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.04),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.03),
      ],
      relativeTime: 0
    )
    do {
      hapticPlaying = true
      let pattern = try CHHapticPattern(events: [event], parameters: [])
      let player = try engine.makePlayer(with: pattern)
      try player.start(atTime: CHHapticTimeImmediate)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) { [weak self] in
        self?.hapticPlaying = false
      }
    } catch {
      hapticPlaying = false
    }
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
