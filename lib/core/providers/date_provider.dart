import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the date the user is currently viewing.
///
/// Defaults to today on launch. Drives both the reading schedule and the
/// journal — both screens always reflect the selected date, not a hardcoded
/// "now". Forward navigation is blocked at today; today is always the anchor.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _today();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get isToday => state == _today();

  void goBack() => state = state.subtract(const Duration(days: 1));

  void goForward() {
    final next = state.add(const Duration(days: 1));
    if (!next.isAfter(_today())) state = next;
  }

  void goToToday() => state = _today();
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);
