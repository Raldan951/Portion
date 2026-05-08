import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user preferences — device-local, no iCloud sync.
@immutable
class AppSettings {
  const AppSettings({
    this.showQuickStart = true,
    this.showReadAloud = true,
    this.firstLaunchDate,
    this.betaBannerDismissed = false,
  });
  final bool showQuickStart;
  final bool showReadAloud;
  final DateTime? firstLaunchDate;
  final bool betaBannerDismissed;
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _keyQuickStart = 'show_quick_start';
  static const _keyReadAloud = 'show_read_aloud';
  static const _keyFirstLaunch = 'first_launch_date';
  static const _keyBetaBannerDismissed = 'beta_banner_dismissed';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final stored = prefs.getString(_keyFirstLaunch);
    final DateTime firstLaunch;
    if (stored == null) {
      firstLaunch = DateTime.now();
      await prefs.setString(_keyFirstLaunch, firstLaunch.toIso8601String());
    } else {
      firstLaunch = DateTime.parse(stored);
    }

    state = AppSettings(
      showQuickStart: prefs.getBool(_keyQuickStart) ?? true,
      showReadAloud: prefs.getBool(_keyReadAloud) ?? true,
      firstLaunchDate: firstLaunch,
      betaBannerDismissed: prefs.getBool(_keyBetaBannerDismissed) ?? false,
    );
  }

  Future<void> setShowQuickStart(bool value) async {
    state = AppSettings(
      showQuickStart: value,
      showReadAloud: state.showReadAloud,
      firstLaunchDate: state.firstLaunchDate,
      betaBannerDismissed: state.betaBannerDismissed,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyQuickStart, value);
  }

  Future<void> setShowReadAloud(bool value) async {
    state = AppSettings(
      showQuickStart: state.showQuickStart,
      showReadAloud: value,
      firstLaunchDate: state.firstLaunchDate,
      betaBannerDismissed: state.betaBannerDismissed,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReadAloud, value);
  }

  Future<void> dismissBetaBanner() async {
    state = AppSettings(
      showQuickStart: state.showQuickStart,
      showReadAloud: state.showReadAloud,
      firstLaunchDate: state.firstLaunchDate,
      betaBannerDismissed: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBetaBannerDismissed, true);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
