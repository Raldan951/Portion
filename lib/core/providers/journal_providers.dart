import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/journal_document.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import 'date_provider.dart';

/// A single shared JournalService instance, initialised once on first use.
final journalServiceProvider = FutureProvider<JournalService>((ref) async {
  final service = JournalService();
  await service.init();
  return service;
});

/// Journal entries for the selected date, newest first (v1 — legacy).
/// Invalidate this provider after saving to trigger a refresh.
final todayEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final service = await ref.watch(journalServiceProvider.future);
  final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
  return service.getEntriesForDate(dateKey);
});

// ── v2: Document-based journal ────────────────────────────────────────────────

/// The journal document (single page) for the selected date.
/// Returns null if the user hasn't written anything yet today.
final journalDocumentProvider = FutureProvider<JournalDocument?>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final service = await ref.watch(journalServiceProvider.future);
  final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
  return service.getDocument(dateKey);
});

/// Watches the journal directory for file changes (e.g. iCloud syncing a
/// new or updated .txt file). Fires a [FileSystemEvent] for every change to
/// a .txt file. Consumers listen and invalidate [journalDocumentProvider] so
/// the UI reflects changes from other devices without a manual refresh.
final journalWatcherProvider = StreamProvider<FileSystemEvent>((ref) async* {
  final service = await ref.watch(journalServiceProvider.future);
  final dir = Directory(service.journalDirPath);
  if (!dir.existsSync()) return;
  yield* dir
      .watch(events: FileSystemEvent.all)
      .where((e) => e.path.endsWith('.txt'));
});

/// Holds the text of a clipped passage waiting to be inserted into the journal.
/// PassageScreen enqueues; JournalPage dequeues and clears.
class ClipQueueNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void enqueue(String clipText) => state = clipText;
  void clear() => state = null;
}

final clipQueueProvider = NotifierProvider<ClipQueueNotifier, String?>(
  ClipQueueNotifier.new,
);
