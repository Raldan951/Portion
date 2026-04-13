import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/reading_plan.dart';

/// Loads reading plan JSON assets and provides today's schedule.
///
/// Plans are cached after the first load so subsequent calls are instant.
class ReadingPlanService {
  static const _mcheynePath = 'assets/plans/mcheyne_plan.json';

  ReadingPlan? _cachedPlan;

  /// Loads the M'Cheyne plan from the bundled JSON asset.
  /// Subsequent calls return the cached copy.
  Future<ReadingPlan> loadMcheynePlan() async {
    if (_cachedPlan != null) return _cachedPlan!;
    final raw = await rootBundle.loadString(_mcheynePath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cachedPlan = ReadingPlan.fromJson(json);
    return _cachedPlan!;
  }
}
