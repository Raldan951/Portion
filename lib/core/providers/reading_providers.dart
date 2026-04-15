import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_translation.dart';
import '../models/bible_verse.dart';
import '../models/reading_plan.dart';
import '../services/bible_database_service.dart';
import '../services/icloud_service.dart';
import '../services/reading_plan_service.dart';
import 'date_provider.dart';

/// A single shared instance of ReadingPlanService.
final readingPlanServiceProvider = Provider<ReadingPlanService>(
  (_) => ReadingPlanService(),
);

// ── Plan start mode ───────────────────────────────────────────────────────────

/// Stores a start mode per plan ID.
///
/// Values:
///   - `'calendar'`    → use day-of-year (follows the calendar year)
///   - `'YYYY-MM-DD'`  → user chose this date as Day 1
///
/// Storage key per plan: `plan_start_{planId}`.
class PlanStartNotifier extends Notifier<Map<String, String>> {
  static String _key(String planId) => 'plan_start_$planId';

  @override
  Map<String, String> build() {
    _load();
    return {};
  }

  void setCalendar(String planId) {
    state = {...state, planId: 'calendar'};
    _persist(planId, 'calendar');
  }

  void setStartDate(String planId, DateTime date) {
    final iso = date.toIso8601String().substring(0, 10); // YYYY-MM-DD
    state = {...state, planId: iso};
    _persist(planId, iso);
  }

  /// Place the user on a specific day by back-calculating the start date.
  ///
  /// Day 1 → startDate = today. Day 47 → startDate = today − 46 days.
  void setDay(String planId, int dayNumber) {
    final startDate =
        DateTime.now().subtract(Duration(days: dayNumber - 1));
    setStartDate(planId, startDate);
  }

  Future<void> _load() async {
    final updates = <String, String>{};
    for (final plan in ReadingPlanService.availablePlans) {
      final k = _key(plan.id);
      final saved = await ICloudService.kvGet(k) ?? await _localPrefs(k);
      if (saved != null) updates[plan.id] = saved;
    }
    if (updates.isNotEmpty) state = {...state, ...updates};
  }

  Future<void> _persist(String planId, String value) async {
    final k = _key(planId);
    await ICloudService.kvSet(k, value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(k, value);
  }

  Future<String?> _localPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}

final planStartProvider =
    NotifierProvider<PlanStartNotifier, Map<String, String>>(
  PlanStartNotifier.new,
);

// ── Plan selection ────────────────────────────────────────────────────────────

/// Holds and exposes the user's selected reading plan ID.
///
/// Persistence strategy (in priority order):
///   1. NSUbiquitousKeyValueStore — syncs across devices within seconds.
///   2. shared_preferences — local fallback when iCloud is unavailable.
///
/// Defaults to 'mcheyne' on first launch.
class PlanNotifier extends Notifier<String> {
  static const _key = 'selected_plan';

  @override
  String build() {
    _load();
    return 'mcheyne';
  }

  void select(String planId) {
    state = planId;
    _persist(planId);
  }

  Future<void> _load() async {
    final saved =
        await ICloudService.kvGet(_key) ??
        await _localPrefs();
    if (saved == null) return;
    final exists = ReadingPlanService.availablePlans.any((p) => p.id == saved);
    if (exists) state = saved;
  }

  Future<void> _persist(String value) async {
    await ICloudService.kvSet(_key, value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }

  Future<String?> _localPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
}

final selectedPlanIdProvider = NotifierProvider<PlanNotifier, String>(
  PlanNotifier.new,
);

/// Loads the full [ReadingPlan] for the currently selected plan ID.
final activePlanProvider = FutureProvider<ReadingPlan>((ref) {
  final planId = ref.watch(selectedPlanIdProvider);
  final service = ref.watch(readingPlanServiceProvider);
  final meta = ReadingPlanService.availablePlans.firstWhere(
    (p) => p.id == planId,
    orElse: () => ReadingPlanService.availablePlans.first,
  );
  return service.loadPlan(meta.assetPath);
});

/// Resolves the [DailySchedule] for the currently selected date.
/// Returns null while loading or if the date falls outside the plan.
final todaysScheduleProvider = Provider<DailySchedule?>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final planId = ref.watch(selectedPlanIdProvider);
  final startModes = ref.watch(planStartProvider);

  return ref.watch(activePlanProvider).whenOrNull(
    data: (plan) {
      final startMode = startModes[planId];
      final int dayIndex;

      if (startMode != null && startMode != 'calendar') {
        // User-anchored: days elapsed since their chosen start date.
        final startDate = DateTime.parse(startMode);
        dayIndex = selectedDate.difference(startDate).inDays;
      } else {
        // Calendar mode: day of year.
        dayIndex =
            selectedDate.difference(DateTime(selectedDate.year)).inDays;
      }

      // Cycle so short plans wrap and day 0 (Jan 1) maps to entry 1.
      final planDay = (dayIndex % plan.schedule.length) + 1;
      return plan.forDay(planDay);
    },
  );
});


/// True when today is the first day of a new plan cycle in user-anchored mode.
///
/// Only meaningful for "start today" plans — in calendar mode the year resets
/// naturally and no banner is needed. Shows on day 365, 730, etc.
final planJustCompletedProvider = Provider<bool>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final planId = ref.watch(selectedPlanIdProvider);
  final startModes = ref.watch(planStartProvider);

  return ref.watch(activePlanProvider).whenOrNull(
        data: (plan) {
          final startMode = startModes[planId];
          if (startMode == null || startMode == 'calendar') return false;
          final startDate = DateTime.parse(startMode);
          final dayIndex = selectedDate.difference(startDate).inDays;
          return dayIndex > 0 && dayIndex % plan.schedule.length == 0;
        },
      ) ??
      false;
});

// ── Bible database ────────────────────────────────────────────────────────────

/// A single shared BibleDatabaseService instance.
/// Databases are opened lazily per translation on first access.
final bibleDatabaseServiceProvider = Provider<BibleDatabaseService>(
  (_) => BibleDatabaseService(),
);

/// Fetches a chapter (or chapter range) for any inline translation.
///
/// Key: (translation, book name, startChapter, endChapter).
/// endChapter equals startChapter for single-chapter readings.
final chapterProvider = FutureProvider.autoDispose
    .family<List<BibleVerse>, (BibleTranslation, String, int, int)>(
  (ref, args) async {
    final service = ref.watch(bibleDatabaseServiceProvider);
    final (translation, book, start, end) = args;
    return service.getChapter(
      translation,
      book,
      start,
      chapterEnd: end == start ? null : end,
    );
  },
);
