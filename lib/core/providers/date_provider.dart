import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the date the user is currently viewing.
///
/// Defaults to today on launch. Drives both the reading schedule and the
/// journal — both screens always reflect the selected date, not a hardcoded
/// "now". Forward navigation is blocked at today; today is always the anchor.
///
/// "Today" is anchored at session start (when the provider first builds).
/// This means the date cannot flip to the next calendar day mid-session,
/// even if the user is reading past midnight. The session anchor refreshes
/// the next time the provider is rebuilt (app relaunch).
class SelectedDateNotifier extends Notifier<DateTime> {
  late DateTime _sessionAnchor;

  @override
  DateTime build() {
    final now = DateTime.now();
    _sessionAnchor = DateTime(now.year, now.month, now.day);
    return _sessionAnchor;
  }

  /// True when the selected date matches the session-start anchor.
  bool get isToday => state == _sessionAnchor;

  /// True when the calendar has ticked past the session anchor — i.e. it is
  /// now a new calendar day but the session has not yet been refreshed.
  /// The UI can use this to show a "new day available" signal without
  /// disrupting the current session's readings.
  bool get newDayAvailable {
    final now = DateTime.now();
    final calendarToday = DateTime(now.year, now.month, now.day);
    return calendarToday.isAfter(_sessionAnchor);
  }

  void goBack() => state = state.subtract(const Duration(days: 1));

  void goForward() => state = state.add(const Duration(days: 1));

  bool get isFuture => state.isAfter(_sessionAnchor);

  /// Returns to today, refreshing the session anchor if the calendar has
  /// ticked forward (e.g. the user is crossing midnight).
  void goToToday() {
    final now = DateTime.now();
    _sessionAnchor = DateTime(now.year, now.month, now.day);
    state = _sessionAnchor;
  }
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);
