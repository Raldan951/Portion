import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user preferences — device-local, no iCloud sync.
@immutable
class AppSettings {
  final bool showReadingCheckboxes;

  const AppSettings({this.showReadingCheckboxes = false});

  AppSettings copyWith({bool? showReadingCheckboxes}) {
    return AppSettings(
      showReadingCheckboxes:
          showReadingCheckboxes ?? this.showReadingCheckboxes,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _keyCheckboxes = 'show_reading_checkboxes';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  void setShowCheckboxes(bool value) {
    state = state.copyWith(showReadingCheckboxes: value);
    _persist();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final checkboxes = prefs.getBool(_keyCheckboxes) ?? false;
    state = AppSettings(showReadingCheckboxes: checkboxes);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCheckboxes, state.showReadingCheckboxes);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
