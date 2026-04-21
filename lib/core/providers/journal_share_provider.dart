import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum JournalShareDestination { email, messages }

const _kKey = 'journal_share_destination';

final journalShareDestinationProvider =
    NotifierProvider<JournalShareDestinationNotifier, JournalShareDestination?>(
  JournalShareDestinationNotifier.new,
);

class JournalShareDestinationNotifier
    extends Notifier<JournalShareDestination?> {
  @override
  JournalShareDestination? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kKey);
    if (stored != null) {
      state = JournalShareDestination.values.firstWhere(
        (d) => d.name == stored,
        orElse: () => JournalShareDestination.email,
      );
    }
  }

  Future<void> select(JournalShareDestination dest) async {
    state = dest;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, dest.name);
  }
}
