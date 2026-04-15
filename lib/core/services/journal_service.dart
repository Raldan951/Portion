import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/journal_document.dart';
import '../models/journal_entry.dart';
import 'icloud_service.dart';

/// Manages journal data as per-day plain-text files.
///
/// Each day's journal is stored as `$base/journal/YYYY-MM-DD.txt`.
/// When iCloud is available, `$base` is the ubiquity container Documents
/// folder and iOS/macOS syncs the files automatically. When iCloud is
/// unavailable the files live in the local app documents directory.
///
/// On first run, any existing SQLite journal_documents rows are migrated
/// to text files so no data is lost.
class JournalService {
  late final String _basePath;

  Future<void> init() async {
    final icloudPath = await ICloudService.containerPath;
    _basePath = icloudPath ?? (await getApplicationDocumentsDirectory()).path;

    // Ensure the journal sub-directory exists.
    await Directory(p.join(_basePath, 'journal')).create(recursive: true);

    // One-time migration from legacy SQLite.
    await _migrateFromSqliteIfNeeded();
  }

  // ── File path helper ──────────────────────────────────────────────────────

  /// The journal sub-directory path — used by the file watcher provider.
  String get journalDirPath => p.join(_basePath, 'journal');

  File _fileForDate(String date) =>
      File(p.join(_basePath, 'journal', '$date.txt'));

  // ── Document API (v2) ─────────────────────────────────────────────────────

  /// Returns the journal document for [date], or null if nothing written yet.
  Future<JournalDocument?> getDocument(String date) async {
    final file = _fileForDate(date);
    if (!file.existsSync()) return null;
    final body = await file.readAsString();
    if (body.isEmpty) return null;
    final stat = file.statSync();
    return JournalDocument(date: date, body: body, updatedAt: stat.modified);
  }

  /// Writes the journal document for [date].
  Future<void> upsertDocument(String date, String body) async {
    await _fileForDate(date).writeAsString(body);
  }

  // ── Legacy entry API (v1 — stubs, no longer written) ─────────────────────

  Future<void> saveEntry(String date, String body) async {}

  Future<List<JournalEntry>> getEntriesForDate(String date) async => [];

  // ── SQLite migration ──────────────────────────────────────────────────────

  /// Reads any existing rows from the legacy journal.db and writes them as
  /// text files. Skips dates that already have a text file. Marks completion
  /// with a `.migrated` sentinel so this only runs once.
  Future<void> _migrateFromSqliteIfNeeded() async {
    final sentinel = File(p.join(_basePath, 'journal', '.migrated'));
    if (sentinel.existsSync()) return;

    final localDocsPath = (await getApplicationDocumentsDirectory()).path;
    final dbPath = p.join(localDocsPath, 'journal.db');
    if (!File(dbPath).existsSync()) {
      // No legacy DB — just mark done.
      await sentinel.writeAsString(DateTime.now().toIso8601String());
      return;
    }

    try {
      final db = await openDatabase(dbPath, readOnly: true);
      final rows = await db.query('journal_documents', orderBy: 'date');
      for (final row in rows) {
        final date = row['date'] as String;
        final body = row['body'] as String;
        if (body.isNotEmpty) {
          final file = _fileForDate(date);
          if (!file.existsSync()) {
            await file.writeAsString(body);
            // ignore: avoid_print
            print('[JournalService] migrated $date (${body.length} chars)');
          }
        }
      }
      await db.close();
    } catch (e) {
      // Non-fatal — user keeps existing text files, SQLite data stays on disk.
      // ignore: avoid_print
      print('[JournalService] migration error: $e');
    }

    await sentinel.writeAsString(DateTime.now().toIso8601String());
  }
}
