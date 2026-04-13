import 'package:flutter/foundation.dart';

/// One Bible passage reference — book, chapter, and optional range info.
///
/// The [display] field is the original text from the source data
/// (e.g. 'Psalm 119:1-24') and is used directly in the UI so we don't
/// have to reconstruct it from parts.
@immutable
class BibleReference {
  final String book;
  final int chapter;
  final int? chapterEnd;   // set for ranges like 'Psalm 108-109'
  final String? verseRange; // set for verse-level refs like '1-24' or '1-28:19'
  final String display;    // original display text, e.g. 'Deuteronomy 27:1-28:19'

  const BibleReference({
    required this.book,
    required this.chapter,
    this.chapterEnd,
    this.verseRange,
    required this.display,
  });

  factory BibleReference.fromJson(Map<String, dynamic> json) {
    return BibleReference(
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      chapterEnd: json['chapter_end'] as int?,
      verseRange: json['verse_range'] as String?,
      display: json['display'] as String,
    );
  }

  @override
  String toString() => display;
}

/// The readings assigned to one calendar day.
@immutable
class DailySchedule {
  final int day;              // 1–365
  final String monthDay;      // 'MM-DD', e.g. '04-11'
  final List<BibleReference> morning;
  final List<BibleReference> evening;

  const DailySchedule({
    required this.day,
    required this.monthDay,
    required this.morning,
    required this.evening,
  });

  factory DailySchedule.fromJson(Map<String, dynamic> json) {
    return DailySchedule(
      day: json['day'] as int,
      monthDay: json['month_day'] as String,
      morning: (json['morning'] as List)
          .map((r) => BibleReference.fromJson(r as Map<String, dynamic>))
          .toList(),
      evening: (json['evening'] as List)
          .map((r) => BibleReference.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Formats morning readings as a single display string, e.g.
  /// 'Leviticus 15  •  Psalm 18'
  String get morningLabel =>
      morning.map((r) => r.display).join('  \u2022  ');

  /// Formats evening readings as a single display string.
  String get eveningLabel =>
      evening.map((r) => r.display).join('  \u2022  ');
}

/// A complete reading plan — metadata plus the full daily schedule.
@immutable
class ReadingPlan {
  final String id;
  final String name;
  final String description;
  final String author;
  final List<DailySchedule> schedule;

  const ReadingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.schedule,
  });

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    return ReadingPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      schedule: (json['schedule'] as List)
          .map((d) => DailySchedule.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Returns the schedule entry for a given 1-based day of year.
  DailySchedule? forDay(int dayOfYear) {
    if (dayOfYear < 1 || dayOfYear > schedule.length) return null;
    return schedule[dayOfYear - 1];
  }

  /// Returns today's schedule entry.
  DailySchedule? get today {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return forDay(dayOfYear);
  }
}
