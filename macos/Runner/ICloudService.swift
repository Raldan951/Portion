import FlutterMacOS
import Foundation

/// macOS equivalent of the iOS ICloudService — same channel name and behaviour.
///
/// Provides:
/// 1. `getContainerPath` — local path of the iCloud ubiquity container's
///    Documents folder. macOS syncs this via the iCloud Drive daemon once
///    the app is installed and signed.
/// 2. `kvGet` / `kvSet` — NSUbiquitousKeyValueStore wrappers for preferences.
class ICloudService: NSObject, FlutterPlugin {

  static let channelName = "com.peterparise.biblejournal/icloud"
  static let containerID  = "iCloud.com.peterparise.biblejournal"

  private static var kvsAvailable: Bool = {
    return FileManager.default.ubiquityIdentityToken != nil
  }()

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger
    )
    let instance = ICloudService()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    case "getContainerPath":
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

    case "getRealHomePath":
      let pw = getpwuid(getuid())
      if let pw = pw {
        result(String(cString: pw.pointee.pw_dir))
      } else {
        result(nil)
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
