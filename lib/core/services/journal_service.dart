import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/journal_document.dart';
import '../models/journal_entry.dart';
import 'icloud_service.dart';

/// Manages journal data as per-day Markdown files.
///
/// Each day's journal is stored as `$base/journal/YYYY-MM-DD.md`.
/// On iOS and macOS, `$base` is the iCloud ubiquity container Documents
/// folder so files sync automatically across devices. When iCloud is
/// unavailable (simulator, iCloud disabled, other platforms) the files
/// live in the local app documents directory instead.
///
/// On first run, any existing SQLite journal_documents rows are migrated
/// to text files so no data is lost. If iCloud becomes available for the
/// first time, any locally-saved .txt files are copied there once.
class JournalService {
  late final String _basePath;

  Future<void> init() async {
    // On iOS/macOS, try the iCloud ubiquity container first. Falls back to
    // local app documents if iCloud is unavailable (no account, simulator,
    // entitlement missing, etc.).
    String? iCloudPath;
    if (Platform.isIOS || Platform.isMacOS) {
      iCloudPath = await ICloudService.containerPath;
    }
    _basePath = iCloudPath ?? (await getApplicationDocumentsDirectory()).path;

    // Ensure the journal sub-directory exists.
    await Directory(p.join(_basePath, 'journal')).create(recursive: true);

    // If we landed on the iCloud path, migrate any previously-local journals.
    if (iCloudPath != null) {
      await _migrateLocalToICloud(iCloudPath);
    }

    // One-time migration from legacy SQLite.
    await _migrateFromSqliteIfNeeded();
  }

  // ── File path helper ──────────────────────────────────────────────────────

  /// The journal sub-directory path — used by the file watcher provider.
  String get journalDirPath => p.join(_basePath, 'journal');

  File _fileForDate(String date) =>
      File(p.join(_basePath, 'journal', '$date.md'));

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

  /// Returns the file paths of all journal entries, sorted by date.
  Future<List<String>> allEntryPaths() async {
    final dir = Directory(p.join(_basePath, 'journal'));
    if (!dir.existsSync()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => p.extension(f.path) == '.md')
        .map((f) => f.path)
        .toList()
      ..sort();
  }

  // ── Legacy entry API (v1 — stubs, no longer written) ─────────────────────

  Future<void> saveEntry(String date, String body) async {}

  Future<List<JournalEntry>> getEntriesForDate(String date) async => [];

  // ── SQLite migration ──────────────────────────────────────────────────────

  /// Copies any .txt journals from the local app documents directory into the
  /// iCloud container. Runs once (guarded by a sentinel file). Safe to call
  /// if the iCloud path happens to equal the local path — it skips that case.
  Future<void> _migrateLocalToICloud(String iCloudPath) async {
    final sentinel = File(
      p.join(iCloudPath, 'journal', '.migrated_from_local'),
    );
    if (sentinel.existsSync()) return;

    final localDocsPath = (await getApplicationDocumentsDirectory()).path;

    // Nothing to do if iCloud IS the local path (shouldn't happen, but safe).
    if (p.equals(iCloudPath, localDocsPath)) {
      await sentinel.writeAsString(DateTime.now().toIso8601String());
      return;
    }

    final localJournalDir = Directory(p.join(localDocsPath, 'journal'));
    if (localJournalDir.existsSync()) {
      try {
        final files = localJournalDir
            .listSync()
            .whereType<File>()
            .where((f) => p.extension(f.path) == '.md');
        for (final file in files) {
          final dest = File(
            p.join(iCloudPath, 'journal', p.basename(file.path)),
          );
          if (!dest.existsSync()) {
            await file.copy(dest.path);
            // ignore: avoid_print
            print(
              '[JournalService] local→iCloud: ${p.basename(file.path)}',
            );
          }
        }
      } catch (e) {
        // Non-fatal — local journals remain intact.
        // ignore: avoid_print
        print('[JournalService] local→iCloud migration error: $e');
      }
    }

    await sentinel.writeAsString(DateTime.now().toIso8601String());
  }

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
