import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/founding_doc.dart';
import '../services/founding_docs_service.dart';

// ── Service ───────────────────────────────────────────────────────────────────

final foundingDocsServiceProvider = Provider<FoundingDocsService>(
  (_) => FoundingDocsService(),
);

final foundingDocsProvider = FutureProvider<FoundingDocs>((ref) {
  return ref.watch(foundingDocsServiceProvider).load();
});

// ── Enabled toggle ────────────────────────────────────────────────────────────

class _EnabledNotifier extends Notifier<bool> {
  static const _key = 'founding_docs_enabled';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final foundingDocsEnabledProvider =
    NotifierProvider<_EnabledNotifier, bool>(_EnabledNotifier.new);

// ── Active document ───────────────────────────────────────────────────────────

class _ActiveDocNotifier extends Notifier<FoundingDocType> {
  static const _key = 'founding_docs_active';

  @override
  FoundingDocType build() {
    _load();
    return FoundingDocType.federalistPapers;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      state = FoundingDocType.values.firstWhere(
        (t) => t.name == stored,
        orElse: () => FoundingDocType.federalistPapers,
      );
    }
  }

  Future<void> select(FoundingDocType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, type.name);
  }
}

final foundingDocsActiveProvider =
    NotifierProvider<_ActiveDocNotifier, FoundingDocType>(_ActiveDocNotifier.new);

// ── Federalist bookmark ───────────────────────────────────────────────────────

class FederalistBookmarkNotifier extends Notifier<int> {
  static const _key = 'federalist_bookmark';

  @override
  int build() {
    _load();
    return 0;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key) ?? 0;
  }

  Future<void> advance(int totalSegments) async {
    final next = (state + 1).clamp(0, totalSegments - 1);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, next);
  }

  Future<void> jumpTo(int segmentIdx) async {
    state = segmentIdx;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, segmentIdx);
  }
}

final federalistBookmarkProvider =
    NotifierProvider<FederalistBookmarkNotifier, int>(
        FederalistBookmarkNotifier.new);
