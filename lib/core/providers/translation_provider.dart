import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_translation.dart';

/// Holds and exposes the user's selected Bible translation.
///
/// On build, defaults to KJV and immediately kicks off an async load from
/// shared_preferences — fast enough that the switch is imperceptible.
/// On select, updates state synchronously and persists in the background.
class TranslationNotifier extends Notifier<BibleTranslation> {
  static const _key = 'selected_translation';

  @override
  BibleTranslation build() {
    _loadFromPrefs();
    return BibleTranslation.kjv;
  }

  void select(BibleTranslation translation) {
    state = translation;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_key, translation.name));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) return;
    final translation = BibleTranslation.values
        .where((t) => t.name == saved)
        .firstOrNull;
    if (translation != null) state = translation;
  }
}

final selectedTranslationProvider =
    NotifierProvider<TranslationNotifier, BibleTranslation>(
  TranslationNotifier.new,
);
