import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var hapticChannel: AnyObject?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 13.0, *) {
      let controller = window?.rootViewController as! FlutterViewController
      hapticChannel = HapticChannel(messenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Required for Google Sign-In to redirect back to the app after OAuth.
  // After the user authenticates in Safari, iOS delivers the REVERSED_CLIENT_ID
  // URL scheme here. Calling super delegates it to the google_sign_in plugin.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
}
