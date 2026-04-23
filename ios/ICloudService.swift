import Flutter
import Foundation

/// Native method channel that gives Flutter two iCloud capabilities:
///
/// 1. `getContainerPath` — returns the local path of the iCloud ubiquity
///    container where we store journal.db. iOS syncs this directory
///    automatically. Returns nil if iCloud is unavailable (simulator, Mac,
///    iCloud disabled in Settings).
///
/// 2. `kvGet` / `kvSet` — thin wrappers around NSUbiquitousKeyValueStore,
///    used for small preferences (selected translation). Changes propagate
///    to other devices within seconds.
@objc class ICloudService: NSObject, FlutterPlugin {

  static let channelName = "com.peterparise.portion/icloud"
  static let containerID  = "iCloud.com.peterparise.portion"

  /// True when iCloud account is signed in and KVS entitlement is present.
  private static var kvsAvailable: Bool = {
    // FileManager.ubiquityIdentityToken is nil when iCloud is not signed in.
    return FileManager.default.ubiquityIdentityToken != nil
  }()

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = ICloudService()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    case "getContainerPath":
      // url(forUbiquityContainerIdentifier:) can return nil on the first call
      // after a cold launch while iCloud is still initialising. Retry up to
      // 5 times with 1-second gaps before giving up and returning nil.
      DispatchQueue.global(qos: .userInitiated).async {
        var resolved: URL? = nil
        for _ in 0..<5 {
          if let url = FileManager.default.url(
            forUbiquityContainerIdentifier: ICloudService.containerID
          ) {
            resolved = url
            break
          }
          Thread.sleep(forTimeInterval: 1.0)
        }
        if let url = resolved {
          let docsURL = url.appendingPathComponent("Documents", isDirectory: true)
          try? FileManager.default.createDirectory(
            at: docsURL, withIntermediateDirectories: true
          )
          DispatchQueue.main.async { result(docsURL.path) }
        } else {
          DispatchQueue.main.async { result(nil) }
        }
      }

    case "kvGet":
      guard ICloudService.kvsAvailable else { result(nil); return }
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String else {
        result(FlutterError(code: "BAD_ARGS", message: "key required", details: nil))
        return
      }
      result(NSUbiquitousKeyValueStore.default.string(forKey: key))

    case "kvSet":
      guard ICloudService.kvsAvailable else { result(nil); return }
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? String else {
        result(FlutterError(code: "BAD_ARGS", message: "key and value required", details: nil))
        return
      }
      NSUbiquitousKeyValueStore.default.set(value, forKey: key)
      NSUbiquitousKeyValueStore.default.synchronize()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
