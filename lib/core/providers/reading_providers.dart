import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bible_translation.dart';
import '../models/bible_verse.dart';
import '../models/reading_plan.dart';
import '../services/bible_database_service.dart';
import '../services/reading_plan_service.dart';
import 'date_provider.dart';

/// A single shared instance of ReadingPlanService.
final readingPlanServiceProvider = Provider<ReadingPlanService>(
  (_) => ReadingPlanService(),
);

/// Loads the full M'Cheyne plan from the bundled JSON asset.
final mcheynePlanProvider = FutureProvider<ReadingPlan>((ref) {
  final service = ref.watch(readingPlanServiceProvider);
  return service.loadMcheynePlan();
});

/// Resolves the [DailySchedule] for the currently selected date.
/// Returns null while loading or if the date falls outside the plan.
final todaysScheduleProvider = Provider<DailySchedule?>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(mcheynePlanProvider).whenOrNull(
    data: (plan) {
      final dayOfYear =
          selectedDate.difference(DateTime(selectedDate.year)).inDays;
      return plan.forDay(dayOfYear);
    },
  );
});

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
