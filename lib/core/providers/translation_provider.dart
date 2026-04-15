import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_translation.dart';
import '../services/icloud_service.dart';

/// Holds and exposes the user's selected Bible translation.
///
/// Persistence strategy (in priority order):
///   1. NSUbiquitousKeyValueStore — syncs across devices within seconds.
///   2. shared_preferences — local fallback when iCloud is unavailable.
///
/// On build, defaults to KJV and kicks off an async load.
/// On select, updates state synchronously and persists in the background.
class TranslationNotifier extends Notifier<BibleTranslation> {
  static const _key = 'selected_translation';

  @override
  BibleTranslation build() {
    _load();
    return BibleTranslation.kjv;
  }

  void select(BibleTranslation translation) {
    state = translation;
    _persist(translation.name);
  }

  Future<void> _load() async {
    // Try iCloud key-value store first; fall back to shared_preferences.
    final saved =
        await ICloudService.kvGet(_key) ??
        await _localPrefs();
    if (saved == null) return;
    final translation =
        BibleTranslation.values.where((t) => t.name == saved).firstOrNull;
    if (translation != null) state = translation;
  }

  Future<void> _persist(String value) async {
    await ICloudService.kvSet(_key, value);
    // Also write locally so the value is available offline instantly.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }

  Future<String?> _localPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
}

final selectedTranslationProvider =
    NotifierProvider<TranslationNotifier, BibleTranslation>(
  TranslationNotifier.new,
);
