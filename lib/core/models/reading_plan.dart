import 'package:flutter/foundation.dart';

/// One Bible passage reference — book, chapter, and optional range info.
///
/// The [display] field is the original text from the source data
/// (e.g. 'Psalm 119:1-8 (Aleph)') and is used directly in the UI so we don't
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

/// A named group of readings within a daily schedule.
///
/// [label] is optional — when null the UI renders the readings with no header.
/// M'Cheyne uses 'Morning' and 'Evening'; other plans omit labels entirely.
@immutable
class ReadingSection {
  final String? label;
  final List<BibleReference> readings;

  const ReadingSection({this.label, required this.readings});

  factory ReadingSection.fromJson(Map<String, dynamic> json) {
    return ReadingSection(
      label: json['label'] as String?,
      readings: (json['readings'] as List)
          .map((r) => BibleReference.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// The readings assigned to one calendar day.
@immutable
class DailySchedule {
  final int day;        // 1–365
  final String monthDay; // 'MM-DD', e.g. '04-11'
  final List<ReadingSection> sections;

  const DailySchedule({
    required this.day,
    required this.monthDay,
    required this.sections,
  });

  factory DailySchedule.fromJson(Map<String, dynamic> json) {
    return DailySchedule(
      day: json['day'] as int,
      monthDay: json['month_day'] as String,
      sections: (json['sections'] as List)
          .map((s) => ReadingSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// All references flattened across all sections — used by the completion provider.
  List<BibleReference> get allReadings =>
      sections.expand((s) => s.readings).toList();
}

/// Lightweight metadata for a reading plan — used in the plan picker UI
/// without loading the full 365-day schedule.
@immutable
class ReadingPlanMeta {
  final String id;
  final String name;
  final String description;
  final String author;
  final String assetPath;

  const ReadingPlanMeta({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.assetPath,
  });
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
}
