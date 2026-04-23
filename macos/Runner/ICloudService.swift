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

  static let channelName = "com.peterparise.portion/icloud"
  static let containerID  = "iCloud.com.peterparise.portion"

  private static var kvsAvailable: Bool = {
    return FileManager.default.ubiquityIdentityToken != nil
  }()

  private var accessedBookmarkURL: URL? = nil

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

    case "pickFolder":
      DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder for your Portion journal entries"
        panel.prompt = "Select"

        guard panel.runModal() == .OK, let url = panel.url else {
          result(nil)
          return
        }

        do {
          let data = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
          )
          UserDefaults.standard.set(data, forKey: "exportFolderBookmark")
        } catch {
          result(FlutterError(code: "BOOKMARK_ERROR",
                              message: error.localizedDescription,
                              details: nil))
          return
        }

        self.accessedBookmarkURL?.stopAccessingSecurityScopedResource()
        _ = url.startAccessingSecurityScopedResource()
        self.accessedBookmarkURL = url
        result(url.path)
      }

    case "loadBookmarkedFolder":
      guard let data = UserDefaults.standard.data(forKey: "exportFolderBookmark") else {
        result(nil)
        return
      }
      do {
        var isStale = false
        let url = try URL(
          resolvingBookmarkData: data,
          options: .withSecurityScope,
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )
        if isStale {
          UserDefaults.standard.removeObject(forKey: "exportFolderBookmark")
          result(nil)
          return
        }
        self.accessedBookmarkURL?.stopAccessingSecurityScopedResource()
        _ = url.startAccessingSecurityScopedResource()
        self.accessedBookmarkURL = url
        result(url.path)
      } catch {
        UserDefaults.standard.removeObject(forKey: "exportFolderBookmark")
        result(nil)
      }

    case "releaseFolder":
      self.accessedBookmarkURL?.stopAccessingSecurityScopedResource()
      self.accessedBookmarkURL = nil
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
