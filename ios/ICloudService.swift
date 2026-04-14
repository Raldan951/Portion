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

  static let channelName = "com.peterparise.biblejournal/icloud"
  static let containerID  = "iCloud.com.peterparise.biblejournal"

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
      if let url = FileManager.default.url(
        forUbiquityContainerIdentifier: ICloudService.containerID
      ) {
        // Ensure the Documents subdirectory exists — this is where we store files.
        let docsURL = url.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(
          at: docsURL, withIntermediateDirectories: true
        )
        result(docsURL.path)
      } else {
        // iCloud not available — caller falls back to local storage.
        result(nil)
      }

    case "kvGet":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String else {
        result(FlutterError(code: "BAD_ARGS", message: "key required", details: nil))
        return
      }
      let store = NSUbiquitousKeyValueStore.default
      store.synchronize()
      result(store.string(forKey: key))

    case "kvSet":
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
