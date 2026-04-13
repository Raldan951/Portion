import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import 'date_provider.dart';

/// A single shared JournalService instance, initialised once on first use.
final journalServiceProvider = FutureProvider<JournalService>((ref) async {
  final service = JournalService();
  await service.init();
  return service;
});

/// Journal entries for the selected date, newest first.
/// Invalidate this provider after saving to trigger a refresh.
final todayEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final service = await ref.watch(journalServiceProvider.future);
  final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
  return service.getEntriesForDate(dateKey);
});
