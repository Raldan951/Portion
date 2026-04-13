import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/journal_document.dart';
import '../models/journal_entry.dart';

/// Manages the local journal SQLite database.
///
/// v1: journal_entries — one entry per reflection, multiple per day.
/// v2: journal_documents — one continuous document per day (the journal page).
///
/// Both tables coexist; v1 data is preserved for future migration if needed.
class JournalService {
  Database? _db;

  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'journal.db');

    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE journal_entries (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            date       TEXT    NOT NULL,
            body       TEXT    NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_journal_date ON journal_entries (date)',
        );
        await db.execute('''
          CREATE TABLE journal_documents (
            date       TEXT    PRIMARY KEY,
            body       TEXT    NOT NULL DEFAULT '',
            updated_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS journal_documents (
              date       TEXT    PRIMARY KEY,
              body       TEXT    NOT NULL DEFAULT '',
              updated_at INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  // ── Legacy entry API (v1) ─────────────────────────────────────────────────

  Future<void> saveEntry(String date, String body) async {
    await _db!.insert('journal_entries', {
      'date': date,
      'body': body.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<JournalEntry>> getEntriesForDate(String date) async {
    final rows = await _db!.query(
      'journal_entries',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return rows.map(JournalEntry.fromMap).toList();
  }

  // ── Document API (v2) ─────────────────────────────────────────────────────

  /// Returns the journal document for [date], or null if none exists yet.
  Future<JournalDocument?> getDocument(String date) async {
    final rows = await _db!.query(
      'journal_documents',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return JournalDocument.fromMap(rows.first);
  }

  /// Creates or replaces the journal document for [date].
  Future<void> upsertDocument(String date, String body) async {
    await _db!.insert(
      'journal_documents',
      {
        'date': date,
        'body': body,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
