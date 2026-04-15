import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which individual readings the user has marked complete.
///
/// Keys are formatted as: '{planId}_{YYYY-MM-DD}_{sectionIdx}_{readingIdx}'
/// State is the full set of completed keys, loaded once on startup.
class ReadingCompletionNotifier extends Notifier<Set<String>> {
  static const _prefsKey = 'reading_completion_keys';

  @override
  Set<String> build() {
    _load();
    return {};
  }

  /// Builds the storage key for a specific reading.
  static String keyFor({
    required String planId,
    required String date,
    required int sectionIndex,
    required int readingIndex,
  }) =>
      '${planId}_${date}_${sectionIndex}_$readingIndex';

  bool isComplete(String key) => state.contains(key);

  void toggle(String key) {
    final next = Set<String>.from(state);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    state = next;
    _persist(next);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? [];
    state = stored.toSet();
  }

  Future<void> _persist(Set<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, keys.toList());
  }
}

final readingCompletionProvider =
    NotifierProvider<ReadingCompletionNotifier, Set<String>>(
  ReadingCompletionNotifier.new,
);
