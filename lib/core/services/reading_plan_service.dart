import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/reading_plan.dart';

/// Loads reading plan JSON assets and provides today's schedule.
///
/// Plans are cached after the first load so subsequent calls are instant.
class ReadingPlanService {
  /// All bundled reading plans available in the app.
  static const List<ReadingPlanMeta> availablePlans = [
    ReadingPlanMeta(
      id: 'mcheyne',
      name: "M'Cheyne One-Year Reading Plan",
      description:
          "Covers the Old Testament once and the New Testament and Psalms "
          "twice in one year, with four readings daily — two in the morning "
          "and two in the evening.",
      author: "Robert Murray M'Cheyne (1806–1843)",
      assetPath: 'assets/plans/mcheyne_plan.json',
    ),
    ReadingPlanMeta(
      id: 'bible_in_a_year',
      name: 'Bible in a Year',
      description:
          'Read through the entire Bible in one year with a single daily '
          'reading that moves sequentially through the Old and New Testaments.',
      author: 'Traditional',
      assetPath: 'assets/plans/bible_in_a_year.json',
    ),
    ReadingPlanMeta(
      id: 'nt_90_days',
      name: 'New Testament in 90 Days',
      description:
          'A focused sprint through the entire New Testament in 90 days — '
          'ideal for those new to regular Bible reading.',
      author: 'Traditional',
      assetPath: 'assets/plans/nt_90_days.json',
      calendarAligned: false,
    ),
    ReadingPlanMeta(
      id: 'three_streams',
      name: 'The Three Streams',
      description:
          'Three daily readings — Old Testament, New Testament, and '
          'Psalms & Proverbs — each flowing as its own continuous thread '
          'through the year. Read when you can, not by the clock.',
      author: 'BibleJournal',
      assetPath: 'assets/plans/three_streams.json',
    ),
  ];

  final Map<String, ReadingPlan> _cache = {};

  /// Loads a plan from [assetPath]; subsequent calls return the cached copy.
  Future<ReadingPlan> loadPlan(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath]!;
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final plan = ReadingPlan.fromJson(json);
    _cache[assetPath] = plan;
    return plan;
  }
}
