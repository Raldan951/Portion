import 'package:flutter/services.dart';

/// Dart interface to the native ICloudService method channel.
///
/// Provides two things:
/// - [containerPath]: the local path of the iCloud ubiquity container's
///   Documents folder. iOS syncs this directory automatically. Returns null
///   when iCloud is unavailable (simulator, iCloud off in Settings).
/// - [kvGet] / [kvSet]: NSUbiquitousKeyValueStore wrappers for small
///   preferences that should sync across devices within seconds.
class ICloudService {
  static const _channel = MethodChannel('com.peterparise.biblejournal/icloud');

  /// Returns the iCloud Documents container path, or null if unavailable.
  /// Hard timeout of 6 s so a slow or unavailable iCloud daemon never hangs
  /// the app indefinitely.
  static Future<String?> get containerPath async {
    try {
      return await _channel
          .invokeMethod<String>('getContainerPath')
          .timeout(const Duration(seconds: 6), onTimeout: () => null);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Returns the real (non-sandboxed) home directory path on macOS.
  /// Returns null on other platforms or if the call fails.
  static Future<String?> get realHomePath async {
    try {
      return await _channel.invokeMethod<String>('getRealHomePath');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Reads a string value from NSUbiquitousKeyValueStore.
  static Future<String?> kvGet(String key) async {
    try {
      return await _channel.invokeMethod<String>('kvGet', {'key': key});
    } on PlatformException {
      return null;
    }
  }

  /// Writes a string value to NSUbiquitousKeyValueStore.
  static Future<void> kvSet(String key, String value) async {
    try {
      await _channel.invokeMethod<void>('kvSet', {'key': key, 'value': value});
    } on PlatformException {
      // Best-effort — local shared_preferences will still have the value.
    }
  }
}
