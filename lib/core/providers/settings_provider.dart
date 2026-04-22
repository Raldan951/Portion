import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user preferences — device-local, no iCloud sync.
@immutable
class AppSettings {
  const AppSettings({
    this.showQuickStart = true,
    this.showReadAloud = true,
  });
  final bool showQuickStart;
  final bool showReadAloud;
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _keyQuickStart = 'show_quick_start';
  static const _keyReadAloud = 'show_read_aloud';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      showQuickStart: prefs.getBool(_keyQuickStart) ?? true,
      showReadAloud: prefs.getBool(_keyReadAloud) ?? true,
    );
  }

  Future<void> setShowQuickStart(bool value) async {
    state = AppSettings(showQuickStart: value, showReadAloud: state.showReadAloud);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyQuickStart, value);
  }

  Future<void> setShowReadAloud(bool value) async {
    state = AppSettings(showQuickStart: state.showQuickStart, showReadAloud: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReadAloud, value);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
