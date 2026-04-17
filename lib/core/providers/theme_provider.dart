import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/journal_theme.dart';

const _kThemeKey = 'selected_journal_theme';

class ThemeNotifier extends Notifier<JournalTheme> {
  @override
  JournalTheme build() {
    _loadFromPrefs();
    return JournalTheme.warmDesk;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kThemeKey);
    if (id != null) {
      state = JournalTheme.fromId(id);
    }
  }

  Future<void> select(JournalTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, theme.id);
  }
}

final journalThemeProvider = NotifierProvider<ThemeNotifier, JournalTheme>(
  ThemeNotifier.new,
);
